import assert from 'node:assert/strict';
import byIdentifier from '../customs/byIdentifier.js';
import byText from '../customs/byText.js';
import checkElementScreen from '../customs/checkElementScreen.js';
import checkMessageScreen, { messageSelector } from '../customs/checkMessageScreen.js';
import checkNoElementScreen from '../customs/checkNoElementScreen.js';
import checkTextScreen from '../customs/checkTextScreen.js';
import shotScreen from '../customs/shotScreen.js';
import signInScenario from '../scenarios/signInScenario.js';
import timeCreateScenario from '../scenarios/timeCreateScenario.js';
import timeDeleteScenario from '../scenarios/timeDeleteScenario.js';
import timeFactory from '../factories/timeFactory.js';
import timeUpdateScenario from '../scenarios/timeUpdateScenario.js';
import toTab from '../customs/toTab.js';
import userFactory from '../factories/userFactory.js';
import { recordedBody, recordedRequests } from '../customs/requestMockApi.js';

// O registro de tempo depende de duas coisas do aplicativo que a tela não
// mostra: a habilidade escolhida no menu vira um skill_id no corpo, e a edição
// preserva esse skill_id mesmo quando só os minutos mudam. Nenhuma das duas
// aparece no texto da tela, e as duas são o que a conferência de payload cobre.
//
// A data do registro não entra em nada disso de propósito: ela é do servidor, e
// o aplicativo não a envia nem na criação nem na edição.
describe('Registros de tempo', () => {
  beforeEach(async () => {
    await signInScenario(userFactory(false), byIdentifier('bttr.skills.new'));
    await toTab('Histórico', 'Histórico de tempo');
  });

  it('deve registrar um tempo e voltar ao histórico atualizado', async () => {
    const time = timeFactory(false, 'created');

    await shotScreen.capture('time_list_initial');
    await timeCreateScenario(time, messageSelector('tempo foi criado com sucesso'));
    await checkMessageScreen('tempo foi criado com sucesso', 'time_create_success');

    assert.deepEqual(await recordedBody('/times/create_time'), {
      skill_id: time.skill.id,
      minutes: time.minutes,
    });

    await checkNoElementScreen('bttr.times.create');
    await checkElementScreen('bttr.times.new');
    await checkTextScreen('Suas práticas · 2');
  });

  it('deve alterar um registro preservando a habilidade escolhida', async () => {
    const time = timeFactory(false);
    const timeUpdated = timeFactory(false, 'baseUpdated');

    await timeUpdateScenario(
      time,
      timeUpdated.minutes,
      messageSelector('tempo alterado com sucesso'),
    );
    await checkMessageScreen('tempo alterado com sucesso', 'time_update_success');

    assert.deepEqual(
      await recordedBody(`/times/update_time_by_id/${time.id}`, 'PUT'),
      { skill_id: time.skill.id, minutes: timeUpdated.minutes },
    );

    await checkTextScreen(`${timeUpdated.minutes}min`);
  });

  it('deve excluir um registro após a confirmação', async () => {
    const time = timeFactory(false);

    await timeDeleteScenario(time, messageSelector('tempo excluido com sucesso'));
    await checkMessageScreen('tempo excluido com sucesso', 'time_delete_success');

    assert.equal(
      (await recordedRequests(`/times/delete_time_by_id/${time.id}`, 'DELETE')).length,
      1,
    );

    await checkTextScreen('Seu tempo conta uma história.');
    await shotScreen.capture('time_list_empty');
  });

  it('deve mostrar mensagem de erro ao registrar tempo fora da faixa de minutos', async () => {
    const time = timeFactory(false, 'created');

    await timeCreateScenario(
      { ...time, minutes: 0 },
      byText('Informe minutos inteiros entre 1 e 1440.'),
    );
    await shotScreen.capture('time_create_invalid_minutes');

    assert.equal((await recordedRequests('/times/create_time')).length, 0);
  });
});
