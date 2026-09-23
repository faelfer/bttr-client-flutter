import fillInput from './fillInput.js';
import inputElement from './inputElement.js';

// Substitui o conteúdo de um campo que já vem preenchido — o perfil chega com
// nome e e-mail da API, e os formulários de edição chegam com os dados do
// registro. Diferente do fillInput, valor vazio aqui significa "apagar o que
// está no campo", que é o cenário de validação de campo obrigatório.
export default async function replaceInput(identifier, value) {
  if (value === undefined || value === '') {
    const field = await inputElement(identifier);
    await field.click();
    await field.clearValue();
    return;
  }

  await fillInput(identifier, value);
}
