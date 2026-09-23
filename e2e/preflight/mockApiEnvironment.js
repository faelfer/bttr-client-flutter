import requestMockApi, { readMockApiUrl, resetMockApi } from '../customs/requestMockApi.js';

// A suíte reinicia cenários e apaga o histórico de requisições pela API de
// administração do WireMock. Isso é destrutivo: apontada para um servidor que
// não seja o mock local desta execução, ela apagaria o estado de quem estiver
// usando aquele servidor.
//
// A guarda é fail-closed, como a do projeto de referência: o endereço precisa
// ser local e precisa responder como o mock do bttr-server. Qualquer sinal
// ausente aborta antes de a sessão abrir.
const LOOPBACK_HOSTS = ['localhost', '127.0.0.1', '::1', '[::1]'];
const MOCK_SERVICE = 'bttr-api-mock';

function abort(message) {
  throw new Error(`e2e abortado: ${message}`);
}

function isPrivateIPv4(hostname) {
  const octets = hostname.split('.');

  if (octets.length !== 4 || octets.some((octet) => !/^\d{1,3}$/.test(octet))) {
    return false;
  }

  const [first, second] = octets.map(Number);

  if (octets.some((octet) => Number(octet) > 255)) {
    return false;
  }

  // RFC1918
  return (
    first === 10 ||
    (first === 172 && second >= 16 && second <= 31) ||
    (first === 192 && second === 168)
  );
}

export function isLocalHostname(hostname) {
  const normalized = hostname.toLowerCase();

  return LOOPBACK_HOSTS.includes(normalized) || isPrivateIPv4(normalized);
}

export async function assertMockApiEnvironment() {
  const mockApiUrl = readMockApiUrl();

  if (!isLocalHostname(mockApiUrl.hostname)) {
    abort(
      `BTTR_MOCK_API_URL aponta para um host que não é local: ${mockApiUrl.origin}.\n` +
        'A suíte reinicia cenários e apaga o histórico de requisições do servidor: ' +
        'ela só pode rodar contra o mock local do bttr-server.',
    );
  }

  let health;

  try {
    health = await requestMockApi('/mock/health');
  } catch (error) {
    abort(
      `o mock não respondeu em ${mockApiUrl.origin} (${error.message}).\n` +
        "Suba-o com 'docker compose -f compose.e2e.yaml up -d --wait mock-api'.",
    );
  }

  if (health?.service !== MOCK_SERVICE) {
    abort(
      `${mockApiUrl.origin} respondeu, mas não é o mock do bttr-server ` +
        `(service: ${JSON.stringify(health?.service)}, esperado ${JSON.stringify(MOCK_SERVICE)}).`,
    );
  }

  await resetMockApi();
}

// O mock respondendo não prova que o aplicativo fala com ele: a URL da API é
// compilada dentro do pacote, e um APK antigo no dispositivo continua apontando
// para onde apontava quando foi compilado. Nesse caso todo teste falha no
// primeiro acesso, com uma mensagem de conexão que manda procurar o defeito na
// tela.
//
// A conferência é indireta de propósito — ler a URL de dentro do aplicativo
// exigiria instrumentá-lo —, e roda depois do primeiro acesso do primeiro spec:
// se o mock registrou a requisição de acesso, o pacote instalado é o que foi
// compilado para esta execução.
export async function assertAppReachedMockApi() {
  const response = await requestMockApi('/__admin/requests/find', {
    method: 'POST',
    body: { method: 'POST', urlPath: '/users/sign_in' },
  });

  if (response.requests.length === 0) {
    abort(
      `o aplicativo instalado não chamou ${readMockApiUrl().origin}.\n` +
        'O pacote no dispositivo foi compilado com outra URL de API: recompile com ' +
        "'scripts/appium-e2e-ci.sh <plataforma>', que passa a URL do mock no --dart-define.",
    );
  }
}
