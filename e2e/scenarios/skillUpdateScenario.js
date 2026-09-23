import byIdentifier from '../customs/byIdentifier.js';
import hideKeyboard from '../customs/hideKeyboard.js';
import replaceInput from '../customs/replaceInput.js';
import skillOpenScenario from './skillOpenScenario.js';
import tapUntil from '../customs/tapUntil.js';

// Edição de uma habilidade existente: os dois campos chegam preenchidos com o
// que o servidor devolveu, então os dois são substituídos.
export default async function skillUpdateScenario(skill, skillUpdated, expectedSelector) {
  await skillOpenScenario(skill);
  await replaceInput('bttr.skills.name', skillUpdated.name);
  await replaceInput('bttr.skills.daily', `${skillUpdated.daily}`);
  await hideKeyboard();
  await tapUntil(byIdentifier('bttr.skills.save'), expectedSelector);
}
