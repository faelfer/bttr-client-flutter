import byIdentifier from '../customs/byIdentifier.js';
import byText from '../customs/byText.js';
import hideKeyboard from '../customs/hideKeyboard.js';
import fillInput from '../customs/fillInput.js';
import tapUntil from '../customs/tapUntil.js';

// Troca de senha, a partir do perfil. Os três campos são mascarados, então
// nenhum deles pode ser conferido pela releitura do fillInput: o que diz se a
// digitação chegou é o desfecho do envio.
//
// A confirmação é parâmetro separado da senha nova porque a divergência entre as
// duas é um caso de teste: o aplicativo recusa localmente, sem chamar o
// servidor, e é justamente essa ausência de chamada que o spec confere.
const PASSWORD_LINK = 'Alterar senha';

export default async function redefinePasswordScenario(
  { current, next, confirmation },
  expectedSelector,
) {
  await tapUntil(byText(PASSWORD_LINK), byIdentifier('bttr.password.current'));
  await fillInput('bttr.password.current', current, { masked: true });
  await fillInput('bttr.password.next', next, { masked: true });
  await fillInput('bttr.password.confirmation', confirmation, { masked: true });
  await hideKeyboard();
  await tapUntil(byIdentifier('bttr.password.save'), expectedSelector);
}
