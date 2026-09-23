import hideKeyboard from './hideKeyboard.js';
import tappableElement from './tappableElement.js';

// Toque simples, para o que não tem desfecho a esperar: abrir um menu, marcar
// uma opção, fechar um diálogo. Quando o toque leva a outra tela ou dispara uma
// chamada de API, o custom certo é o tapUntil, que confere o efeito e repete o
// toque perdido.
export default async function tapElement(selector) {
  await hideKeyboard();
  const element = await tappableElement(selector);
  await element.click();
}
