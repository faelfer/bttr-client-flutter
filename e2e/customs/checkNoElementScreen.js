import byIdentifier from './byIdentifier.js';
import { getDriver } from './session.js';

// Confere que um elemento saiu da tela. É o que separa "a mutação foi enviada"
// de "a mutação terminou": o formulário só desaparece quando o aplicativo
// navega de volta para a lista, e enquanto o botão de salvar está lá a operação
// ainda está em curso.
export default async function checkNoElementScreen(identifier, timeout = 30000) {
  const elementToCheck = await getDriver().$(byIdentifier(identifier));
  await elementToCheck.waitForDisplayed({ timeout, reverse: true });
}
