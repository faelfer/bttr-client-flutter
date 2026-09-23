import byIdentifier from '../customs/byIdentifier.js';
import hideKeyboard from '../customs/hideKeyboard.js';
import replaceInput from '../customs/replaceInput.js';
import tapUntil from '../customs/tapUntil.js';
import timeOpenScenario from './timeOpenScenario.js';

// Edição de um registro existente. A habilidade não é trocada: o formulário
// chega com ela selecionada, e a alteração do fluxo é o tempo dedicado — que é
// também o que o payload precisa levar junto do skill_id preservado.
export default async function timeUpdateScenario(time, minutes, expectedSelector) {
  await timeOpenScenario(time);
  await replaceInput('bttr.times.minutes', `${minutes}`);
  await hideKeyboard();
  await tapUntil(byIdentifier('bttr.times.save'), expectedSelector);
}
