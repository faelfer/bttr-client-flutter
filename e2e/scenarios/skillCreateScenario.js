import byIdentifier from '../customs/byIdentifier.js';
import fillInput from '../customs/fillInput.js';
import hideKeyboard from '../customs/hideKeyboard.js';
import replaceInput from '../customs/replaceInput.js';
import tapUntil from '../customs/tapUntil.js';

// Da lista de habilidades até o formulário de criação e o envio.
//
// O nome é preenchido com fillInput e a meta com replaceInput porque os dois
// campos chegam diferentes: o nome vem vazio, e a meta diária já vem com 30
// escrito. Preencher por cima de um valor existente emendaria os dois números.
export default async function skillCreateScenario(skill, expectedSelector) {
  await tapUntil(
    byIdentifier('bttr.skills.new'),
    byIdentifier('bttr.skills.name'),
  );
  await fillInput('bttr.skills.name', skill.name);
  await replaceInput('bttr.skills.daily', `${skill.daily}`);
  await hideKeyboard();
  await tapUntil(byIdentifier('bttr.skills.create'), expectedSelector);
}
