import byText from './byText.js';
import isElementOnScreen from './isElementOnScreen.js';
import scrollToElement from './scrollToElement.js';

// A espera vem antes da rolagem porque o texto conferido quase sempre chega de
// uma resposta da API e aparece onde a tela já está: esperar é o caminho comum,
// rolar é a exceção.
//
// A rolagem é para cima porque a tela não volta ao topo sozinha e o que se
// confere aqui fica no alto: título da tela, contagem da lista, nome da
// habilidade nas estatísticas. Depois de salvar um formulário o passo anterior
// já rolou até o botão no fim da tela, e o título saiu da área visível — a
// conferência acusava ausência de um texto que estava lá.
//
// O orçamento de gestos é curto de propósito: ele entra só no caminho de falha,
// que antes desta rolagem já era falha direta.
const SCREEN_TIMEOUT_MS = 25000;
const MAX_SCROLLS_UP = 6;

export default async function checkTextScreen(text) {
  const textSelector = byText(text);

  if (await isElementOnScreen(textSelector, SCREEN_TIMEOUT_MS)) {
    return;
  }

  await scrollToElement(textSelector, MAX_SCROLLS_UP, 'up');
}
