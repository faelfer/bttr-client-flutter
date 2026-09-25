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

function configuredBudgets() {
  return {
    buildMs: Number(process.env.PERF_P95_BUILD_MS ?? 50),
    rasterMs: Number(process.env.PERF_P95_RASTER_MS ?? 250),
    totalMs: Number(process.env.PERF_P95_TOTAL_MS ?? 400),
  };
}

export function assertFrameBudget(summary, budgets = configuredBudgets()) {
  // Numeric input remains useful to callers that intentionally apply one
  // threshold to every metric (and keeps this helper backwards compatible).
  const limits = typeof budgets === 'number'
    ? { buildMs: budgets, rasterMs: budgets, totalMs: budgets }
    : budgets;
  for (const [name, value] of Object.entries(limits)) {
    assert(Number.isFinite(value) && value > 0, `Limite ${name} inválido`);
  }
  assert(summary.p95BuildMs <= limits.buildMs,
    `p95 build ${summary.p95BuildMs}ms > ${limits.buildMs}ms`);
  assert(summary.p95RasterMs <= limits.rasterMs,
    `p95 raster ${summary.p95RasterMs}ms > ${limits.rasterMs}ms`);
  assert(summary.p95TotalMs <= limits.totalMs,
    `p95 total ${summary.p95TotalMs}ms > ${limits.totalMs}ms`);
}
