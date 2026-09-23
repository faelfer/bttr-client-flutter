import assert from 'node:assert/strict';
import skillFactory from '../skillFactory.js';
import baseSkill from '../../mocks/default_skill.json' with { type: 'json' };
import baseUpdatedSkill from '../../mocks/default_skill_base_updated.json' with { type: 'json' };
import createdSkill from '../../mocks/default_skill_created.json' with { type: 'json' };
import createdUpdatedSkill from '../../mocks/default_skill_created_updated.json' with { type: 'json' };

describe('skillFactory', () => {
  it('devolve a habilidade de cada estado do cenário do mock', () => {
    assert.deepEqual(skillFactory(false), baseSkill);
    assert.deepEqual(skillFactory(false, 'created'), createdSkill);
    assert.deepEqual(skillFactory(false, 'createdUpdated'), createdUpdatedSkill);
    assert.deepEqual(skillFactory(false, 'baseUpdated'), baseUpdatedSkill);
  });

  it('acusa habilidade sem mock', () => {
    assert.throws(() => skillFactory(false, 'deleted'), /sem mock para a habilidade/);
  });

  // a meta diária é validada pelo aplicativo como inteiro de 1 a 1440, e a
  // habilidade gerada não pode cair fora dessa faixa: o formulário recusaria o
  // envio e o teste falharia por massa, não por defeito
  it('gera habilidade dentro das regras do formulário', () => {
    for (let attempt = 0; attempt < 200; attempt += 1) {
      const skillNew = skillFactory();

      assert.ok(Number.isInteger(skillNew.daily));
      assert.ok(skillNew.daily >= 1 && skillNew.daily <= 1440, `${skillNew.daily}`);
      assert.ok(skillNew.name.length >= 2 && skillNew.name.length <= 120);
    }
  });

  it('não compartilha o objeto do mock entre chamadas', () => {
    skillFactory(false).name = 'alterada';

    assert.equal(skillFactory(false).name, baseSkill.name);
  });
});
