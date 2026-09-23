import { getDriver } from './session.js';

// Confere a presença de um elemento sem derrubar o teste quando ele não existe.
// A suíte precisa disso para decidir caminho, e não só para afirmar: o
// controlApp escolhe entre seguir e subir o aplicativo de novo conforme a tela
// de acesso aparecer, e o signOutScenario decide se ainda há sessão aberta antes
// de tentar sair dela.
export default async function isElementOnScreen(selector, timeout = 8000) {
  const elementToCheck = await getDriver().$(selector);

  return elementToCheck
    .waitForDisplayed({ timeout })
    .then(() => true)
    .catch(() => false);
}
