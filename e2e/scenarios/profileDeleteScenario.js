import byIdentifier from '../customs/byIdentifier.js';
import byText from '../customs/byText.js';
import tapUntil from '../customs/tapUntil.js';

// Exclusão da conta. O botão fica no último painel do perfil, abaixo da área
// visível na maioria dos aparelhos — quem rola até ele é o tapUntil, pelo
// scrollToElement.
//
// O desfecho é a tela de acesso: o aplicativo apaga a sessão junto da conta, e o
// roteador manda qualquer rota protegida de volta para o acesso.
const CONFIRM_TITLE = 'Confirmar exclusão';
const CONFIRM_BUTTON = 'Sim, excluir';

export default async function profileDeleteScenario(expectedSelector) {
  await tapUntil(byIdentifier('bttr.profile.delete'), byText(CONFIRM_TITLE));
  await tapUntil(byText(CONFIRM_BUTTON), expectedSelector);
}
