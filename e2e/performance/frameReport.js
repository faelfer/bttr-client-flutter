import assert from 'node:assert/strict';

function percentile(values, fraction) {
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.ceil(sorted.length * fraction) - 1] / 1000;
}

export function summarizeFrames(csv) {
  const frames = csv.trim().split(/\r?\n/).filter(Boolean).map((line) => {
    const cells = line.split(',');
    assert(cells.length === 3 && cells.every((cell) => cell.trim() !== ''), `Frame inválido: ${line}`);
    const values = cells.map(Number);
    assert(values.every((value) => Number.isFinite(value) && value >= 0));
    return values;
  });
  assert(frames.length >= 10, `Apenas ${frames.length} frames foram registrados`);
  return {
    frameCount: frames.length,
    p95BuildMs: percentile(frames.map((frame) => frame[0]), 0.95),
    p95RasterMs: percentile(frames.map((frame) => frame[1]), 0.95),
    p95TotalMs: percentile(frames.map((frame) => frame[2]), 0.95),
  };
}

export function assertFrameBudget(summary, limitMs = Number(process.env.PERF_P95_FRAME_MS ?? 250)) {
  assert(Number.isFinite(limitMs) && limitMs > 0, 'PERF_P95_FRAME_MS inválido');
  assert(summary.p95BuildMs <= limitMs, `p95 build ${summary.p95BuildMs}ms > ${limitMs}ms`);
  assert(summary.p95RasterMs <= limitMs, `p95 raster ${summary.p95RasterMs}ms > ${limitMs}ms`);
  assert(summary.p95TotalMs <= limitMs, `p95 total ${summary.p95TotalMs}ms > ${limitMs}ms`);
}
