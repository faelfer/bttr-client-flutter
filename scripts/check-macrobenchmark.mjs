import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { assertStartupBudget, summarizeStartup } from '../e2e/performance/benchmarkReport.js';

function findReports(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) return findReports(path);
    return entry.name.endsWith('-benchmarkData.json') ? [path] : [];
  });
}

const reports = findReports('build/macrobenchmark/outputs/connected_android_test_additional_output');
if (reports.length !== 1) {
  throw new Error(`Esperado 1 relatório Macrobenchmark, encontrados ${reports.length}: ${reports.join(', ')}`);
}
const summary = summarizeStartup(JSON.parse(readFileSync(reports[0], 'utf8')));
writeFileSync('test-results/performance/startup.json', JSON.stringify(summary, null, 2));
assertStartupBudget(summary);
console.log(`Inicialização mediana: ${summary.startupMedianMs}ms em ${summary.iterations} iterações`);
