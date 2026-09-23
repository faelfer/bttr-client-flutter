import byText from './byText.js';
import isElementOnScreen from './isElementOnScreen.js';
import scrollToElement from './scrollToElement.js';
import tapUntil from './tapUntil.js';
import { getDriver } from './session.js';
import { isAndroid } from '../preflight/deviceEnvironment.js';

// Voltar é a mesma intenção com dois caminhos: no Android existe o botão voltar
// do sistema, que o aplicativo trata (o PopScope do AppShell decide o destino);
// no iOS não existe botão nenhum, e o que volta é o link de retorno que cada
// formulário desenha no alto ("Voltar às habilidades", "Voltar ao histórico",
// "Voltar ao perfil").
//
// O botão do sistema é preferido onde existe porque ele não depende do texto do
// link: o rótulo muda de tela para tela, e o link pode estar fora da área
// visível quando o passo anterior rolou a tela.
//
// A conferência espera a tela aparecer em vez de olhar no mesmo instante do
// toque: a navegação não é instantânea, e a checagem imediata acusava ausência
// antes da tela nova ser desenhada. Cada acusação dessas gastava um voltar a
// mais, o que levava a navegação para fora do aplicativo em vez de recuperá-la.
const SCREEN_TIMEOUT_MS = 6000;

async function isScreenReached(screenSelector) {
  if (await isElementOnScreen(screenSelector, SCREEN_TIMEOUT_MS)) {
    return true;
  }

  // a tela alvo pode ser mais alta que o aparelho, e aí o texto só aparece
  // depois de rolar — mas rolar não é o caminho comum, então só entra depois de
  // a espera não encontrar nada
  return scrollToElement(screenSelector)
    .then(() => true)
    .catch(() => false);
}

/**
 * @param {string} screenName texto que confirma a chegada à tela anterior
 * @param {string} backLabel rótulo do link de retorno, usado onde não há botão
 * voltar do sistema
 */
export default async function goBack(screenName, backLabel, maxAttempts = 3) {
  const screenSelector = byText(screenName);

  if (!isAndroid()) {
    if (backLabel === undefined) {
      throw new Error(
        `goBack | no iOS não há botão voltar do sistema: informe o rótulo do ` +
          `link de retorno para chegar em "${screenName}"`,
      );
    }

    await tapUntil(byText(backLabel), screenSelector);
    return;
  }

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    await getDriver().back();

    if (await isScreenReached(screenSelector)) {
      return;
    }

    console.log(`goBack | tentativa ${attempt} sem a tela: ${screenName}`);
  }

  throw new Error(`goBack | tela não encontrada ao voltar: ${screenName}`);
}
