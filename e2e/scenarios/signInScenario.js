import byIdentifier from '../customs/byIdentifier.js';
import fillInput from '../customs/fillInput.js';
import hideKeyboard from '../customs/hideKeyboard.js';
import tapUntil from '../customs/tapUntil.js';

// Tela de acesso. O botão é buscado pelo identificador, e não pelo rótulo,
// porque "Entrar" aparece mais de uma vez na tela — o rótulo do botão e o texto
// do link de cadastro compartilham a palavra.
//
// A senha é preenchida como mascarada: o campo lê de volta como pontos, então a
// conferência de digitação do fillInput não teria como comparar. O que cobre a
// senha é o desfecho do próprio acesso.
export default async function signInScenario(user, expectedSelector) {
  await fillInput('bttr.auth.email', user.email);
  await fillInput('bttr.auth.password', user.password, { masked: true });
  await hideKeyboard();
  await tapUntil(byIdentifier('bttr.auth.signIn'), expectedSelector);
}
