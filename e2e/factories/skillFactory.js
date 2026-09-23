import { randomInt } from 'node:crypto';
import baseSkill from '../mocks/default_skill.json' with { type: 'json' };
import baseUpdatedSkill from '../mocks/default_skill_base_updated.json' with { type: 'json' };
import createdSkill from '../mocks/default_skill_created.json' with { type: 'json' };
import createdUpdatedSkill from '../mocks/default_skill_created_updated.json' with { type: 'json' };

// As habilidades do ambiente não são massa livre: elas são exatamente o que o
// cenário "Skills lifecycle" do mock devolve em cada estado. Quem cria uma
// habilidade precisa enviar o nome e a meta que o estado SKILL_CREATED vai
// listar de volta, senão a conferência da lista falha mesmo com o aplicativo
// certo — o mock responde pelo estado, não pelo corpo recebido.
//
// Por isso a fábrica devolve massa fixa para os caminhos de sucesso, e o
// gerador aleatório fica só para o que não passa pelo cenário: os casos de
// validação, em que o formulário nem chega a enviar.
const SKILLS_DEFAULT = {
  base: baseSkill,
  created: createdSkill,
  createdUpdated: createdUpdatedSkill,
  baseUpdated: baseUpdatedSkill,
};

/**
 * @param {boolean} isGenerateNew true devolve uma habilidade inédita, para os
 * casos de validação
 * @param {'base'|'created'|'createdUpdated'|'baseUpdated'} skillKind estado do
 * cenário do mock
 */
export default function skillFactory(isGenerateNew = true, skillKind = 'base') {
  if (isGenerateNew) {
    return {
      name: `Habilidade E2E ${randomInt(100, 1000)}`,
      daily: randomInt(1, 1441),
    };
  }

  const skillDefault = SKILLS_DEFAULT[skillKind];

  if (skillDefault === undefined) {
    throw new Error(`skillFactory | sem mock para a habilidade: ${skillKind}`);
  }

  return { ...skillDefault };
}
