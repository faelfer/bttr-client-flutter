import byIdentifier from '../customs/byIdentifier.js';
import choicePicker from '../customs/choicePicker.js';
import hideKeyboard from '../customs/hideKeyboard.js';
import replaceInput from '../customs/replaceInput.js';
import tapUntil from '../customs/tapUntil.js';

// Do histórico até o formulário de registro e o envio.
//
// A habilidade é escolhida em um menu suspenso pelo nome, e a escolha vem antes
// dos minutos de propósito: o menu se abre por cima da tela, e um campo
// preenchido antes ficaria coberto por ele. A meta de minutos já chega
// preenchida com 25, por isso replaceInput.
export default async function timeCreateScenario(time, expectedSelector) {
  await tapUntil(byIdentifier('bttr.times.new'), byIdentifier('bttr.times.skill'));
  await choicePicker('bttr.times.skill', time.skill.name);
  await replaceInput('bttr.times.minutes', `${time.minutes}`);
  await hideKeyboard();
  await tapUntil(byIdentifier('bttr.times.create'), expectedSelector);
}
