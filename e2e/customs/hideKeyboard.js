import { getDriver } from './session.js';
import { isAndroid } from '../preflight/deviceEnvironment.js';

// Depois de digitar, o teclado cobre a parte de baixo da tela, que é justamente
// onde ficam os botões de enviar dos formulários. O driver reclama quando não há
// teclado aberto, e esse erro não interessa a ninguém: quem chama só quer a tela
// livre.
//
// No iOS não existe hideKeyboard genérico para o simulador; o que fecha o
// teclado é um gesto para baixo na tela.
export default async function hideKeyboard() {
  const driver = getDriver();

  try {
    if (isAndroid()) {
      if (await driver.isKeyboardShown()) {
        await driver.hideKeyboard();
      }

      return;
    }

    if (await driver.execute('mobile: isKeyboardShown')) {
      await driver.execute('mobile: swipe', { direction: 'down' });
    }
  } catch (error) {
    console.log(`hideKeyboard | ${error.message}`);
  }
}
