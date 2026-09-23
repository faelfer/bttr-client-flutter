import byIdentifier from '../customs/byIdentifier.js';
import hideKeyboard from '../customs/hideKeyboard.js';
import replaceInput from '../customs/replaceInput.js';
import tapUntil from '../customs/tapUntil.js';

// Alteração dos dados da conta. Os dois campos chegam preenchidos com o que a
// leitura de perfil devolveu, então os dois são substituídos.
export default async function profileUpdateScenario(user, expectedSelector) {
  await replaceInput('bttr.profile.username', user.username);
  await replaceInput('bttr.profile.email', user.email);
  await hideKeyboard();
  await tapUntil(byIdentifier('bttr.profile.save'), expectedSelector);
}
