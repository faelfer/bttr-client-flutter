import byIdentifier from '../customs/byIdentifier.js';
import fillInput from '../customs/fillInput.js';
import hideKeyboard from '../customs/hideKeyboard.js';
import tapUntil from '../customs/tapUntil.js';

// Tela de recuperação de senha. Só tem o campo de e-mail: o aplicativo não
// redefine a senha aqui, ele pede ao servidor o envio do link.
export default async function forgotPasswordScenario(user, expectedSelector) {
  await fillInput('bttr.auth.email', user.email);
  await hideKeyboard();
  await tapUntil(byIdentifier('bttr.auth.forgotPassword'), expectedSelector);
}
