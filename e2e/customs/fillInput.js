import hideKeyboard from './hideKeyboard.js';
import inputElement from './inputElement.js';
import readInput from './readInput.js';
import { getDriver } from './session.js';
import { isAndroid } from '../preflight/deviceEnvironment.js';

// Preenche um campo rolando até ele antes. Valor vazio significa "não tocar no
// campo", como no projeto de referência: nos cenários de validação o aplicativo
// precisa receber o estado inicial do campo, e o formulário de habilidade já
// abre com a meta diária preenchida com 30.
//
// A digitação é conferida e repetida porque um campo que ainda está entrando na
// tela engole as teclas sem erro: o toque foi aceito, o foco existe, e o valor
// simplesmente não chega. Sem a releitura o teste seguia com o campo vazio e
// falhava depois, na validação do formulário, apontando para a regra em vez de
// para a digitação perdida.
//
// Campo mascarado não pode ser conferido assim: a senha lê de volta como
// pontos, então `masked` desliga a releitura. O que cobre a senha é o desfecho
// do próprio cenário — o acesso que passa ou o alerta que sobe.
const VALUE_TIMEOUT_MS = 10000;
const TYPE_ATTEMPTS = 3;

async function type(identifier, value) {
  // o teclado aberto cobre parte da tela, e o campo seguinte pode estar embaixo
  // dele: fechar antes é o que deixa a rolagem chegar ao campo certo
  await hideKeyboard();
  const field = await inputElement(identifier);

  if (isAndroid()) {
    await field.click();

    if (await field.getText()) {
      await field.clearValue();
      await field.click();
    }

    // o "mobile: type" digita no campo com foco em vez de definir o valor de
    // uma vez: o Flutter só atualiza o controlador do campo a partir dos
    // eventos do teclado, e o setValue direto não chega até ele
    await getDriver().execute('mobile: type', { text: value });
    return;
  }

  await field.click();
  await field.clearValue();
  const current = (await field.getValue()) ?? '';

  // o clearValue do XCUITest não esvazia campo seguro, e um campo que volta
  // preenchido receberia o valor novo emendado no antigo
  if (current) {
    await field.addValue('\b'.repeat(current.length));
  }

  await field.addValue(value);
}

export default async function fillInput(identifier, value, { masked = false } = {}) {
  if (value === undefined || value === '') {
    return;
  }

  for (let attempt = 1; attempt <= TYPE_ATTEMPTS; attempt += 1) {
    await type(identifier, value);

    if (masked) {
      return;
    }

    try {
      await getDriver().waitUntil(
        async () => (await readInput(identifier)) === value,
        {
          timeout: VALUE_TIMEOUT_MS,
          timeoutMsg:
            `fillInput | o campo ${identifier} não recebeu o valor "${value}" ` +
            `em ${TYPE_ATTEMPTS} tentativas`,
        },
      );

      return;
    } catch (error) {
      if (attempt === TYPE_ATTEMPTS) {
        throw error;
      }

      console.log(
        `fillInput | digitação perdida em ${identifier}, tentativa ${attempt}`,
      );
    }
  }
}
