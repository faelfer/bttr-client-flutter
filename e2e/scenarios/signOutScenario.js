import byIdentifier from '../customs/byIdentifier.js';
import tapUntil from '../customs/tapUntil.js';

// A saída fica no cabeçalho da área autenticada, disponível em qualquer aba: não
// é preciso navegar até o perfil antes.
//
// O toque é tapUntil, e não toque simples, porque a tela pode estar carregando
// dados quando ele acontece — a lista de habilidades busca a página ao entrar — e
// o toque perdido nesse intervalo deixaria a sessão aberta sem erro nenhum. O
// teste seguinte só descobriria isso ao não encontrar a tela de acesso.
export default async function signOutScenario() {
  await tapUntil(
    byIdentifier('bttr.auth.signOut'),
    byIdentifier('bttr.auth.email'),
  );
}
