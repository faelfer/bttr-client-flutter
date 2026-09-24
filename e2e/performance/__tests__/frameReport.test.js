import assert from 'node:assert/strict';
import { assertFrameBudget, summarizeFrames } from '../frameReport.js';

describe('Relatório de frames', () => {
  const csv = Array.from({ length: 20 }, (_, index) =>
    `${(index + 1) * 1000},${(index + 1) * 2000},${(index + 1) * 3000}`
  ).join('\n');

  it('calcula p95 e rejeita valores acima do limite', () => {
    const summary = summarizeFrames(csv);
    assert.equal(summary.frameCount, 20);
    assert.equal(summary.p95BuildMs, 19);
    assert.equal(summary.p95RasterMs, 38);
    assert.equal(summary.p95TotalMs, 57);
    assertFrameBudget(summary, 60);
    assert.throws(() => assertFrameBudget(summary, 40), /total/);
    assert.throws(() => assertFrameBudget(summary, 30), /raster/);
  });

  it('rejeita amostra vazia ou incompleta', () => {
    assert.throws(() => summarizeFrames(''), /Apenas 0 frames/);
    assert.throws(() => summarizeFrames('1,2'), /Frame inválido/);
    assert.throws(() => summarizeFrames('1,2,'), /Frame inválido/);
  });
});
