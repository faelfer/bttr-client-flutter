import assert from 'node:assert/strict';
import byIdentifier from '../customs/byIdentifier.js';
import byText from '../customs/byText.js';
import checkElementScreen from '../customs/checkElementScreen.js';
import checkMessageScreen, { messageSelector } from '../customs/checkMessageScreen.js';
import shotScreen from '../customs/shotScreen.js';
import signUpScenario from '../scenarios/signUpScenario.js';
import tapUntil from '../customs/tapUntil.js';
import userFactory from '../factories/userFactory.js';
import { recordedBody, recordedRequests } from '../customs/requestMockApi.js';

// O cadastro de sucesso usa um usuário inédito a cada execução. Ele não é
// exigência do mock, que aceita qualquer endereço — é o que mantém o spec
// honesto: um endereço fixo passaria mesmo se o aplicativo deixasse de enviar o
// que digitou, porque a resposta do mock é a mesma de qualquer jeito.
//
// A recusa por e-mail já cadastrado é regra própria do mock, ligada ao endereço
// de e2e/mocks/default_user_duplicate.json.
describe('Tela de cadastro', () => {
  beforeEach(async () => {
    await tapUntil(
      byText('Ainda não tem conta? Cadastre-se'),
      byIdentifier('bttr.auth.username'),
    );
  });

  it('deve cadastrar um novo usuário e voltar ao acesso', async () => {
    const user = userFactory();

    await shotScreen.capture('sign_up_initial');
    await signUpScenario(user, messageSelector('usuário foi criado com sucesso'));
    await checkMessageScreen('usuário foi criado com sucesso', 'sign_up_success');

    assert.deepEqual(await recordedBody('/users/sign_up'), {
      username: user.username,
      email: user.email,
      password: user.password,
    });

    await checkElementScreen('bttr.auth.signIn');
  });

  it('deve mostrar mensagem de erro ao cadastrar com e-mail já existente', async () => {
    const user = userFactory(false, 'duplicate');

    await signUpScenario(user, messageSelector('e-mail já cadastrado'));
    await checkMessageScreen('e-mail já cadastrado', 'sign_up_duplicate');

    assert.equal((await recordedRequests('/users/sign_up')).length, 1);
  });

  it('deve mostrar mensagem de erro ao cadastrar com senha fora das regras', async () => {
    const user = userFactory();

    await signUpScenario(
      { ...user, password: 'senha' },
      byText('Use de 4 a 128 caracteres, com maiúscula, minúscula, número e símbolo.'),
    );
    await shotScreen.capture('sign_up_weak_password');

    assert.equal((await recordedRequests('/users/sign_up')).length, 0);
  });

  it('deve mostrar mensagem de erro ao cadastrar com o campo nome vazio', async () => {
    const user = userFactory();

    await signUpScenario(
      { ...user, username: '' },
      byText('Informe um nome entre 2 e 100 caracteres.'),
    );
    await shotScreen.capture('sign_up_empty_username');

    assert.equal((await recordedRequests('/users/sign_up')).length, 0);
  });
});
