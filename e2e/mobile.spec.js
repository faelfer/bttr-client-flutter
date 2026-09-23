import assert from 'node:assert/strict';
import { mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { remote } from 'webdriverio';

const platform = process.env.E2E_PLATFORM;
if (!['android', 'ios'].includes(platform)) {
  throw new Error('Defina E2E_PLATFORM=android ou E2E_PLATFORM=ios.');
}

const mockUrl = process.env.BTTR_MOCK_API_URL ?? 'http://127.0.0.1:18080';
const appiumUrl = new URL(process.env.APPIUM_SERVER_URL ?? 'http://127.0.0.1:4723');
const appPath = resolve(process.env.E2E_APP_PATH ?? (
  platform === 'android'
    ? 'build/app/outputs/flutter-apk/app-debug.apk'
    : 'build/ios/iphonesimulator/Runner.app'
));

let driver;

async function mock(method, path, body) {
  const response = await fetch(new URL(path, mockUrl), {
    method,
    headers: body ? { 'content-type': 'application/json' } : {},
    body: body ? JSON.stringify(body) : undefined,
  });
  assert.equal(response.ok, true, `${method} ${path}: HTTP ${response.status}`);
  const text = await response.text();
  return text ? JSON.parse(text) : undefined;
}

async function resetMock() {
  await mock('POST', '/__admin/mappings/reset');
  await mock('POST', '/__admin/scenarios/reset');
  await mock('DELETE', '/__admin/requests');
}

function byId(identifier) {
  return platform === 'android'
    ? `//*[@resource-id="${identifier}"]`
    : `~${identifier}`;
}

async function control(identifier) {
  const element = await driver.$(byId(identifier));
  await element.waitForDisplayed({ timeout: 30000 });
  return element;
}

async function dismissKeyboard() {
  if (platform === 'ios') {
    if (await driver.execute('mobile: isKeyboardShown')) {
      await driver.execute('mobile: swipe', { direction: 'down' });
    }
  } else {
    if (await driver.isKeyboardShown()) {
      await driver.hideKeyboard();
    }
  }
}

// On iOS the identifier belongs to the Semantics wrapper, an
// XCUIElementTypeOther. Clearing it is a no-op, so typing would append to a
// pre-filled value. Drive the text field it wraps instead.
async function iosTextField(element) {
  for (const type of ['XCUIElementTypeTextField', 'XCUIElementTypeSecureTextField']) {
    const field = await element.$(`.//${type}`);
    if (await field.isExisting()) return field;
  }
  return element;
}

async function type(identifier, value) {
  await dismissKeyboard();
  const element = await control(identifier);
  if (platform === 'android') {
    await element.click();
    if (await element.getText()) {
      await element.clearValue();
      await element.click();
    }
    await driver.execute('mobile: type', { text: value });
  } else {
    const field = await iosTextField(element);
    await field.click();
    await field.clearValue();
    const current = (await field.getValue()) ?? '';
    if (current) await field.addValue('\b'.repeat(current.length));
    await field.addValue(value);
  }
}

// Obscured fields read back masked, so `masked` skips the read-back check.
// A field that is still animating in can drop the keystrokes, so confirm the
// value landed and type it again when it did not.
async function fill(identifier, value, { masked = false } = {}) {
  for (let attempt = 1; ; attempt++) {
    await type(identifier, value);
    if (masked) return;
    try {
      await driver.waitUntil(async () => (await readValue(identifier)) === value, {
        timeout: 10000,
        timeoutMsg: `O campo ${identifier} não recebeu o valor "${value}".`,
      });
      return;
    } catch (error) {
      if (attempt === 3) throw error;
    }
  }
}

async function readValue(identifier) {
  const element = await driver.$(byId(identifier));
  if (platform === 'android') return await element.getText();
  const field = await iosTextField(element);
  return (await field.getValue()) ?? '';
}

async function click(identifier) {
  await dismissKeyboard();
  const element = await driver.$(byId(identifier));
  await element.waitForExist({ timeout: 30000 });
  if (platform === 'ios') await element.waitForDisplayed({ timeout: 30000 });
  const button = await element.$(platform === 'android'
    ? './/android.widget.Button'
    : './/XCUIElementTypeButton');
  await (await button.isExisting() ? button : element).click();
}

async function ensureSignedOut() {
  await driver.waitUntil(async () => {
    const email = await driver.$(byId('bttr.auth.email'));
    const signOut = await driver.$(byId('bttr.auth.signOut'));
    return (await email.isExisting() && await email.isDisplayed()) ||
      (await signOut.isExisting() && await signOut.isDisplayed());
  }, { timeout: 30000, timeoutMsg: 'O app não exibiu login nem a sessão.' });
  const signOut = await driver.$(byId('bttr.auth.signOut'));
  if (await signOut.isExisting() && await signOut.isDisplayed()) {
    await click('bttr.auth.signOut');
  }
  await control('bttr.auth.email');
}

async function signIn() {
  await fill('bttr.auth.email', 'e2e@example.com');
  await fill('bttr.auth.password', 'Senha123!', { masked: true });
  await click('bttr.auth.signIn');
  await control('bttr.skills.new');
}

async function recordedRequests(path) {
  const response = await mock('POST', '/__admin/requests/find', {
    method: 'POST',
    urlPath: path,
  });
  return response.requests;
}

describe(`Appium ${platform} (${platform === 'android' ? 'UiAutomator2' : 'XCUITest'})`, function () {
  before(async function () {
    // Bootstrapping the session installs the app and, on a cold iOS agent,
    // builds WebDriverAgent with xcodebuild, which alone takes several minutes.
    this.timeout(900000);
    await resetMock();
    const capabilities = platform === 'android'
      ? {
          platformName: 'Android',
          'appium:automationName': 'UiAutomator2',
          'appium:app': appPath,
          'appium:udid': process.env.E2E_ANDROID_UDID,
          'appium:fullReset': true,
          'appium:autoGrantPermissions': true,
        }
      : {
          platformName: 'iOS',
          'appium:automationName': 'XCUITest',
          'appium:app': appPath,
          'appium:udid': process.env.E2E_IOS_UDID,
          'appium:platformVersion': process.env.E2E_IOS_PLATFORM_VERSION,
          'appium:fullReset': true,
          'appium:autoDismissAlerts': true,
        };
    Object.keys(capabilities).forEach(key => {
      if (capabilities[key] === undefined) delete capabilities[key];
    });
    driver = await remote({
      hostname: appiumUrl.hostname,
      port: Number(appiumUrl.port || 4723),
      path: appiumUrl.pathname,
      logLevel: 'error',
      capabilities,
    });
    await ensureSignedOut();
    await resetMock();
  });

  afterEach(async function () {
    if (!driver) return;
    try {
      if (this.currentTest.state === 'failed') {
        await mkdir('test-results', { recursive: true });
        await driver.saveScreenshot(resolve(
          `test-results/appium-${platform}-${this.currentTest.title.replace(/[^a-z0-9]+/gi, '-').toLowerCase()}.png`
        ));
      }
    } catch (error) {
      console.error('Não foi possível salvar a captura da falha:', error);
    }
  });

  after(async function () {
    if (driver) await driver.deleteSession();
    driver = undefined;
  });

  it('entra, cria uma habilidade e sai da conta', async function () {
    await signIn();
    assert.equal((await recordedRequests('/users/sign_in')).length, 1);
    await click('bttr.skills.new');
    await fill('bttr.skills.name', 'Kotlin');
    await fill('bttr.skills.daily', '60');
    await click('bttr.skills.create');
    await (await driver.$(byId('bttr.skills.create'))).waitForDisplayed({
      reverse: true,
      timeout: 30000,
    });
    await control('bttr.skills.new');
    const requests = await recordedRequests('/skills/create_skill');
    assert.equal(requests.length, 1);
    assert.deepEqual(JSON.parse(requests[0].body), {
      name: 'Kotlin',
      daily: 60,
    });
    await click('bttr.auth.signOut');
    await control('bttr.auth.email');
  });
});
