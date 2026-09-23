import { remote } from 'webdriverio';
import { readAppiumServer, readCapabilities } from '../preflight/deviceEnvironment.js';

// O projeto de referência alcança o dispositivo pelos globais do WebdriverIO
// (`driver`, `$`), que só existem sob o runner do wdio. Aqui a suíte roda no
// mocha com o webdriverio como biblioteca, e esses globais não existem: cada
// custom precisa de um lugar comum de onde tirar a sessão, e é este módulo.
//
// A sessão é uma só para a execução inteira, e não uma por spec. O mocha roda
// todos os arquivos no mesmo processo — diferente dos workers do wdio, que
// abrem uma sessão por arquivo —, e abrir sessão custa caro: no agente de CI a
// primeira sessão de iOS ainda compila o WebDriverAgent com o xcodebuild, o que
// sozinho passa de vários minutos. O isolamento entre testes não vem da sessão:
// vem do controlApp.launch, que devolve o aplicativo ao estado inicial, e do
// reinício dos cenários do mock.
let session = null;

export async function openSession() {
  if (session !== null) {
    return session;
  }

  const { hostname, port, path } = readAppiumServer();

  session = await remote({
    hostname,
    port,
    path,
    logLevel: 'error',
    capabilities: readCapabilities(),
  });

  return session;
}

// A mensagem é explícita porque o erro nativo ("cannot read properties of
// null") apareceria dentro de um custom qualquer, longe da causa: um custom
// chamado fora dos hooks que abrem a sessão.
export function getDriver() {
  if (session === null) {
    throw new Error(
      'session | a sessão do Appium não está aberta: os customs só podem ser ' +
        'usados dentro dos testes, depois do root hook de e2e/preflight/hooks.js',
    );
  }

  return session;
}

// A sessão é encerrada mesmo quando o encerramento falha: um erro aqui viraria
// falha do hook final e esconderia o resultado dos testes que já rodaram.
export async function closeSession() {
  if (session === null) {
    return;
  }

  const closing = session;
  session = null;

  try {
    await closing.deleteSession();
  } catch (error) {
    console.log(`session | não foi possível encerrar a sessão: ${error.message}`);
  }
}
