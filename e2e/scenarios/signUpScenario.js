import byIdentifier from '../customs/byIdentifier.js';
import fillInput from '../customs/fillInput.js';
import hideKeyboard from '../customs/hideKeyboard.js';
import tapUntil from '../customs/tapUntil.js';

// Tela de cadastro. O desfecho é sempre informado por quem chama: o cadastro que
// passa volta para a tela de acesso, e o que o servidor recusa fica na mesma
// tela com o aviso — são telas diferentes, e esperar a errada gastaria o
// tempo inteiro do tapUntil antes de falhar pelo motivo errado.
export default async function signUpScenario(user, expectedSelector) {
  await fillInput('bttr.auth.username', user.username);
  await fillInput('bttr.auth.email', user.email);
  await fillInput('bttr.auth.password', user.password, { masked: true });
  await hideKeyboard();
  await tapUntil(byIdentifier('bttr.auth.signUp'), expectedSelector);
}
