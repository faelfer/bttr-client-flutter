import assert from 'node:assert/strict';
import { execFileSync, spawn } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import byIdentifier from '../customs/byIdentifier.js';
import controlApp from '../customs/controlApp.js';
import requestMockApi, { resetMockApi } from '../customs/requestMockApi.js';
import { closeSession, getDriver, openSession } from '../customs/session.js';
import toTab from '../customs/toTab.js';
import signInScenario from '../scenarios/signInScenario.js';
import userFactory from '../factories/userFactory.js';
import { assertDeviceEnvironment } from '../preflight/deviceEnvironment.js';
import { assertMockApiEnvironment } from '../preflight/mockApiEnvironment.js';
import { assertFrameBudget, summarizeFrames } from './frameReport.js';

const serial = process.env.E2E_ANDROID_UDID;
const appId = 'com.bttr.bttr_client_flutter';
const tracePath = '/data/misc/perfetto-traces/bttr-performance.perfetto-trace';

function adb(...args) {
  return execFileSync('adb', ['-s', serial, ...args], { encoding: 'utf8', maxBuffer: 4 * 1024 * 1024 });
}

async function scrollSkills(driver) {
  const { width, height } = await driver.getWindowSize();
  for (let index = 0; index < 4; index += 1) {
    await driver.execute('mobile: scrollGesture', {
      left: Math.round(width * 0.1), top: Math.round(height * 0.2),
      width: Math.round(width * 0.8), height: Math.round(height * 0.6),
      direction: index % 2 === 0 ? 'down' : 'up', percent: 0.8,
    });
  }
}

async function recordTrace(action) {
  const trace = spawn('adb', [
    '-s', serial, 'shell', 'perfetto', '-t', '30s', '-o', tracePath,
    'sched', 'freq', 'gfx', 'view',
  ], { stdio: ['ignore', 'ignore', 'pipe'] });
  const traceFinished = new Promise((resolve) => trace.on('close', resolve));
  let errorOutput = '';
  trace.stderr.on('data', (chunk) => { errorOutput += chunk; });
  try {
    await action();
  } finally {
    const exitCode = await traceFinished;
    assert.equal(exitCode, 0, `Perfetto falhou: ${errorOutput}`);
    adb('pull', tracePath, 'test-results/performance/app.perfetto-trace');
  }
}

describe('Performance Android com API mock', function () {
  this.timeout(480000);

  before(async () => {
    await assertMockApiEnvironment();
    await assertDeviceEnvironment();
    await openSession();
  });

  after(async () => {
    await closeSession();
  });

  it('valida frames do Flutter em fluxos de acesso e navegação', async () => {
    mkdirSync('test-results/performance', { recursive: true });
    await resetMockApi();
    await requestMockApi('/__admin/settings', {
      method: 'POST', body: { fixedDelay: 100 },
    });
    try {
      await controlApp.launch();
      await signInScenario(userFactory(false), byIdentifier('bttr.skills.new'));
      const driver = getDriver();
      await scrollSkills(driver);
      await toTab('Histórico', 'Histórico de tempo');
      await driver.$(byIdentifier('bttr.times.new')).waitForDisplayed({ timeout: 30000 });
      // Release mode delivers FrameTiming batches approximately once a second.
      await new Promise((resolve) => setTimeout(resolve, 1500));
      const csv = adb('exec-out', 'cat', `/sdcard/Android/media/${appId}/performance-frames.csv`);
      writeFileSync('test-results/performance/frames.csv', csv);
      const summary = summarizeFrames(csv);
      writeFileSync('test-results/performance/frames.json', JSON.stringify(summary, null, 2));
      console.log(
        `Frames: ${summary.frameCount}; p95 build=${summary.p95BuildMs}ms; ` +
        `raster=${summary.p95RasterMs}ms; total=${summary.p95TotalMs}ms`,
      );
      // Capture a replay so Perfetto's tracing overhead cannot skew the gate.
      await recordTrace(async () => {
        await toTab('Habilidades', 'Minhas habilidades');
        await scrollSkills(driver);
        await toTab('Histórico', 'Histórico de tempo');
      });
      try {
        assertFrameBudget(summary);
      } catch (error) {
        console.error(`Gate de frames reprovado: ${error.message}`);
        throw error;
      }
    } finally {
      await controlApp.close();
      await requestMockApi('/__admin/settings', { method: 'POST', body: { fixedDelay: 0 } });
    }
  });
});
