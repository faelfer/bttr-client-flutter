import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { appId, isForeground } from './controlApp.js';
import { ARTIFACTS_DIR } from './shotScreen.js';
import { getDriver } from './session.js';
import { isAndroid } from '../preflight/deviceEnvironment.js';

// O vídeo mostra o sintoma (a tela que ficou), mas não a causa quando o
// aplicativo sai do primeiro plano no meio do teste: queda do processo,
// encerramento por memória e navegação para fora terminam todos na mesma
// imagem. Este dump guarda, junto do vídeo, o pacote em primeiro plano no
// instante da falha e o fim do log do dispositivo, que é onde aparece a exceção
// fatal ou a linha do encerramento por memória.
const LOG_TAIL_LINES = 1200;

// O próprio driver escreve no log a cada busca de elemento, e uma espera de 25s
// enche a janela inteira com esse ruído: sem descartar essas linhas o dump não
// alcança o momento em que o aplicativo saiu do ar. Os serviços do emulador
// entram na mesma conta — são ruído do ambiente, não do aplicativo.
//
// As bordas de palavra evitam que uma etiqueta curta case dentro de outra
// palavra e leve junto uma linha que interessa.
const NOISE_TAGS = new RegExp(
  `\\b(${[
    'appium',
    'uiautomator',
    'UiAutomator',
    'io\\.appium',
    'artd',
    'mapper\\.ranchu',
    'Finsky',
    'WindowManagerShell',
    'BackgroundInstallControlService',
    'libbinder',
  ].join('|')})\\b`,
);

// Linhas que explicam sozinhas por que o aplicativo sumiu da tela. Elas são
// repetidas no topo do arquivo porque a causa costuma estar centenas de linhas
// acima do fim do log, e o fim é o que sobra depois do corte.
const CRASH_MARKS =
  /(FATAL EXCEPTION|AndroidRuntime|ANR in|lowmemorykiller|Force finishing|WIN DEATH|Process .* has died|Fatal error)/;
const CRASH_MARK_LINES = 60;

async function readForegroundApp() {
  // o Android diz qual pacote está na frente, o que separa "o aplicativo caiu"
  // de "o teste navegou para fora dele". O iOS não expõe isso: o que dá para
  // saber é se o aplicativo sob teste ainda está em primeiro plano, que já
  // responde a pergunta que importa aqui.
  if (!isAndroid()) {
    return (await isForeground()) ? appId() : 'outro aplicativo, ou nenhum';
  }

  return await getDriver()
    .getCurrentPackage()
    .catch((error) => `indisponível (${error.message})`);
}

async function readLogLines() {
  try {
    const logs = await getDriver().getLogs(isAndroid() ? 'logcat' : 'syslog');

    return logs
      .map((entry) => entry.message)
      .filter((message) => !NOISE_TAGS.test(message));
  } catch (error) {
    return [`log do dispositivo indisponível (${error.message})`];
  }
}

export default async function dumpDeviceLog(titleTest) {
  const foregroundApp = await readForegroundApp();
  const logLines = await readLogLines();
  const crashLines = logLines
    .filter((message) => CRASH_MARKS.test(message))
    .slice(0, CRASH_MARK_LINES);
  const fileName = `FAILED_${titleTest.replace(/[^\w-]+/g, '_').slice(0, 80)}_${Date.now()}.log`;

  const report = [
    `teste: ${titleTest}`,
    `aplicativo esperado em primeiro plano: ${appId()}`,
    `primeiro plano na falha: ${foregroundApp}`,
    foregroundApp === appId()
      ? ''
      : '⚠️  o aplicativo não estava em primeiro plano: procure a queda do processo abaixo',
    '',
    crashLines.length === 0
      ? '--- nenhuma queda de processo no log ---'
      : `--- queda de processo no log (${crashLines.length} primeiras linhas) ---`,
    ...crashLines,
    '',
    `--- últimas ${LOG_TAIL_LINES} linhas do log do dispositivo ---`,
    logLines.slice(-LOG_TAIL_LINES).join('\n'),
  ].join('\n');

  try {
    mkdirSync(ARTIFACTS_DIR, { recursive: true });
    writeFileSync(resolve(ARTIFACTS_DIR, fileName), report);
    console.log(`🧾 | log da falha salvo em e2e/artifacts/${fileName}`);
  } catch (error) {
    console.log(`dumpDeviceLog | não foi possível salvar o log: ${error.message}`);
  }
}
