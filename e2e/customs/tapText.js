import byText from './byText.js';
import tapElement from './tapElement.js';

// Toca em um elemento pelo texto exibido. É o que atende o que não tem
// identificador: os botões dos diálogos de confirmação ("Sim, excluir"), os
// links de voltar, os itens da lista de habilidades do formulário de tempo e os
// cartões vindos da API.
export default async function tapText(text) {
  await tapElement(byText(text));
}
