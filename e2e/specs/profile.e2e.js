import assert from 'node:assert/strict';
import byIdentifier from '../customs/byIdentifier.js';
import byText from '../customs/byText.js';
import checkElementScreen from '../customs/checkElementScreen.js';
import checkMessageScreen, { messageSelector } from '../customs/checkMessageScreen.js';
import profileDeleteScenario from '../scenarios/profileDeleteScenario.js';
import profileUpdateScenario from '../scenarios/profileUpdateScenario.js';
import readInput from '../customs/readInput.js';
import redefinePasswordScenario from '../scenarios/redefinePasswordScenario.js';
import shotScreen from '../customs/shotScreen.js';
import signInScenario from '../scenarios/signInScenario.js';
import toTab from '../customs/toTab.js';
import userFactory from '../factories/userFactory.js';
import { recordedBody, recordedRequests } from '../customs/requestMockApi.js';

// A conta é a parte do aplicativo em que errar o contrato é mais caro: a
// alteração de perfil e a troca de senha enviam o que o usuário digitou, e a
// exclusão apaga tudo. Por isso cada teste aqui confere o corpo que saiu, e o
// que não deveria sair é conferido pela ausência de requisição.
//
// A troca de senha com confirmação divergente é o caso que justifica essa
// segunda metade: o aplicativo recusa localmente, antes de chamar o servidor, e
// sem conferir a ausência da chamada o teste não distinguiria a recusa local de
// uma recusa do servidor.
describe('Conta do usuário', () => {
  beforeEach(async () => {
    await signInScenario(userFactory(false), byIdentifier('bttr.skills.new'));
    await toTab('Meu perfil', 'Informações pessoais');
  });

  it('deve exibir os dados da conta autenticada', async () => {
    const user = userFactory(false);

    assert.equal(await readInput('bttr.profile.username'), user.username);
    assert.equal(await readInput('bttr.profile.email'), user.email);
    await shotScreen.capture('profile_initial');
  });

  it('deve salvar as alterações do perfil', async () => {
    const user = userFactory();

    await profileUpdateScenario(user, messageSelector('perfil alterado com sucesso'));
    await checkMessageScreen('perfil alterado com sucesso', 'profile_update_success');

    assert.deepEqual(await recordedBody('/users/profile', 'PATCH'), {
      username: user.username,
      email: user.email,
    });
  });

  it('deve mostrar mensagem de erro ao salvar o perfil com o campo e-mail inválido', async () => {
    const user = userFactory();

    await profileUpdateScenario(
      { ...user, email: 'usuario@' },
      byText('Informe um e-mail válido.'),
    );
    await shotScreen.capture('profile_invalid_email');

    assert.equal((await recordedRequests('/users/profile', 'PATCH')).length, 0);
  });

  it('deve alterar a senha da conta', async () => {
    const user = userFactory(false);

    await redefinePasswordScenario(
      {
        current: user.password,
        next: user.newPassword,
        confirmation: user.newPassword,
      },
      messageSelector('senha alterada com sucesso'),
    );
    await checkMessageScreen('senha alterada com sucesso', 'password_update_success');

    assert.deepEqual(await recordedBody('/users/redefine_password'), {
      password: user.password,
      new_password: user.newPassword,
    });
  });

  it('deve recusar a troca de senha quando a confirmação não coincide', async () => {
    const user = userFactory(false);

    await redefinePasswordScenario(
      {
        current: user.password,
        next: user.newPassword,
        confirmation: `${user.newPassword}x`,
      },
      byText('As senhas não coincidem.'),
    );
    await shotScreen.capture('password_mismatch');

    assert.equal((await recordedRequests('/users/redefine_password')).length, 0);
  });

  it('deve excluir a conta e voltar ao acesso', async () => {
    await profileDeleteScenario(byIdentifier('bttr.auth.email'));

    assert.equal((await recordedRequests('/users/profile', 'DELETE')).length, 1);

    await checkElementScreen('bttr.auth.email');
    await shotScreen.capture('profile_deleted');
  });
});
