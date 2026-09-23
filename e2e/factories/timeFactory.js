import { randomInt } from 'node:crypto';
import baseTime from '../mocks/default_time.json' with { type: 'json' };
import baseUpdatedTime from '../mocks/default_time_base_updated.json' with { type: 'json' };
import createdTime from '../mocks/default_time_created.json' with { type: 'json' };
import createdUpdatedTime from '../mocks/default_time_created_updated.json' with { type: 'json' };

// Mesma regra da fábrica de habilidades: os registros de tempo são o que o
// cenário "Times lifecycle" do mock devolve em cada estado, e a habilidade
// embutida em cada um é a base do outro cenário — o formulário de tempo escolhe
// a habilidade por nome, e é esse nome que precisa bater.
const TIMES_DEFAULT = {
  base: baseTime,
  created: createdTime,
  createdUpdated: createdUpdatedTime,
  baseUpdated: baseUpdatedTime,
};

/**
 * @param {boolean} isGenerateNew true devolve um registro inédito, para os
 * casos de validação
 * @param {'base'|'created'|'createdUpdated'|'baseUpdated'} timeKind estado do
 * cenário do mock
 */
export default function timeFactory(isGenerateNew = true, timeKind = 'base') {
  if (isGenerateNew) {
    return {
      minutes: randomInt(1, 1441),
      skill: { ...baseTime.skill },
    };
  }

  const timeDefault = TIMES_DEFAULT[timeKind];

  if (timeDefault === undefined) {
    throw new Error(`timeFactory | sem mock para o tempo: ${timeKind}`);
  }

  return { ...timeDefault, skill: { ...timeDefault.skill } };
}
