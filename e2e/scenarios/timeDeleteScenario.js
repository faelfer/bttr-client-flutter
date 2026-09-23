import byIdentifier from '../customs/byIdentifier.js';
import byText from '../customs/byText.js';
import tapUntil from '../customs/tapUntil.js';
import timeOpenScenario from './timeOpenScenario.js';

// Mesma forma da exclusão de habilidade: o botão mora no formulário de edição e
// passa por um diálogo de confirmação.
const CONFIRM_TITLE = 'Confirmar exclusão';
const CONFIRM_BUTTON = 'Sim, excluir';

export default async function timeDeleteScenario(time, expectedSelector) {
  await timeOpenScenario(time);
  await tapUntil(byIdentifier('bttr.times.delete'), byText(CONFIRM_TITLE));
  await tapUntil(byText(CONFIRM_BUTTON), expectedSelector);
}
