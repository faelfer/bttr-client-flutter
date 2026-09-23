import controlApp from '../customs/controlApp.js';
import dumpDeviceLog from '../customs/dumpDeviceLog.js';
import recordScreen from '../customs/recordScreen.js';
import shotScreen from '../customs/shotScreen.js';
import { resetMockApi } from '../customs/requestMockApi.js';
import { closeSession, openSession } from '../customs/session.js';
import { assertDeviceEnvironment } from './deviceEnvironment.js';
import { assertAppReachedMockApi, assertMockApiEnvironment } from './mockApiEnvironment.js';

// Os hooks de raiz do mocha fazem aqui o papel dos hooks do wdio.conf.js no
// projeto de referência: guarda de ambiente antes de tudo, estado inicial antes
// de cada teste e artefato depois. Ficarem em um lugar só, e não repetidos no
// começo de cada spec, é o que garante que um spec novo nasça com a mesma
// preparação — a repetição é onde um spec acaba esquecendo de reiniciar o
// cenário do mock e passa a depender do que o anterior deixou.
//
// A ordem do beforeEach importa: o cenário do mock é reiniciado antes de o
// aplicativo abrir, porque a primeira tela já dispara chamadas e uma resposta de
// estado herdado chegaria antes do reinício.
const SESSION_TIMEOUT_MS = 900000;
const SETUP_TIMEOUT_MS = 180000;
const ARTIFACT_NAME_LIMIT = 60;

let isMockReachChecked = false;

// O nome do artefato sai do título do teste porque é o título que o relatório
// JUnit mostra: quem lê a falha no relatório encontra o vídeo e a captura pelo
// mesmo texto. O corte existe porque os títulos são frases inteiras em
// português, e nome de arquivo longo fica truncado nas ferramentas que leem o
// diretório — o corte aqui é previsível, o delas não.
function artifactName(test) {
  const title = test.title
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^\w-]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, ARTIFACT_NAME_LIMIT);

  return `${test.state === 'failed' ? 'FAILED_' : ''}${title}`;
}

export const mochaHooks = {
  async beforeAll() {
    // a primeira sessão de iOS ainda compila o WebDriverAgent com o xcodebuild
    // em um agente frio, o que sozinho passa de vários minutos
    this.timeout(SESSION_TIMEOUT_MS);

    await assertMockApiEnvironment();
    await assertDeviceEnvironment();
    await openSession();
  },

  async beforeEach() {
    this.timeout(SETUP_TIMEOUT_MS);

    await resetMockApi();
    await controlApp.launch();
    await recordScreen.start();
  },

  async afterEach() {
    this.timeout(SETUP_TIMEOUT_MS);
    const test = this.currentTest;

    await recordScreen.stop(artifactName(test));

    if (test.state === 'failed') {
      await shotScreen.capture(artifactName(test));
      await dumpDeviceLog(test.title);
      await warnWhenAppMissedMockApi();
    }

    await controlApp.close();
  },

  async afterAll() {
    await closeSession();
  },
};

// A causa mais cara de investigar é o pacote instalado apontar para outra URL de
// API: todo teste falha no primeiro acesso, e a mensagem que aparece é sempre a
// mesma "elemento não encontrado", que manda procurar o defeito na tela.
//
// A conferência avisa em vez de lançar porque ela roda depois de o teste já ter
// falhado: lançar aqui trocaria a falha real do teste, que é o que o relatório
// precisa mostrar, pela falha do hook. E acontece uma vez só — depois do
// primeiro acesso registrado, a dúvida não existe mais.
async function warnWhenAppMissedMockApi() {
  if (isMockReachChecked) {
    return;
  }

  try {
    await assertAppReachedMockApi();
    isMockReachChecked = true;
  } catch (error) {
    console.log(`⚠️  | ${error.message}`);
  }
}
