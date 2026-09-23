import tapUntil from './tapUntil.js';
import byText from './byText.js';
import { isAndroid } from '../preflight/deviceEnvironment.js';

// A área autenticada usa a barra de abas de baixo: "Habilidades", "Histórico" e
// "Meu perfil". As abas não têm identificador porque o rótulo já é estável — ele
// é texto fixo do aplicativo, não conteúdo vindo da API.
//
// Mas o rótulo não chega puro na árvore de acessibilidade: o Flutter acrescenta
// a posição da aba à descrição, e o que o Android publica é
// "Habilidades\nGuia 1 de 3". Comparar por igualdade não encontra nada — foi o
// que derrubou os specs de tempo e de conta na primeira execução, com uma
// mensagem que parecia dizer que a aba não existia.
//
// Por isso a comparação é por início do rótulo. O sufixo é gerado pelo próprio
// motor e muda com o idioma do aparelho e com a quantidade de abas, então
// fixá-lo aqui só trocaria um acoplamento por outro pior.
//
// O toque é tapUntil, e não toque simples: cada aba carrega dados ao entrar, e o
// toque que cai durante o redesenho da tela anterior é perdido sem erro.
function tabSelector(tabName) {
  const attributes = isAndroid()
    ? ['content-desc', 'text']
    : ['name', 'label'];

  return `//*[${attributes
    .map((attribute) => `starts-with(@${attribute}, "${tabName}")`)
    .join(' or ')}]`;
}

export default async function toTab(tabName, textToCheck) {
  await tapUntil(tabSelector(tabName), byText(textToCheck));
}
