import assert from 'node:assert/strict';
import byIdentifier from '../customs/byIdentifier.js';
import byText from '../customs/byText.js';
import checkElementScreen from '../customs/checkElementScreen.js';
import checkMessageScreen, { messageSelector } from '../customs/checkMessageScreen.js';
import checkNoElementScreen from '../customs/checkNoElementScreen.js';
import checkTextScreen from '../customs/checkTextScreen.js';
import goBack from '../customs/goBack.js';
import shotScreen from '../customs/shotScreen.js';
import signInScenario from '../scenarios/signInScenario.js';
import skillCreateScenario from '../scenarios/skillCreateScenario.js';
import skillDeleteScenario from '../scenarios/skillDeleteScenario.js';
import skillFactory from '../factories/skillFactory.js';
import skillOpenScenario from '../scenarios/skillOpenScenario.js';
import skillUpdateScenario from '../scenarios/skillUpdateScenario.js';
import statisticsOpenScenario from '../scenarios/statisticsOpenScenario.js';
import userFactory from '../factories/userFactory.js';
import { recordedBody, recordedRequests } from '../customs/requestMockApi.js';

// O mock responde pelo estado do cenário, e não pelo corpo que recebe: criar
// qualquer habilidade leva o cenário de "Started" para "SKILL_CREATED", e a
// listagem passa a devolver Kotlin. É por isso que a massa dos caminhos de
// sucesso vem do skillFactory com isGenerateNew falso — o que o teste envia
// precisa ser o que o estado seguinte vai listar de volta, senão a conferência
// da lista falharia com o aplicativo certo.
//
// E é por isso que a conferência de payload não é acessório: a tela mostraria
// "habilidade foi criada com sucesso" mesmo se o aplicativo enviasse o campo
// errado. O que prova o contrato é o corpo que chegou ao servidor.
describe('Habilidades', () => {
  beforeEach(async () => {
    await signInScenario(userFactory(false), byIdentifier('bttr.skills.new'));
  });

  it('deve criar uma habilidade e voltar à lista atualizada', async () => {
    const skill = skillFactory(false, 'created');

    await shotScreen.capture('skill_list_initial');
    await skillCreateScenario(skill, messageSelector('habilidade foi criada com sucesso'));
    await checkMessageScreen('habilidade foi criada com sucesso', 'skill_create_success');

    assert.deepEqual(await recordedBody('/skills/create_skill'), {
      name: skill.name,
      daily: skill.daily,
    });

    // o formulário sair da tela é o que separa "a mutação foi enviada" de "a
    // mutação terminou": a mensagem sobe assim que a resposta chega, e a
    // navegação de volta vem depois
    await checkNoElementScreen('bttr.skills.create');
    await checkElementScreen('bttr.skills.new');
    await checkTextScreen(skill.name);
    await checkTextScreen('Suas habilidades · 2');
  });

  // sair do formulário sem salvar é o caminho que mais se usa e o que menos se
  // testa: no Android ele é o botão voltar do sistema, tratado pelo aplicativo,
  // e no iOS é o link de retorno no alto da tela. A ausência de requisição é o
  // que prova que voltar não é salvar.
  it('deve voltar do formulário para a lista sem salvar', async () => {
    const skill = skillFactory(false);

    await skillOpenScenario(skill);
    await goBack('Minhas habilidades', 'Voltar às habilidades');
    await checkElementScreen('bttr.skills.new');

    assert.equal(
      (await recordedRequests(`/skills/update_skill_by_id/${skill.id}`, 'PUT')).length,
      0,
    );
  });

  it('deve alterar uma habilidade existente', async () => {
    const skill = skillFactory(false);
    const skillUpdated = skillFactory(false, 'baseUpdated');

    await skillUpdateScenario(
      skill,
      skillUpdated,
      messageSelector('habilidade alterada com sucesso'),
    );
    await checkMessageScreen('habilidade alterada com sucesso', 'skill_update_success');

    assert.deepEqual(
      await recordedBody(`/skills/update_skill_by_id/${skill.id}`, 'PUT'),
      { name: skillUpdated.name, daily: skillUpdated.daily },
    );

    await checkTextScreen(skillUpdated.name);
  });

  it('deve excluir uma habilidade após a confirmação', async () => {
    const skill = skillFactory(false);

    await skillDeleteScenario(
      skill,
      messageSelector('habilidade excluida com sucesso'),
    );
    await checkMessageScreen('habilidade excluida com sucesso', 'skill_delete_success');

    assert.equal(
      (await recordedRequests(`/skills/delete_skill_by_id/${skill.id}`, 'DELETE')).length,
      1,
    );

    // a lista vazia tem texto próprio, e é ele que prova que a exclusão chegou
    // à listagem — não basta a mensagem de sucesso
    await checkTextScreen('Sua próxima habilidade começa aqui.');
    await shotScreen.capture('skill_list_empty');
  });

  it('deve abrir as estatísticas da habilidade', async () => {
    const skill = skillFactory(false);

    await statisticsOpenScenario();
    await checkTextScreen(skill.name);
    await checkTextScreen('Meta diária');
    await checkTextScreen('Sua evolução neste mês');
    await shotScreen.capture('skill_statistics');
  });

  it('deve mostrar mensagem de erro ao criar habilidade com meta diária fora da faixa', async () => {
    const skill = { ...skillFactory(), daily: 0 };

    await skillCreateScenario(
      skill,
      byText('Informe minutos inteiros entre 1 e 1440.'),
    );
    await shotScreen.capture('skill_create_invalid_daily');

    assert.equal((await recordedRequests('/skills/create_skill')).length, 0);
  });

  it('deve mostrar mensagem de erro ao criar habilidade com o campo nome vazio', async () => {
    const skill = skillFactory(false, 'created');

    await skillCreateScenario(
      { ...skill, name: '' },
      byText('Informe um nome entre 2 e 120 caracteres.'),
    );
    await shotScreen.capture('skill_create_empty_name');

    assert.equal((await recordedRequests('/skills/create_skill')).length, 0);
  });
});
