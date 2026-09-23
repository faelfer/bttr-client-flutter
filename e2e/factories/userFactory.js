import { randomInt } from 'node:crypto';
import defaultUser from '../mocks/default_user.json' with { type: 'json' };
import duplicateUser from '../mocks/default_user_duplicate.json' with { type: 'json' };
import invalidUser from '../mocks/default_user_invalid.json' with { type: 'json' };

// O usuário registrado do ambiente é o de e2e/mocks/default_user.json: é ele que
// autentica em todos os specs, e é ele que o mock devolve na leitura de perfil.
// Os outros dois existem porque o mock reconhece dois endereços por regra
// própria — "invalid@example.com" recusa o acesso com 401 e
// "duplicate@example.com" recusa o cadastro com 409 —, e um teste de caminho
// negativo precisa exatamente desses.
//
// O usuário novo (o padrão, isGenerateNew) serve ao cadastro de sucesso, que
// exige um endereço inédito a cada execução. Ele é gerado sem biblioteca de
// dados falsos: o único campo que precisa ser realmente único é o e-mail, e
// trazer uma dependência para isso custaria mais do que resolve.
const USERS_DEFAULT = {
  default: defaultUser,
  invalid: invalidUser,
  duplicate: duplicateUser,
};

/**
 * @param {boolean} isGenerateNew true devolve um usuário inédito; false devolve
 * a massa do ambiente
 * @param {'default'|'invalid'|'duplicate'} userKind massa do ambiente escolhida
 */
export default function userFactory(isGenerateNew = true, userKind = 'default') {
  if (isGenerateNew) {
    const singleKey = randomInt(100000, 1000000);

    return {
      username: `usuario.e2e.${singleKey}`,
      email: `usuario.e2e.${singleKey}@bttr.local`,
      password: defaultUser.password,
      newPassword: defaultUser.newPassword,
    };
  }

  const userDefault = USERS_DEFAULT[userKind];

  if (userDefault === undefined) {
    throw new Error(`userFactory | sem mock para o usuário: ${userKind}`);
  }

  return { ...userDefault };
}
