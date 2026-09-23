import byIdentifier from './byIdentifier.js';
import isElementOnScreen from './isElementOnScreen.js';
import tapUntil from './tapUntil.js';
import { getDriver } from './session.js';
import { isAndroid } from '../preflight/deviceEnvironment.js';

// Cada teste precisa começar do zero, e "do zero" aqui é a tela de acesso sem
// sessão salva. Reinstalar o aplicativo a cada teste devolveria isso, mas custa
// caro e enche o armazenamento do dispositivo ao longo de uma execução inteira —
// foi o motivo de o projeto de referência trocar a reinstalação pela limpeza de
// dados. A instalação acontece uma vez por sessão, pela capability
// `appium:app` com `fullReset`.
//
// As duas plataformas chegam ao mesmo estado por caminhos diferentes, e a
// diferença é onde o token fica guardado:
//
// - no Android ele está no armazenamento criptografado do aplicativo, e o
//   "mobile: clearApp" apaga o pacote inteiro de dados de uma vez;
// - no iOS ele está no Keychain, que sobrevive a encerrar, limpar e até
//   reinstalar o aplicativo. Não há comando equivalente, então a sessão é
//   encerrada pela própria interface — que é, afinal, o caminho que o usuário
//   tem.
//
// A saída pela interface mora aqui, e não no signOutScenario, para não inverter
// a dependência: cenário usa custom, custom não usa cenário. O signOutScenario
// continua existindo porque ele é o teste da saída; este bloco é só o preparo do
// teste seguinte.
const APP_IDS = {
  android: 'com.bttr.bttr_client_flutter',
  ios: 'com.bttr.bttrClientFlutter',
};

const SIGN_IN_FIELD = 'bttr.auth.email';
const SIGN_OUT_BUTTON = 'bttr.auth.signOut';

// As aberturas boas desenham a tela de acesso em poucos segundos; a margem cobre
// o emulador carregado, em que o primeiro desenho passa de meio minuto.
const SIGN_IN_TIMEOUT_MS = 60000;
const SESSION_TIMEOUT_MS = 30000;
const FOREGROUND_TIMEOUT_MS = 60000;
const FOREGROUND_INTERVAL_MS = 1000;
const LAUNCH_ATTEMPTS = 2;

export function appId() {
  return isAndroid() ? APP_IDS.android : APP_IDS.ios;
}

export async function isForeground() {
  // 4 é o estado "rodando em primeiro plano" do protocolo do Appium, igual nos
  // dois drivers
  return (await getDriver()
    .queryAppState(appId())
    .catch(() => 0)) === 4;
}

// O activateApp devolve quando o sistema aceita o pedido de abertura, e não
// quando a tela do aplicativo aparece. Com o dispositivo carregado a diferença é
// grande, e o passo seguinte iria procurar o campo de e-mail na árvore da tela
// inicial do sistema.
async function activateUntilForeground() {
  const driver = getDriver();
  await driver.activateApp(appId());
  await driver.waitUntil(isForeground, {
    timeout: FOREGROUND_TIMEOUT_MS,
    interval: FOREGROUND_INTERVAL_MS,
    timeoutMsg:
      `controlApp | o aplicativo não chegou ao primeiro plano em ` +
      `${FOREGROUND_TIMEOUT_MS}ms: veja o log salvo em e2e/artifacts`,
  });
}

// Primeiro plano não é o mesmo que utilizável: o aplicativo pode aparecer e a
// primeira tela não ser desenhada. A tela de acesso é o desfecho garantido de
// uma abertura boa — sem sessão o roteador manda toda rota protegida para ela —,
// então é ela que diz se a abertura valeu. Esperar mais não resolve; o que
// resolve é subir de novo.
async function reachSignInScreen() {
  if (await isElementOnScreen(byIdentifier(SIGN_IN_FIELD), SIGN_IN_TIMEOUT_MS)) {
    return true;
  }

  // sessão de sobra do teste anterior (o caso do iOS, em que o token fica no
  // Keychain): o aplicativo abre direto na área autenticada, e a saída pela
  // interface devolve a tela de acesso
  if (await isElementOnScreen(byIdentifier(SIGN_OUT_BUTTON), SESSION_TIMEOUT_MS)) {
    await tapUntil(byIdentifier(SIGN_OUT_BUTTON), byIdentifier(SIGN_IN_FIELD));

    return true;
  }

  return false;
}

export default {
  appId,
  isForeground,

  async launch() {
    const driver = getDriver();

    for (let attempt = 1; attempt <= LAUNCH_ATTEMPTS; attempt += 1) {
      // encerrar antes de abrir garante o estado inicial mesmo quando o teste
      // anterior terminou de forma inesperada
      await driver.terminateApp(appId());

      if (isAndroid()) {
        await driver.execute('mobile: clearApp', { appId: appId() });
      }

      await activateUntilForeground();

      if (await reachSignInScreen()) {
        return;
      }

      if (attempt === LAUNCH_ATTEMPTS) {
        throw new Error(
          'controlApp | o aplicativo subiu sem a tela de acesso em ' +
            `${LAUNCH_ATTEMPTS} aberturas: veja a captura e o log em e2e/artifacts`,
        );
      }

      console.log(
        `controlApp | o aplicativo subiu em branco na abertura ${attempt} ` +
          '(sem a tela de acesso): subindo de novo',
      );
    }
  },

  async close() {
    await getDriver()
      .terminateApp(appId())
      .catch((error) => console.log(`controlApp | encerramento: ${error.message}`));
  },
};
