import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

// A suíte dirige um aplicativo já compilado, e tudo o que decide qual
// aplicativo é esse vem do ambiente: a plataforma, o dispositivo e o caminho do
// pacote. Quando um desses falta, o erro só aparece lá na frente — como
// "elemento não encontrado" no primeiro `it` — e manda procurar o defeito no
// aplicativo em vez de no comando que subiu a execução.
//
// Por isso as asserções aqui são fail-closed, como a guarda de ambiente do
// projeto de referência: qualquer sinal ausente aborta antes de a sessão abrir.
// Abortar cedo custa segundos; abortar tarde custa a execução inteira, porque o
// `before` que falha faz o mocha descartar todos os testes do arquivo.
const PLATFORMS = ['android', 'ios'];

// O caminho padrão é o mesmo que o scripts/appium-e2e-ci.sh usa ao compilar, e
// existe para a execução local funcionar sem exportar nada. Em CI o script
// sempre exporta E2E_APP_PATH.
const APP_PATHS = {
  android: 'build/app/outputs/flutter-apk/app-debug.apk',
  ios: 'build/ios/iphonesimulator/Runner.app',
};

const APPIUM_STATUS_TIMEOUT_MS = 3000;

function abort(message) {
  throw new Error(`e2e abortado: ${message}`);
}

export function readPlatform() {
  const platform = process.env.E2E_PLATFORM;

  if (!PLATFORMS.includes(platform)) {
    abort(
      `E2E_PLATFORM inválido: "${platform ?? ''}". ` +
        "Use 'npm run test:e2e:android' ou 'npm run test:e2e:ios', que definem a variável.",
    );
  }

  return platform;
}

export function isAndroid() {
  return readPlatform() === 'android';
}

function readAppPath() {
  const platform = readPlatform();
  const appPath = resolve(process.env.E2E_APP_PATH ?? APP_PATHS[platform]);

  if (!existsSync(appPath)) {
    abort(
      `o aplicativo de ${platform} não existe em ${appPath}.\n` +
        "Compile antes de rodar, ou use 'scripts/appium-e2e-ci.sh', que compila com a URL do mock.",
    );
  }

  return appPath;
}

export function readAppiumServer() {
  const url = new URL(process.env.APPIUM_SERVER_URL ?? 'http://127.0.0.1:4723');

  return {
    hostname: url.hostname,
    port: Number(url.port || 4723),
    path: url.pathname,
    statusUrl: new URL('/status', url).toString(),
  };
}

// O `appium:app` instala o pacote uma vez por sessão, e o `fullReset` garante
// que a instalação não herde dados de uma execução anterior. Dentro da execução
// quem devolve o estado inicial é o controlApp, porque reinstalar a cada teste
// enche o armazenamento do dispositivo — foi o motivo de o projeto de
// referência trocar a reinstalação pelo "mobile: clearApp".
export function readCapabilities() {
  const appPath = readAppPath();
  const capabilities = isAndroid()
    ? {
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        'appium:app': appPath,
        'appium:udid': process.env.E2E_ANDROID_UDID,
        'appium:fullReset': true,
        'appium:autoGrantPermissions': true,
        // sem animação de janela as telas não ficam em estado intermediário, o
        // que reduz toque perdido em botão durante a transição
        'appium:disableWindowAnimation': process.env.E2E_SUITE !== 'performance',
        // margem para o servidor UiAutomator2 subir no emulador
        'appium:uiautomator2ServerLaunchTimeout': 120000,
        'appium:uiautomator2ServerInstallTimeout': 120000,
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

  // uma capability com valor indefinido não é "ausente" para o Appium: ela é
  // enviada como null e o driver recusa a sessão
  for (const key of Object.keys(capabilities)) {
    if (capabilities[key] === undefined) delete capabilities[key];
  }

  return capabilities;
}

// O servidor do Appium é subido pelo scripts/appium-e2e-ci.sh, fora do
// processo do mocha. Quando ele não está no ar, o `remote()` falha com um erro
// de conexão que não diz o que fazer; a mensagem daqui diz.
async function assertAppiumReady() {
  const { statusUrl } = readAppiumServer();
  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    APPIUM_STATUS_TIMEOUT_MS,
  );

  try {
    const response = await fetch(statusUrl, { signal: controller.signal });

    if (!response.ok) {
      abort(`o Appium respondeu ${response.status} em ${statusUrl}.`);
    }
  } catch (error) {
    abort(
      `o Appium não respondeu em ${statusUrl} (${error.message}).\n` +
        "Suba a execução com 'scripts/appium-e2e-ci.sh <plataforma>', que inicia o servidor.",
    );
  } finally {
    clearTimeout(timeout);
  }
}

export async function assertDeviceEnvironment() {
  readPlatform();
  readAppPath();
  readCapabilities();
  await assertAppiumReady();
}
