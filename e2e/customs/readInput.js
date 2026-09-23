import inputElement from './inputElement.js';
import { isAndroid } from '../preflight/deviceEnvironment.js';

// O conteúdo de um campo chega por atributos diferentes: no Android ele é o
// texto do nó, no iOS é o value do elemento. Campo vazio no iOS devolve o
// placeholder ou nada, e o `?? ''` mantém o retorno sempre textual para quem
// compara.
export default async function readInput(identifier) {
  const field = await inputElement(identifier);

  return isAndroid() ? await field.getText() : ((await field.getValue()) ?? '');
}
