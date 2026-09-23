import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import createTimeStamp from './createTimeStamp.js';
import { ARTIFACTS_DIR } from './shotScreen.js';
import { getDriver } from './session.js';
import { isAndroid } from '../preflight/deviceEnvironment.js';

// O vídeo de cada teste é o que explica a falha que a captura não explica: o
// toque que não pegou, a tela que ficou a meio caminho, o campo que perdeu o
// foco. Ele é gravado pelo dispositivo e transferido em base64 no fim, então o
// tamanho do arquivo é custo de sessão, não só de disco.
//
// O padrão do Appium no Android (4 Mbps, 180s) não serve: a taxa gera arquivos
// de dezenas de MB por teste, e o limite de 180s é menor que o timeout do
// mocha — os testes longos seriam cortados justamente antes da falha. 1 Mbps
// mantém o vídeo legível para conferir a tela, e o limite acompanha o timeout
// da suíte.
//
// No iOS a gravação depende de o ffmpeg estar na máquina, e o driver só acusa
// isso na hora. Por isso a gravação inteira é best-effort: ela é evidência, e
// uma evidência que falta não pode virar falha de teste — seria trocar o
// resultado real do teste por um erro de artefato.
const RECORD_OPTIONS = {
  bitRate: 1000000,
  timeLimit: 480,
  forceRestart: true,
};

let isRecording = false;

export default {
  async start() {
    isRecording = false;

    try {
      await getDriver().startRecordingScreen(isAndroid() ? RECORD_OPTIONS : {});
      isRecording = true;
    } catch (error) {
      console.log(
        `recordScreen | gravação indisponível nesta execução (${error.message}): ` +
          'os testes seguem sem vídeo',
      );
    }
  },

  /**
   * @param {string} fileName nome do arquivo, sem carimbo nem extensão
   */
  async stop(fileName) {
    if (!isRecording) {
      return;
    }

    isRecording = false;
    const nameFile = `${fileName}_${createTimeStamp()}.mp4`;

    try {
      mkdirSync(ARTIFACTS_DIR, { recursive: true });
      const video = await getDriver().saveRecordingScreen(
        resolve(ARTIFACTS_DIR, nameFile),
      );

      // a sessão pode ter caído entre o start e o stop, e aí o arquivo sai com
      // zero byte: um vídeo vazio no meio dos artefatos se confunde com
      // gravação perdida, então a ausência é dita em voz alta
      if (video.length === 0) {
        console.log(`recordScreen | gravação vazia para "${nameFile}"`);
      }
    } catch (error) {
      console.log(`recordScreen | vídeo "${nameFile}" não foi salvo: ${error.message}`);
    }
  },
};
