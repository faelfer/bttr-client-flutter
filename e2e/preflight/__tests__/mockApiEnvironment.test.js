import assert from 'node:assert/strict';
import { isLocalHostname, assertMockApiEnvironment } from '../mockApiEnvironment.js';

// A guarda existe para impedir que a suíte reinicie cenários e apague o
// histórico de requisições de um servidor que não seja o mock local desta
// execução. O que esse teste protege é justamente o limite dela: um endereço
// público a mais na lista de aceitos transforma a suíte em uma ferramenta de
// apagar dados de outra pessoa.
describe('mockApiEnvironment', () => {
  it('aceita apenas endereços locais e de rede privada', () => {
    for (const hostname of [
      'localhost',
      '127.0.0.1',
      '::1',
      '10.0.2.2',
      '172.16.0.1',
      '172.31.255.254',
      '192.168.0.10',
    ]) {
      assert.equal(isLocalHostname(hostname), true, hostname);
    }
  });

  it('recusa endereços públicos e endereços fora da faixa privada', () => {
    for (const hostname of [
      'api.bttr.example.com',
      '8.8.8.8',
      '11.0.0.1',
      '172.15.0.1',
      '172.32.0.1',
      '192.169.0.1',
      '999.999.999.999',
    ]) {
      assert.equal(isLocalHostname(hostname), false, hostname);
    }
  });

  it('aborta antes de qualquer chamada quando a URL não é local', async () => {
    const urlBefore = process.env.BTTR_MOCK_API_URL;
    process.env.BTTR_MOCK_API_URL = 'https://bttr-api.example.com';

    try {
      await assert.rejects(assertMockApiEnvironment, /não é local/);
    } finally {
      if (urlBefore === undefined) {
        delete process.env.BTTR_MOCK_API_URL;
      } else {
        process.env.BTTR_MOCK_API_URL = urlBefore;
      }
    }
  });
});
