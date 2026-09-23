import byText from '../customs/byText.js';
import tapUntil from '../customs/tapUntil.js';

// Abre as estatísticas a partir do cartão da habilidade. Diferente do botão de
// editar, o link de estatísticas tem o mesmo rótulo em todos os cartões: ele não
// distingue uma habilidade da outra.
//
// Por isso este cenário só serve quando há uma habilidade na lista — o estado
// inicial do cenário do mock. Com mais de uma, o toque cairia no primeiro
// cartão, que pode não ser o pedido, e o teste passaria conferindo a habilidade
// errada. Conferir qual habilidade abriu é do spec, pelo título da tela.
//
// O desfecho esperado é um texto que só existe nas estatísticas, e não o nome da
// habilidade: o nome já está na tela antes do toque, no cartão de onde o toque
// saiu, e o tapUntil o encontraria mesmo se a navegação não tivesse acontecido.
const STATISTICS_LINK = 'Ver estatísticas';
const STATISTICS_SCREEN = 'Meta mensal';

export default async function statisticsOpenScenario() {
  await tapUntil(byText(STATISTICS_LINK), byText(STATISTICS_SCREEN));
}
