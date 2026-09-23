import byIdentifier from './byIdentifier.js';
import scrollToElement from './scrollToElement.js';
import { isAndroid } from '../preflight/deviceEnvironment.js';

// O identificador do campo pertence ao widget Semantics que envolve o
// TextFormField, e não ao campo em si. No Android isso não muda nada: o nó
// anunciado é o campo editável, e ele aceita texto. No iOS o Semantics vira um
// XCUIElementTypeOther, um contêiner: limpar não faz efeito nenhum e digitar
// acrescentaria ao valor que já estava lá — foi assim que a edição de perfil
// saiu com o nome antigo grudado no novo.
//
// Por isso o iOS desce até o campo de verdade que está dentro do contêiner. O
// campo de senha é de um tipo próprio (SecureTextField), então os dois entram na
// busca.
const IOS_FIELD_TYPES = ['XCUIElementTypeTextField', 'XCUIElementTypeSecureTextField'];

export default async function inputElement(identifier) {
  const element = await scrollToElement(byIdentifier(identifier));

  if (isAndroid()) {
    return element;
  }

  for (const type of IOS_FIELD_TYPES) {
    const field = await element.$(`.//${type}`);

    if (await field.isExisting()) {
      return field;
    }
  }

  return element;
}
