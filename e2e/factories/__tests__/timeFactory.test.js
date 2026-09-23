import assert from 'node:assert/strict';
import timeFactory from '../timeFactory.js';
import baseTime from '../../mocks/default_time.json' with { type: 'json' };
import baseUpdatedTime from '../../mocks/default_time_base_updated.json' with { type: 'json' };
import createdTime from '../../mocks/default_time_created.json' with { type: 'json' };
import createdUpdatedTime from '../../mocks/default_time_created_updated.json' with { type: 'json' };

describe('timeFactory', () => {
  it('devolve o registro de cada estado do cenário do mock', () => {
    assert.deepEqual(timeFactory(false), baseTime);
    assert.deepEqual(timeFactory(false, 'created'), createdTime);
    assert.deepEqual(timeFactory(false, 'createdUpdated'), createdUpdatedTime);
    assert.deepEqual(timeFactory(false, 'baseUpdated'), baseUpdatedTime);
  });

  it('acusa registro sem mock', () => {
    assert.throws(() => timeFactory(false, 'removed'), /sem mock para o tempo/);
  });

  it('gera registro dentro das regras do formulário', () => {
    for (let attempt = 0; attempt < 200; attempt += 1) {
      const timeNew = timeFactory();

      assert.ok(Number.isInteger(timeNew.minutes));
      assert.ok(timeNew.minutes >= 1 && timeNew.minutes <= 1440, `${timeNew.minutes}`);
      assert.equal(timeNew.skill.name, baseTime.skill.name);
    }
  });

  // a habilidade embutida é objeto aninhado: uma cópia rasa deixaria os specs
  // compartilhando o mesmo objeto de habilidade
  it('não compartilha a habilidade embutida entre chamadas', () => {
    timeFactory(false).skill.name = 'alterada';

    assert.equal(timeFactory(false).skill.name, baseTime.skill.name);
  });
});
