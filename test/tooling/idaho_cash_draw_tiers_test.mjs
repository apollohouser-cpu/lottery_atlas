import {test} from 'node:test';
import assert from 'node:assert/strict';
import {datesThrough, latestDrawFromPage, parseDraw, buildReport} from '../../tooling/import_idaho_cash_draw_tiers.mjs';

const fixture = () => ({success: true, data: {game: 'Idaho Cash', draw_date: '2026-01-01',
  winning_numbers: [1, 4, 7, 35, 45].map((n) => ({'1': String(n).padStart(2, '0')})),
  winners: [['Jackpot', '0'], ['$200', '3'], ['$5', '152'], ['Free Ticket', '1903']]
    .map(([label, count], i) => ({weight: i + 5, '0': label, '1': count})),
}});

test('tier labels control mapping; zero remains zero and free tickets are not cash', () => {
  const payload = fixture(); payload.data.winners.reverse();
  const draw = parseDraw(payload, '2026-01-01');
  assert.deepEqual(draw.tiers.map((tier) => tier.publishedWinnerCount), [0, 3, 152, 1903]);
  assert.equal(draw.tiers[3].prizeKind, 'free-ticket');
  assert.equal(draw.tiers[3].cashPrize, undefined);
  assert.equal(draw.tiers[0].cashPrize, undefined);
});

test('missing tiers, unknown tiers, duplicates and invalid counts fail', () => {
  for (const mutate of [
    (p) => p.data.winners.pop(),
    (p) => p.data.winners[0]['0'] = '$1',
    (p) => p.data.winners[0]['0'] = '$200',
    (p) => p.data.winners[0]['1'] = '',
    (p) => p.data.winners[0]['1'] = null,
    (p) => p.data.winners[0]['1'] = '-1',
    (p) => p.data.winners[0]['1'] = '1.5',
  ]) {
    const payload = fixture(); mutate(payload);
    assert.throws(() => parseDraw(payload, '2026-01-01'));
  }
});

test('a wrong date, game, response or ball fails', () => {
  for (const mutate of [
    (p) => p.data.draw_date = '2026-01-02',
    (p) => p.data.game = 'Powerball',
    (p) => p.success = false,
    (p) => p.data.winning_numbers[0]['1'] = '46',
    (p) => p.data.winning_numbers[0]['1'] = '04',
  ]) {
    const payload = fixture(); mutate(payload);
    assert.throws(() => parseDraw(payload, '2026-01-01'));
  }
});

test('continuous daily history requires every requested drawing', () => {
  const draw = parseDraw(fixture(), '2026-01-01');
  const report = buildReport([draw], '2026-01-01');
  assert.equal(report.totalsByTier[3].publishedWinnerCount, 1903);
  assert.equal(report.winningTickets, undefined);
  assert.throws(() => buildReport([draw], '2026-01-02'));
  assert.throws(() => buildReport([draw, draw], '2026-01-02'));
  assert.equal(datesThrough('2026-09-18').length, 261);
  assert.throws(() => datesThrough('2026-02-30'));
});

test('the source date comes from the specific game winner table', () => {
  const html = '<input class="datepicker winners-datepicker" data-game="Idaho Cash" data-region="idaho" value="01/01/26">';
  assert.equal(latestDrawFromPage(html), '2026-01-01');
  assert.throws(() => latestDrawFromPage(html + html));
  assert.throws(() => latestDrawFromPage(html.replace('Idaho Cash', 'Powerball')));
});
