import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {parseTableReports, assertNoReportRegression} from '../../tooling/virginia_draw_reports.mjs';
const fixture = (name) => JSON.parse(readFileSync(new URL(`./fixtures/virginia/${name}.json`, import.meta.url)));
test('official Virginia count tables preserve annual and tax wording', () => {
  const m = parseTableReports(fixture('millionaireforlife'), 1075)[0];
  assert.equal(m.totalWinners, 2254);
  assert.equal(m.tiers[0].prizeDescription, '$1,000,000 a year for life');
  assert.equal(m.totalPayout, null);
  const b = parseTableReports(fixture('bankamillion'), 1070)[0];
  assert.equal(b.totalWinners, 8423);
  assert.equal(b.tiers[0].prizeDescription, '$1,000,000 after taxes');
});
test('reject changed jurisdiction, malformed counts, tiers and duplicate dates', () => {
  for (const mutate of [p => p.data[0].DailyDrawDetails[0].DrawData.WinnerLocation = null,
    p => p.data[0].DailyDrawDetails[0].DrawData.Values[0].Winners = '1,2',
    p => p.data[0].DailyDrawDetails[0].DrawData.Values.pop(),
    p => p.data.push(p.data[0])]) {
    const p = fixture('millionaireforlife'); mutate(p);
    assert.throws(() => parseTableReports(p, 1075));
  }
});
test('reject unsupported national data and per-game date regression', () => {
  assert.throws(() => parseTableReports(fixture('millionaireforlife'), 20));
  const reports = parseTableReports(fixture('millionaireforlife'), 1075);
  assert.throws(() => assertNoReportRegression(reports, reports.slice(1)));
  assert.throws(() => assertNoReportRegression(reports, []));
  assert.doesNotThrow(() => assertNoReportRegression(reports, reports));
});
test('unpublished tier arrays are unavailable, not zero winner reports', () => {
  const p = fixture('millionaireforlife');
  p.data[0].DailyDrawDetails[0].DrawData.Values = [];
  assert.equal(parseTableReports(p, 1075).length, 1);
  p.data[1].DailyDrawDetails[0].DrawData.Values = [];
  assert.throws(() => parseTableReports(p, 1075));
});
