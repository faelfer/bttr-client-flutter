import assert from 'node:assert/strict';
import byIdentifier from '../customs/byIdentifier.js';
import byText from '../customs/byText.js';
import checkElementScreen from '../customs/checkElementScreen.js';
import checkMessageScreen, { messageSelector } from '../customs/checkMessageScreen.js';
import shotScreen from '../customs/shotScreen.js';
import forgotPasswordScenario from '../scenarios/forgotPasswordScenario.js';
import tapUntil from '../customs/tapUntil.js';
import userFactory from '../factories/userFactory.js';
import { recordedBody, recordedRequests } from '../customs/requestMockApi.js';

// A recuperação não muda nada no aplicativo: ela pede ao servidor o envio do
// link e volta para o acesso. O que este spec confere, então, é o contrato — o
// endereço que saiu no corpo — e a resposta neutra do servidor, que não revela
// se o e-mail existe.
const MESSAGE_SENT = 'enviaremos as instruções';

describe('Tela de recuperação de senha', () => {
  beforeEach(async () => {
    await tapUntil(
      byText('Esqueceu a senha?'),
      byIdentifier('bttr.auth.forgotPassword'),
    );
  });

  it('deve solicitar o link de recuperação e voltar ao acesso', async () => {
    const user = userFactory(false);

    await shotScreen.capture('forgot_password_initial');
    await forgotPasswordScenario(user, messageSelector(MESSAGE_SENT));
    await checkMessageScreen(MESSAGE_SENT, 'forgot_password_success');

    assert.deepEqual(await recordedBody('/users/forgot_password'), {
      email: user.email,
    });

    await checkElementScreen('bttr.auth.signIn');
  });

  // a resposta é a mesma de um endereço cadastrado, de propósito: revelar a
  // diferença diria a quem perguntasse quais e-mails existem na base
  it('deve responder da mesma forma para e-mail não cadastrado', async () => {
    const user = userFactory();

    await forgotPasswordScenario(user, messageSelector(MESSAGE_SENT));
    await checkMessageScreen(MESSAGE_SENT, 'forgot_password_unknown_email');
  });

  it('deve mostrar mensagem de erro ao solicitar com o campo e-mail inválido', async () => {
    await forgotPasswordScenario(
      { email: 'usuario@' },
      byText('Informe um e-mail válido.'),
    );
    await shotScreen.capture('forgot_password_invalid_email');

    assert.equal((await recordedRequests('/users/forgot_password')).length, 0);
  });
});
