import byIdentifier from '../customs/byIdentifier.js';
import byText from '../customs/byText.js';
import tapUntil from '../customs/tapUntil.js';

// Abre o formulário de edição de um registro a partir do cartão dele no
// histórico. Como no cartão de habilidade, o botão de editar não tem
// identificador: o que o distingue é a descrição de acessibilidade, montada com
// o nome da habilidade do registro.
//
// O desfecho esperado é o campo de minutos: a edição busca o registro e a lista
// de habilidades antes de desenhar o formulário.
export default async function timeOpenScenario(time) {
  await tapUntil(
    byText(`Editar registro de ${time.skill.name}`),
    byIdentifier('bttr.times.minutes'),
  );
}
