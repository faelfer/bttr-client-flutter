import byIdentifier from './byIdentifier.js';
import byText from './byText.js';
import tapText from './tapText.js';
import tapUntil from './tapUntil.js';

// A escolha da habilidade no formulário de tempo é um menu suspenso: tocar no
// campo abre uma lista sobreposta, e a opção é escolhida pelo texto — o nome da
// habilidade, que vem da API e por isso não tem identificador.
//
// A abertura usa tapUntil porque o formulário carrega as habilidades disponíveis
// ao entrar: tocar no campo antes da resposta chegar não abre nada, e o menu
// fechado não dá erro nenhum. O desfecho esperado é a própria opção estar na
// tela, que é o sinal de que a lista abriu e já tem conteúdo.
export default async function choicePicker(identifier, optionText) {
  await tapUntil(byIdentifier(identifier), byText(optionText));
  await tapText(optionText);
}
