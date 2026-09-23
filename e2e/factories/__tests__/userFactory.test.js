import assert from 'node:assert/strict';
import userFactory from '../userFactory.js';
import defaultUser from '../../mocks/default_user.json' with { type: 'json' };
import duplicateUser from '../../mocks/default_user_duplicate.json' with { type: 'json' };
import invalidUser from '../../mocks/default_user_invalid.json' with { type: 'json' };

describe('userFactory', () => {
  it('devolve o usuário registrado do ambiente', () => {
    assert.deepEqual(userFactory(false), defaultUser);
  });

  it('devolve a massa de cada caminho negativo reconhecido pelo mock', () => {
    assert.deepEqual(userFactory(false, 'invalid'), invalidUser);
    assert.deepEqual(userFactory(false, 'duplicate'), duplicateUser);
  });

  it('acusa usuário sem mock', () => {
    assert.throws(() => userFactory(false, 'guest'), /sem mock para o usuário/);
  });

  it('devolve um e-mail inédito a cada usuário novo', () => {
    const emails = new Set(
      Array.from({ length: 50 }, () => userFactory().email),
    );

    assert.equal(emails.size, 50);
  });

  it('gera usuário novo com os campos que as telas de acesso exigem', () => {
    const userNew = userFactory();

    for (const field of ['username', 'email', 'password']) {
      assert.equal(typeof userNew[field], 'string', field);
      assert.ok(userNew[field].length > 0, field);
    }

    // o cadastro valida a senha como nova: de 4 a 128 caracteres, com
    // maiúscula, minúscula, número e símbolo
    assert.match(userNew.password, /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*\W).{4,128}$/);
    assert.match(userNew.email, /^[^\s@]+@[^\s@]+\.[^\s@]+$/);
  });

  // a massa do ambiente é usada por todos os specs; devolver a referência do
  // JSON deixaria um spec que altera um campo estragar o seguinte
  it('não compartilha o objeto do mock entre chamadas', () => {
    const first = userFactory(false);
    first.email = 'alterado@bttr.local';

    assert.equal(userFactory(false).email, defaultUser.email);
  });
});
