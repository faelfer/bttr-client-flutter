import byIdentifier from '../customs/byIdentifier.js';
import byText from '../customs/byText.js';
import skillOpenScenario from './skillOpenScenario.js';
import tapUntil from '../customs/tapUntil.js';

// A exclusão mora dentro do formulário de edição, e passa por um diálogo de
// confirmação que descreve o que será apagado junto — habilidade e registros de
// tempo dela.
//
// O toque no botão de excluir espera o diálogo, e não a exclusão: o diálogo é o
// efeito imediato, e é ele que diz se o toque foi aceito. Confundir os dois
// faria o tapUntil repetir o toque enquanto o diálogo já estava aberto, e o
// segundo toque cairia no diálogo em vez de no botão.
const CONFIRM_TITLE = 'Confirmar exclusão';
const CONFIRM_BUTTON = 'Sim, excluir';

export default async function skillDeleteScenario(skill, expectedSelector) {
  await skillOpenScenario(skill);
  await tapUntil(byIdentifier('bttr.skills.delete'), byText(CONFIRM_TITLE));
  await tapUntil(byText(CONFIRM_BUTTON), expectedSelector);
}
