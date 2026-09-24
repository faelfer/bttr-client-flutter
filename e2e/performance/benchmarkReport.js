import assert from 'node:assert/strict';

export function summarizeStartup(report) {
  const benchmark = report.benchmarks?.find((entry) => entry.name === 'coldStartup');
  const medianMs = benchmark?.metrics?.timeToInitialDisplayMs?.median;
  assert(Number.isFinite(medianMs) && medianMs > 0, 'Macrobenchmark sem mediana de inicialização');
  assert(benchmark.repeatIterations >= 5, 'Macrobenchmark executou menos de 5 iterações');
  return { startupMedianMs: medianMs, iterations: benchmark.repeatIterations };
}

export function assertStartupBudget(summary, limitMs = Number(process.env.PERF_STARTUP_MEDIAN_MS ?? 10000)) {
  assert(Number.isFinite(limitMs) && limitMs > 0, 'PERF_STARTUP_MEDIAN_MS inválido');
  assert(summary.startupMedianMs <= limitMs, `Inicialização mediana ${summary.startupMedianMs}ms > ${limitMs}ms`);
}
