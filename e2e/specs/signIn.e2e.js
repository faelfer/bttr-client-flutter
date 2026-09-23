import assert from 'node:assert/strict';
import byIdentifier from '../customs/byIdentifier.js';
import byText from '../customs/byText.js';
import checkElementScreen from '../customs/checkElementScreen.js';
import checkMessageScreen, { messageSelector } from '../customs/checkMessageScreen.js';
import checkTextScreen from '../customs/checkTextScreen.js';
import shotScreen from '../customs/shotScreen.js';
import signInScenario from '../scenarios/signInScenario.js';
import signOutScenario from '../scenarios/signOutScenario.js';
import userFactory from '../factories/userFactory.js';
import { recordedBody, recordedRequests } from '../customs/requestMockApi.js';

// O root hook de e2e/preflight/hooks.js já entrega cada teste na tela de acesso
// com o cenário do mock reiniciado, então não há preparação própria aqui.
//
// Os dois caminhos negativos deste spec são de naturezas diferentes, e é por
// isso que os dois existem: a credencial recusada é decisão do servidor, e o
// campo inválido é decisão do aplicativo. Só o segundo pode ser conferido pela
// ausência de requisição — e é essa ausência que prova que a validação é local,
// e não uma resposta do servidor lida como validação.
describe('Tela de acesso', () => {
  it('deve realizar o acesso do usuário e sair da conta', async () => {
    const user = userFactory(false);

    await shotScreen.capture('sign_in_initial');
    await signInScenario(user, byIdentifier('bttr.skills.new'));
    await shotScreen.capture('sign_in_skills');

    assert.deepEqual(await recordedBody('/users/sign_in'), {
      email: user.email,
      password: user.password,
    });

    await signOutScenario();
    await checkElementScreen('bttr.auth.email');
  });

  it('deve mostrar mensagem de erro ao acessar com credenciais recusadas', async () => {
    const user = userFactory(false, 'invalid');

    await signInScenario(user, messageSelector('e-mail ou senha incorretos'));
    await checkMessageScreen('e-mail ou senha incorretos', 'sign_in_denied');

    // a recusa é do servidor: a requisição precisa ter saído
    assert.equal((await recordedRequests('/users/sign_in')).length, 1);
  });

  it('deve mostrar mensagem de erro ao acessar com o campo e-mail inválido', async () => {
    const user = userFactory(false);

    await signInScenario(
      { ...user, email: 'usuario@' },
      byText('Informe um e-mail válido.'),
    );
    await shotScreen.capture('sign_in_invalid_email');

    assert.equal((await recordedRequests('/users/sign_in')).length, 0);
  });

  it('deve mostrar mensagem de erro ao acessar com o campo senha vazio', async () => {
    const user = userFactory(false);

    // senha vazia significa "não tocar no campo" para o fillInput, e o campo
    // nasce vazio: é exatamente o estado que o formulário precisa receber
    await signInScenario(
      { ...user, password: '' },
      byText('Informe sua senha (até 128 caracteres).'),
    );
    await shotScreen.capture('sign_in_empty_password');

    assert.equal((await recordedRequests('/users/sign_in')).length, 0);
  });

  it('deve oferecer os caminhos de cadastro e de recuperação de senha', async () => {
    await checkTextScreen('Ainda não tem conta? Cadastre-se');
    await checkTextScreen('Esqueceu a senha?');
  });
});
