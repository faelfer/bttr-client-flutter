import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import createTimeStamp from './createTimeStamp.js';
import { getDriver } from './session.js';

// As capturas vão para e2e/artifacts junto dos vídeos e dos logs de falha: um
// lugar só para tudo o que a execução deixou. O relatório JUnit do mocha não
// carrega imagem, então o que liga a captura ao teste é o nome do arquivo —
// daí o nome ser escolhido por quem captura, e não gerado.
//
// Uma captura que falha não pode derrubar o teste. Ela é evidência, não
// asserção: o dispositivo pode recusar a captura no meio de uma transição de
// tela, e transformar isso em falha trocaria o resultado real do teste por um
// erro de artefato.
export const ARTIFACTS_DIR = resolve('e2e/artifacts');

export default {
  async capture(fileName) {
    const nameFile = `${fileName}_${createTimeStamp()}.png`;

    try {
      mkdirSync(ARTIFACTS_DIR, { recursive: true });
      await getDriver().saveScreenshot(resolve(ARTIFACTS_DIR, nameFile));
    } catch (error) {
      console.log(`shotScreen | captura "${nameFile}" não foi salva: ${error.message}`);
    }
  },
};
