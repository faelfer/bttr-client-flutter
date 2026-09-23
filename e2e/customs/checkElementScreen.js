import byIdentifier from './byIdentifier.js';
import scrollToElement from './scrollToElement.js';

// Espera um elemento identificado aparecer, rolando a tela quando ele está fora
// da área visível. É a conferência de "cheguei na tela certa": cada tela do
// aplicativo tem pelo menos um controle com identificador próprio.
export default async function checkElementScreen(identifier) {
  await scrollToElement(byIdentifier(identifier));
}
