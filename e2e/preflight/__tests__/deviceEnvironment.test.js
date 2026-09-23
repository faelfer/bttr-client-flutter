import assert from 'node:assert/strict';
import { readCapabilities, readPlatform } from '../deviceEnvironment.js';

// O ambiente é lido a cada chamada, e não guardado em um módulo: os testes
// abaixo trocam as variáveis e dependem disso. Mais importante, é isso que faz
// o mesmo processo do mocha poder rodar Android e iOS sem estado herdado.
function withEnvironment(environment, run) {
  const before = { ...process.env };
  Object.assign(process.env, environment);

  try {
    return run();
  } finally {
    for (const key of Object.keys(environment)) {
      if (before[key] === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = before[key];
      }
    }
  }
}

describe('deviceEnvironment', () => {
  it('acusa plataforma ausente ou desconhecida', () => {
    withEnvironment({ E2E_PLATFORM: '' }, () => {
      assert.throws(readPlatform, /E2E_PLATFORM inválido/);
    });

    withEnvironment({ E2E_PLATFORM: 'web' }, () => {
      assert.throws(readPlatform, /E2E_PLATFORM inválido/);
    });
  });

  it('acusa aplicativo inexistente com o caminho procurado', () => {
    withEnvironment(
      { E2E_PLATFORM: 'android', E2E_APP_PATH: 'build/inexistente.apk' },
      () => {
        assert.throws(readCapabilities, /build\/inexistente\.apk/);
      },
    );
  });

  // uma capability com valor indefinido não é "ausente" para o Appium: ela é
  // enviada como null e o driver recusa a sessão. É o caso de E2E_ANDROID_UDID
  // e E2E_IOS_UDID, que só existem quando quem chamou escolheu o dispositivo.
  it('não envia capability sem valor', () => {
    withEnvironment(
      {
        E2E_PLATFORM: 'android',
        E2E_APP_PATH: 'package.json',
        E2E_ANDROID_UDID: '',
      },
      () => {
        delete process.env.E2E_ANDROID_UDID;
        const capabilities = readCapabilities();

        assert.equal('appium:udid' in capabilities, false);
        assert.equal(capabilities.platformName, 'Android');
        assert.equal(capabilities['appium:automationName'], 'UiAutomator2');
      },
    );
  });

  it('monta as capabilities do XCUITest para iOS', () => {
    withEnvironment(
      {
        E2E_PLATFORM: 'ios',
        E2E_APP_PATH: 'package.json',
        E2E_IOS_UDID: 'UDID-SIMULADOR',
      },
      () => {
        const capabilities = readCapabilities();

        assert.equal(capabilities.platformName, 'iOS');
        assert.equal(capabilities['appium:automationName'], 'XCUITest');
        assert.equal(capabilities['appium:udid'], 'UDID-SIMULADOR');
      },
    );
  });
});
