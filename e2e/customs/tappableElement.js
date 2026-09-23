import scrollToElement from './scrollToElement.js';
import { isAndroid } from '../preflight/deviceEnvironment.js';

// O identificador de um botão fica no Semantics que o envolve, e no Android esse
// nó é um contêiner: o toque que conta é o do botão de dentro. Tocar no
// contêiner às vezes funciona por coincidência de área, e às vezes não — e
// quando não funciona o sintoma é o pior possível, um toque aceito sem efeito
// nenhum, que o tapUntil só descobre depois de repetir e desistir.
//
// Por isso o toque desce até o botão quando existe um. Quando não existe — um
// item de lista, um texto tocável — o próprio elemento é o alvo, e a busca
// abaixo não custa nada além de uma consulta.
const BUTTON_TYPES = {
  android: './/android.widget.Button',
  ios: './/XCUIElementTypeButton',
};

export default async function tappableElement(selector) {
  const element = await scrollToElement(selector);
  const button = await element.$(isAndroid() ? BUTTON_TYPES.android : BUTTON_TYPES.ios);

  return (await button.isExisting()) ? button : element;
}
