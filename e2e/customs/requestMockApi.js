// Chamada direta ao WireMock que faz as vezes da API do bttr-server. Ela não
// substitui interação de tela: serve para o que é de outro sistema — reiniciar
// o cenário entre um teste e outro e conferir o que o backend recebeu.
//
// Conferir a requisição importa porque a tela sozinha não prova o contrato. O
// aplicativo mostra "habilidade foi criada com sucesso" a partir da resposta do
// mock, que é a mesma para qualquer corpo enviado: sem olhar o que saiu do
// dispositivo, um payload com o campo errado passaria despercebido.
//
// O processo do mocha roda na máquina, e não no dispositivo, então a URL usada
// aqui é a alcançável pela máquina. Ela é diferente da que o aplicativo usa: o
// emulador Android enxerga a máquina como 10.0.2.2, e é esse endereço que o
// scripts/appium-e2e-ci.sh compila dentro do APK.
const MOCK_HOST_ALIASES = {
  '10.0.2.2': '127.0.0.1', // emulador do Android Studio
  '10.0.3.2': '127.0.0.1', // Genymotion
};

const REQUEST_TIMEOUT_MS = 30000;

export function readMockApiUrl() {
  const url = new URL(process.env.BTTR_MOCK_API_URL ?? 'http://127.0.0.1:18080');
  const alias = MOCK_HOST_ALIASES[url.hostname];

  if (alias) {
    url.hostname = alias;
  }

  return url;
}

export default async function requestMockApi(path, { method = 'GET', body } = {}) {
  const requestUrl = new URL(path, readMockApiUrl());
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  try {
    const response = await fetch(requestUrl, {
      method,
      headers: body ? { 'Content-Type': 'application/json' } : {},
      body: body ? JSON.stringify(body) : undefined,
      signal: controller.signal,
    });
    const text = await response.text();

    if (!response.ok) {
      throw new Error(
        `requestMockApi | ${method} ${path} respondeu ${response.status}: ${text}`,
      );
    }

    return text === '' ? undefined : JSON.parse(text);
  } finally {
    clearTimeout(timeout);
  }
}

// Os mapeamentos de habilidade e de tempo são cenários com estado: criar uma
// habilidade leva o cenário de "Started" para "SKILL_CREATED", e a listagem
// passa a devolver outro conteúdo. Sem reiniciar, o segundo teste receberia a
// massa que o primeiro deixou — e o mapeamento de criação fora de sequência
// responde justamente "o cenário precisa ser reiniciado".
//
// O histórico de requisições é apagado junto porque é ele que as conferências de
// payload leem: uma requisição herdada do teste anterior faria a contagem passar
// sem o aplicativo ter enviado nada.
export async function resetMockApi() {
  await requestMockApi('/__admin/mappings/reset', { method: 'POST' });
  await requestMockApi('/__admin/scenarios/reset', { method: 'POST' });
  await requestMockApi('/__admin/requests', { method: 'DELETE' });
}

/**
 * Requisições que o mock recebeu no endpoint indicado, na ordem em que
 * chegaram.
 * @param {string} urlPath caminho exato, como '/skills/create_skill'
 * @param {string} method método HTTP conferido junto do caminho
 */
export async function recordedRequests(urlPath, method = 'POST') {
  const response = await requestMockApi('/__admin/requests/find', {
    method: 'POST',
    body: { method, urlPath },
  });

  return response.requests;
}

/**
 * Corpo JSON da única requisição esperada no endpoint. Falha quando houve mais
 * de uma: a repetição é o sintoma de toque duplicado, e deixá-la passar
 * esconderia justamente o defeito que o tapUntil existe para evitar.
 */
export async function recordedBody(urlPath, method = 'POST') {
  const requests = await recordedRequests(urlPath, method);

  if (requests.length !== 1) {
    throw new Error(
      `recordedBody | ${method} ${urlPath} recebeu ${requests.length} requisições, esperava 1`,
    );
  }

  return JSON.parse(requests[0].body);
}
