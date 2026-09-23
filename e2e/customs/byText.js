import { isAndroid } from '../preflight/deviceEnvironment.js';

// Nem tudo o que a suíte precisa tocar ou conferir tem identificador: títulos de
// tela, rótulos de aba, itens de lista vindos da API e os botões dos diálogos de
// confirmação são texto, e dar identificador a cada um deles encheria o
// aplicativo de marcação de teste. Para esses o seletor é o texto exibido, como
// no projeto de referência.
//
// O Flutter publica o texto de um widget ora como texto do nó, ora como
// descrição de conteúdo, dependendo de o nó ser ou não um campo editável — e
// quem decide isso é o motor, não o aplicativo. Conferir os dois atributos evita
// que a conferência acuse ausência de um texto que está na tela.
//
// No iOS o par equivalente é name/label, e o value entra junto porque o conteúdo
// de um campo preenchido chega por ali.
export default function byText(text) {
  return isAndroid()
    ? `//*[@text="${text}" or @content-desc="${text}"]`
    : `//*[@name="${text}" or @label="${text}" or @value="${text}"]`;
}
