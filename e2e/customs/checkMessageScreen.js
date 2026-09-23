import byText from './byText.js';
import shotScreen from './shotScreen.js';
import { getDriver } from './session.js';

// O equivalente ao checkAlertScreen do projeto de referência, para os avisos que
// este aplicativo usa. A diferença muda o custom inteiro: lá o aviso é um
// Alert.alert nativo, que fica na tela até alguém tocar em OK e, enquanto está
// aberto, impede a automação de enxergar qualquer outra coisa. Aqui não há
// diálogo nenhum — o que a operação devolve aparece na própria tela, e em dois
// lugares conforme o desfecho: o sucesso vira um SnackBar, que some sozinho
// depois de alguns segundos, e a falha vira um painel de erro, que fica.
//
// Daí a regra que este custom impõe: a captura acontece antes de qualquer outro
// passo. O SnackBar tem tempo contado, e uma captura tirada depois de mais uma
// navegação pegaria a tela sem a mensagem — justamente a evidência que se queria
// guardar.
//
// A conferência é por conteúdo parcial porque parte das mensagens vem do
// servidor: "habilidade foi criada com sucesso." é resposta do mock, e só as
// validações locais do aplicativo têm texto fixo.
const MESSAGE_TIMEOUT_MS = 30000;

/**
 * Seletor do aviso, exportado porque quem toca precisa dele antes de quem
 * confere: o tapUntil espera um desfecho, e o desfecho de um envio que o
 * servidor recusa é justamente o aviso. Sem isso o cenário teria de esperar uma
 * tela que nunca vem.
 */
export function messageSelector(message) {
  return byText(message).replace(
    /@(\w[\w-]*)="([^"]*)"/g,
    (_, attribute, value) => `contains(@${attribute}, "${value}")`,
  );
}

export default async function checkMessageScreen(message, captureName) {
  const messageChecked = await getDriver().$(messageSelector(message));

  await messageChecked.waitForDisplayed({ timeout: MESSAGE_TIMEOUT_MS });
  await shotScreen.capture(captureName);
}
