import { isAndroid } from '../preflight/deviceEnvironment.js';

// O aplicativo é Flutter: os controles não são views nativas, são pintados em
// uma tela só e expostos à automação pela árvore de acessibilidade. O que dá um
// seletor estável ali é o `identifier` do widget Semantics, definido no código
// do aplicativo (os "bttr.*" de lib/src/presentation).
//
// Cada plataforma recebe esse identificador em um atributo diferente: no
// Android ele chega como resource-id da AccessibilityNodeInfo, e no iOS como o
// accessibilityIdentifier do XCUIElement — que é o que o atalho "~" do
// WebdriverIO procura. Um seletor único para as duas não existe, e é por isso
// que este custom existe: o resto da suíte fala em identificador, não em XPath.
export default function byIdentifier(identifier) {
  return isAndroid() ? `//*[@resource-id="${identifier}"]` : `~${identifier}`;
}
