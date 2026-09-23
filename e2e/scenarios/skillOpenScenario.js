import byIdentifier from '../customs/byIdentifier.js';
import byText from '../customs/byText.js';
import tapUntil from '../customs/tapUntil.js';

// Abre o formulário de edição de uma habilidade a partir do cartão dela na
// lista. O botão de editar não tem identificador: ele existe uma vez por cartão,
// e um identificador fixo se repetiria em todos. O que o distingue é a descrição
// de acessibilidade, que o aplicativo monta com o nome da habilidade — e o nome
// é único na lista.
//
// O desfecho esperado é o campo de nome já na tela, e não só o formulário: a
// edição carrega a habilidade do servidor antes de desenhar os campos, e seguir
// antes disso digitaria em um campo que ainda vai ser preenchido pela resposta.
export default async function skillOpenScenario(skill) {
  await tapUntil(
    byText(`Editar ${skill.name}`),
    byIdentifier('bttr.skills.name'),
  );
}
