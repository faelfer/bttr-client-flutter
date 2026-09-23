import hideKeyboard from './hideKeyboard.js';
import tappableElement from './tappableElement.js';
import { getDriver } from './session.js';

// As telas do aplicativo carregam dados no início e se redesenham quando a
// resposta chega — a lista de habilidades, o formulário de tempo (que busca as
// habilidades disponíveis) e o perfil fazem isso. Um toque que cai nesse
// intervalo é perdido sem erro: o botão continua na tela e nada acontece. Este
// custom repete o toque até o efeito esperado aparecer.
//
// Enquanto o gatilho continua visível, o toque não foi aceito e vale repetir.
// Quando ele some — o PrimaryButton troca o rótulo por um indicador de
// progresso enquanto a operação corre, ou a tela mudou — o toque já foi aceito e
// só falta a resposta: aí a espera é longa e sem repetição, para a mesma
// mutação não sair duas vezes.
//
// Enviar duas vezes não é um detalhe aqui: os cenários do mock têm estado, e uma
// criação repetida leva o cenário além do estado que o teste seguinte espera —
// o mapeamento de criação fora de sequência responde justamente "o cenário
// precisa ser reiniciado". As conferências de payload também contam
// requisições, e a segunda quebraria a contagem.
//
// expectedSelector aceita uma lista quando o toque tem mais de um desfecho
// válido — o acesso termina na lista de habilidades ou na mensagem de erro. A
// lista evita união de XPath ("a | b"), que os drivers não resolvem.
//
// O retorno é a quantidade de toques enviados, que é também a quantidade de
// respostas a esperar: quem confere payload usa esse número para saber se a
// contagem de requisições deveria ser uma só.
const TAP_TIMEOUT_MS = 30000;
const SETTLE_TIMEOUT_MS = 60000;
const POLL_INTERVAL_MS = 300;

async function isAnyDisplayed(selectors) {
  const driver = getDriver();

  for (const selector of selectors) {
    const elementToCheck = await driver.$(selector);

    if (await elementToCheck.isDisplayed().catch(() => false)) {
      return true;
    }
  }

  return false;
}

async function waitAnyDisplayed(selectors, timeout) {
  const timeLimit = Date.now() + timeout;

  do {
    if (await isAnyDisplayed(selectors)) {
      return true;
    }

    await getDriver().pause(POLL_INTERVAL_MS);
  } while (Date.now() < timeLimit);

  return false;
}

export default async function tapUntil(tapSelector, expectedSelector, maxAttempts = 3) {
  const expectedSelectors = [].concat(expectedSelector);

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    await hideKeyboard();
    const elementToTap = await tappableElement(tapSelector);
    await elementToTap.click();

    if (await waitAnyDisplayed(expectedSelectors, TAP_TIMEOUT_MS)) {
      return attempt;
    }

    const isTapStillAvailable = await getDriver()
      .$(tapSelector)
      .isDisplayed()
      .catch(() => false);

    if (!isTapStillAvailable) {
      if (await waitAnyDisplayed(expectedSelectors, SETTLE_TIMEOUT_MS)) {
        return attempt;
      }

      break;
    }

    console.log(`tapUntil | toque perdido em ${tapSelector}, tentativa ${attempt}`);
  }

  throw new Error(
    `tapUntil | ${expectedSelectors.join(' ou ')} não apareceu após tocar em ${tapSelector}`,
  );
}
