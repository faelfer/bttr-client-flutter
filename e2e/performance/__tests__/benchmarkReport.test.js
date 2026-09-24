import assert from 'node:assert/strict';
import { assertStartupBudget, summarizeStartup } from '../benchmarkReport.js';

describe('Relatório de inicialização', () => {
  it('extrai a mediana e valida o limite', () => {
    const summary = summarizeStartup({ benchmarks: [{
      name: 'coldStartup', repeatIterations: 5,
      metrics: { timeToInitialDisplayMs: { median: 420 } },
    }] });
    assert.equal(summary.startupMedianMs, 420);
    assertStartupBudget(summary, 500);
    assert.throws(() => assertStartupBudget(summary, 400), /Inicialização mediana/);
  });

  it('rejeita relatório sem benchmark esperado', () => {
    assert.throws(() => summarizeStartup({ benchmarks: [] }), /sem mediana/);
  });

  it('rejeita execução parcial', () => {
    assert.throws(() => summarizeStartup({ benchmarks: [{
      name: 'coldStartup', repeatIterations: 1,
      metrics: { timeToInitialDisplayMs: { median: 420 } },
    }] }), /menos de 5 iterações/);
  });
});
