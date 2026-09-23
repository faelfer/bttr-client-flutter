// Os artefatos de um mesmo teste se repetem entre execuções, e entre repetições
// dentro da mesma execução: "skill_create_success" seria gravado por cima toda
// vez. O carimbo separa um do outro e, como ele é crescente, a ordem alfabética
// da pasta e2e/artifacts é também a ordem cronológica.
//
// O formato é curto de propósito: o nome do arquivo já carrega o título do
// teste, que costuma ser longo, e nomes muito grandes ficam truncados nas
// ferramentas que leem o diretório.
export default function createTimeStamp(date = new Date()) {
  const pad = (value) => `${value}`.padStart(2, '0');

  return [
    date.getFullYear(),
    pad(date.getMonth() + 1),
    pad(date.getDate()),
    pad(date.getHours()),
    pad(date.getMinutes()),
    pad(date.getSeconds()),
    `${date.getMilliseconds()}`.padStart(3, '0'),
  ].join('');
}
