import { getDriver } from './session.js';
import { isAndroid } from '../preflight/deviceEnvironment.js';

// As telas do aplicativo são mais altas que o aparelho — o formulário de
// habilidade tem o painel de dica no fim, o perfil tem três painéis empilhados e
// o botão de excluir conta fica no último — e a automação só interage com o que
// está na área visível. Rola até o elemento aparecer e devolve o elemento pronto
// para uso.
//
// A direção é parâmetro porque nem tudo o que se procura está abaixo: descer é o
// caminho comum (campo de formulário, botão no fim da tela) e continua sendo o
// padrão, mas o título da tela fica acima quando o passo anterior já rolou.
// Cobrir as duas direções por padrão somaria dezenas de gestos ao caminho de
// falha de todos os helpers que rolam a tela.
//
// O gesto é o do driver de cada plataforma, e não um arrasto de ponteiro
// montado à mão: o ponteiro manual não gera velocidade suficiente para a rolagem
// do Flutter reagir, e o resultado é a tela voltando ao lugar.
const SCROLL_AREA_RATIO = { left: 0.1, top: 0.2, width: 0.8, height: 0.6 };

async function scrollOnce(direction) {
  const driver = getDriver();
  const { width, height } = await driver.getWindowSize();

  if (isAndroid()) {
    await driver.execute('mobile: scrollGesture', {
      left: Math.round(width * SCROLL_AREA_RATIO.left),
      top: Math.round(height * SCROLL_AREA_RATIO.top),
      width: Math.round(width * SCROLL_AREA_RATIO.width),
      height: Math.round(height * SCROLL_AREA_RATIO.height),
      direction,
      percent: 1.0,
    });
    return;
  }

  // No XCUITest o "mobile: swipe" move o conteúdo no sentido do gesto, que é o
  // contrário do sentido da rolagem: para ver o que está abaixo, o dedo sobe.
  await driver.execute('mobile: swipe', {
    direction: direction === 'down' ? 'up' : 'down',
  });
}

export default async function scrollToElement(
  selector,
  maxScrolls = 8,
  direction = 'down',
) {
  const driver = getDriver();

  for (let attempt = 0; attempt <= maxScrolls; attempt += 1) {
    const elementToFind = await driver.$(selector);
    const isDisplayed = await elementToFind.isDisplayed().catch(() => false);

    if (isDisplayed) {
      return elementToFind;
    }

    await scrollOnce(direction);
  }

  throw new Error(`scrollToElement | elemento não encontrado: ${selector}`);
}
