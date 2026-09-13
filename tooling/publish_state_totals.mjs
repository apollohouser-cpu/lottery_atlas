import { readFile, writeFile } from 'node:fs/promises';

const [input, output] = process.argv.slice(2);
if (!input || !output) throw new Error('Expected input and output paths');
const payload = JSON.parse(await readFile(input, 'utf8'));
if (!Array.isArray(payload.totals)) throw new Error('Missing totals list');
const states = new Set();
for (const row of payload.totals) {
  if (!/^[A-Z]{2}$/.test(row.state) || states.has(row.state)) {
    throw new Error('Invalid or duplicate state');
  }
  states.add(row.state);
  if (!Number.isSafeInteger(row.winningTickets) || row.winningTickets < 0) {
    throw new Error(`Invalid winning-ticket count for ${row.state}`);
  }
  const dates = ['periodStart', 'periodEnd', 'sourceDate'].map((key) => {
    const value = row[key];
    if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
      throw new Error(`Invalid ${key} for ${row.state}`);
    }
    const parsed = Date.parse(value);
    if (Number.isNaN(parsed)) throw new Error(`Invalid ${key} for ${row.state}`);
    return parsed;
  });
  if (dates[0] > dates[1] || dates[1] > dates[2]) {
    throw new Error(`Inconsistent dates for ${row.state}`);
  }
  if (typeof row.sourceUrl !== 'string' ||
      !row.sourceUrl.startsWith('https://') ||
      typeof row.coverage !== 'string' ||
      !row.coverage.trim()) {
    throw new Error(`Missing official source or coverage for ${row.state}`);
  }
}
await writeFile(output, `${JSON.stringify(payload, null, 2)}\n`);
