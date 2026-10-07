import sys
from pathlib import Path
import unittest
from html import escape
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tooling'))
from missouri_draw_reports import MM_MATCHES, parse_mega_millions


def fixture():
    prizes = ['Jackpot', '$2,000,000-$10,000,000', '$20,000-$100,000', '$1,000-$5,000', '$400-$2,000', '$20-$100', '$20-$100', '$14-$70', '$10-$50']
    counts = [0, 0, 0, 4, 10, 151, 132, 913, 2399]
    rows = ''.join('<tr><td>'+escape(m)+'</td><td>'+str(c)+'</td><td>'+p+'</td></tr>' for m, c, p in zip(MM_MATCHES, counts, prizes))
    return '<html><div class="block-megamillions-prizes-paid"><div class="content"><div class="h1 text-center">Friday, Oct 02, 2026</div><table><thead><tr><th>Numbers Matched</th><th>Number of MO Prizes</th><th>Prize amount</th></tr></thead><tbody>'+rows+'<tr><td>Grand Total MO Winners:</td><td>3,609</td><td>Grand Total Won:</td><td>$73,798</td><td></td></tr><tr><td>Location(s) of Jackpot Winner(s): N/A</td></tr></tbody></table></div></div></html>'


class ReportTests(unittest.TestCase):
    def test_literal_ranges_and_source_units(self):
        report = parse_mega_millions(fixture(), '2026-10-02')
        self.assertEqual(report['sourceWinnerCount'], 3609)
        self.assertEqual(report['sourcePayoutDollars'], 73798)
        self.assertEqual(report['tiers'][1]['prizeLabel'], '$2,000,000-$10,000,000')
        self.assertTrue(all(t['cashPrize'] is None for t in report['tiers']))
        self.assertIsNone(report['distinctTicketCount'])
        self.assertFalse(report['finalityVerified'])

    def test_reject_partial_wrong_date_identity_and_columns(self):
        for raw in [fixture().replace('</html>', ''), fixture().replace('Oct 02', 'Oct 03'), fixture().replace('Friday', 'Thursday'), fixture().replace('Number of MO Prizes', 'National Prizes'), fixture().replace('5 White balls</td>', '4 White balls</td>'), fixture().replace('<td>2399</td>', '<td></td>')]:
            with self.subTest(raw=raw[-100:]), self.assertRaises(ValueError):
                parse_mega_millions(raw, '2026-10-02')

    def test_reject_inconsistent_totals_or_prize_ranges(self):
        for raw in [fixture().replace('3,609', '3,608'), fixture().replace('$73,798', '$1'), fixture().replace('$14-$70', '$70-$14'), fixture().replace('$14-$70', '$14'), fixture().replace('<td>2399</td>', '<td>-1</td>')]:
            with self.assertRaises(ValueError):
                parse_mega_millions(raw, '2026-10-02')


from missouri_draw_reports import parse_powerball_xo, parse_show_me_cash


def fixed_fixture(xo=False):
    if xo:
        block, heading, column = 'block-powerball-prizes-paid', 'Sunday, Oct 04, 2026', 'Teams Matched'
        cells = [(f'{n} Teams', c, a) for n, c, a in zip(range(8, 3, -1), [0, 0, 6, 127, 711], ['$1,200,000', '$20,000', '$500', '$40', '$7'])]
        tail = '<tr><td>Total:</td><td>844</td><td>$13,057</td></tr><tr><td>Location(s) of Jackpot Winner(s): N/A</td></tr>'
    else:
        block, heading, column = 'block-show-me-cash-prizes-paid', 'Monday, Oct 05, 2026', 'Numbers Matched'
        cells = [(f'Match {n} of 5', c, a) for n, c, a in zip(range(5, 1, -1), [0, 22, 434, 5143], ['$0', '$250', '$10', '$1'])]
        tail = '<tr><td>Total Winners: 5,599 Total Won: $14,983</td></tr>'
    rows = ''.join('<tr>'+''.join('<td>'+str(v)+'</td>' for v in row)+'</tr>' for row in cells)
    return f'<html><div class="{block}"><div class="content"><div class="h1 text-center">{heading}</div><table><thead><tr><th>{column}</th><th>Number of MO Prizes</th><th>Prize amount</th></tr></thead><tbody>{rows}{tail}</tbody></table></div></div></html>'


class FixedReportTests(unittest.TestCase):
    def test_both_families_reconcile_without_cash_or_ticket_inference(self):
        for xo, parser, day, count, payout in [(True, parse_powerball_xo, '2026-10-04', 844, 13057), (False, parse_show_me_cash, '2026-10-05', 5599, 14983)]:
            r = parser(fixed_fixture(xo), day)
            self.assertEqual((r['sourceWinnerCount'], r['sourcePayoutDollars']), (count, payout))
            self.assertTrue(all(t['cashPrize'] is None for t in r['tiers']))
            self.assertIsNone(r['distinctTicketCount'])
        self.assertEqual(parse_show_me_cash(fixed_fixture(), '2026-10-05')['tiers'][0]['prizeLabel'], '$0')

    def test_reject_identity_truncation_and_both_total_mismatches(self):
        for xo, parser, day in [(True, parse_powerball_xo, '2026-10-04'), (False, parse_show_me_cash, '2026-10-05')]:
            raw = fixed_fixture(xo)
            for broken in [raw.replace('</html>', ''), raw.replace('2026', '2025'), raw.replace('Number of MO Prizes', 'Number of National Prizes'), raw.replace('844', '845').replace('5,599', '5,598'), raw.replace('$13,057', '$13,058').replace('$14,983', '$14,984'), raw.replace('<td>0</td>', '<td></td>', 1)]:
                with self.assertRaises(ValueError): parser(broken, day)
        with self.assertRaises(ValueError):
            parse_show_me_cash(fixed_fixture().replace('<td>0</td>', '<td>1</td>', 1), '2026-10-05')
        with self.assertRaises(ValueError):
            parse_powerball_xo(fixed_fixture(True).replace('8 Teams', '5 White balls'), '2026-10-04')


from missouri_draw_reports import parse_powerball, PB_MATCHES


def powerball_fixture():
    def table(headers, rows):
        return '<table><thead><tr>'+''.join('<th>'+h+'</th>' for h in headers)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+escape(str(c))+'</td>' for c in r)+'</tr>' for r in rows)+'</tbody></table>'
    main = list(zip(PB_MATCHES, [0,0,0,6,19,365,282,1961,4686], ['Jackpot','$1,000,000','$50,000','$100','$100','$7','$7','$4','$4'], ['-',0,0,2,0,74,43,314,709], ['-','$2,000,000','$100,000','$200','$200','$14','$14','$8','$8']))
    main += [('Total MO Winners (without Power Play):',7319,'Total Won:','$33,617',''), ('Total MO Winners (with Power Play):',1142,'Total Won:','$10,222',''), ('Grand Total MO Winners:',8461,'Grand Total Won:','$43,839',''), ('Location(s) of Jackpot Winner(s): N/A',)]
    double = list(zip(PB_MATCHES,[0,0,0,1,2,41,29,238,538],['$10,000,000','$500,000','$50,000','$500','$500','$20','$20','$10','$7']))
    double += [('Total MO Winners:',849,''),('Total WON:','','$9,046')]
    return '<html><div class="block-powerball-prizes-paid"><div class="content"><div class="h1 text-center">Monday, Oct 05, 2026 - Main Drawing</div><div class="num-list__pp">PP: 2X</div>'+table(['Numbers Matched','Number of MO Prizes','Prize amount','Number of MO Power Play Prizes','Power Play Prize Amount'],main)+'<h2 class="h1 text-center">Monday, Oct 05, 2026 - Double Play Drawing</h2>'+table(['Numbers Matched','Number of MO Prizes','Prize Amount'],double)+'</div></div></html>'


class PowerballTests(unittest.TestCase):
    def test_variants_and_unavailable_jackpot_preserved(self):
        r = parse_powerball(powerball_fixture(), '2026-10-05')
        self.assertEqual(r['powerPlayMultiplier'], 2)
        self.assertEqual(r['mainSourceWinnerCount'], 8461)
        self.assertEqual([v['sourceWinnerCount'] for v in r['variants']], [7319,1142,849])
        self.assertEqual(r['variants'][2]['sourcePayoutDollars'], 9046)
        self.assertIsNone(r['variants'][1]['tiers'][0]['sourcePrizeCount'])
        self.assertIsNone(r['distinctTicketCount'])

    def test_reject_variant_date_counts_payout_and_multiplier_corruption(self):
        raw = powerball_fixture()
        for broken in [raw.replace('</html>',''), raw.replace('PP: 2X','PP: 3X'), raw.replace('2026 - Double','2025 - Double'), raw.replace('<td>8461</td>','<td>8462</td>'), raw.replace('$9,046','$9,047'), raw.replace('$10,222','$10,223'),raw.replace('<td>-</td>','<td>0</td>',1),raw.replace('Number of MO Power Play Prizes','Power Play')]:
            with self.assertRaises(ValueError): parse_powerball(broken, '2026-10-05')


from missouri_draw_reports import parse_mo_millions, parse_cash_pop, MO_MILLIONS_MATCHES, CASH_POP_AMOUNTS


def simple_table(headers, rows):
    return '<table><thead><tr>'+''.join('<th>'+escape(h)+'</th>' for h in headers)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+escape(str(c))+'</td>' for c in r)+'</tr>' for r in rows)+'</tbody></table>'


def mo_fixture():
    body = ''
    for name, counts, amounts, count, payout in [
        ('Main',[0,3,0,97,32,951,916,3964],[0,1500,750,50,25,6,3,2],5963,26532),
        ('Double Play',[0,0,0,14,8,130,127,591],[50000,2000,1000,70,35,10,5,3],870,4968)]:
        rows = [(m,c,f'${a:,}','') for m,c,a in zip(MO_MILLIONS_MATCHES,counts,amounts)]
        rows += [('Grand Total Winners:',count,'Grand Total Won:',f'${payout:,}')]
        body += f'<div class="h1 text-center">Saturday, Oct 03, 2026 - {name} Drawing</div>'+simple_table(['Numbers Matched','Number of MO Prizes','Prize amount',''],rows)
    return '<html><div class="block-powerball-prizes-paid"><div class="content">'+body+'</div></div></html>'


def cash_fixture():
    counts = [0,0,0,3,2,6,3,4,14,7,6,37,2,12,5,56,11,8,5,42,17,41]
    rows = [(c,f'${a:,}') for c,a in zip(counts,CASH_POP_AMOUNTS)]
    rows += [('Total Winners: 281 Total Won: $11,549',)]
    return '<html><div class="block-cashpop-prizes-paid"><div class="content"><div class="h1 text-center">Tuesday, Oct 06, 2026, Matinee</div>'+simple_table(['Number of Prizes','Prize Amount'],rows)+'</div></div></html>'


class MoreReportTests(unittest.TestCase):
    def test_mo_variants_bullseye_zero_label_and_totals(self):
        r = parse_mo_millions(mo_fixture(), '2026-10-03')
        self.assertEqual([v['sourceWinnerCount'] for v in r['variants']], [5963,870])
        self.assertEqual([v['sourcePayoutDollars'] for v in r['variants']], [26532,4968])
        self.assertEqual(r['variants'][0]['tiers'][0]['prizeLabel'], '$0')
        self.assertIn('Bulls-Eye', r['variants'][0]['tiers'][1]['matchLabel'])
        self.assertIsNone(r['distinctTicketCount'])

    def test_mo_rejects_missing_variant_date_identity_padding_and_totals(self):
        for raw in [mo_fixture().replace('</html>',''),mo_fixture().replace('2026 - Double','2025 - Double'),mo_fixture().replace('Bulls-Eye','Bonus'),mo_fixture().replace('$26,532','$26,533'),mo_fixture().replace('<td>870</td>','<td>871</td>'),mo_fixture().replace('<td></td>','<td>extra</td>',1)]:
            with self.assertRaises(ValueError): parse_mo_millions(raw,'2026-10-03')

    def test_cash_pop_session_and_prize_amount_units(self):
        r = parse_cash_pop(cash_fixture(),'2026-10-06',3)
        self.assertEqual((r['sourceWinnerCount'],r['sourcePayoutDollars']),(281,11549))
        self.assertEqual(r['sessionLabel'],'Matinee')
        self.assertEqual(len(r['tiers']),22)
        self.assertTrue(all(t['matchLabel'] is None for t in r['tiers']))
        for session in [0,1,4,6,True,'3']:
            with self.assertRaises(ValueError): parse_cash_pop(cash_fixture(),'2026-10-06',session)

    def test_cash_rejects_wrong_dates_prizes_missing_counts_and_totals(self):
        for raw in [cash_fixture().replace('</html>',''),cash_fixture().replace('Oct 06','Oct 05'),cash_fixture().replace('$2,500','$2,501'),cash_fixture().replace('<td>0</td>','<td></td>',1),cash_fixture().replace('281','282'),cash_fixture().replace('$11,549','$11,550')]:
            with self.assertRaises(ValueError): parse_cash_pop(raw,'2026-10-06',3)


from missouri_draw_reports import parse_pick, PICK_MATCHES


def pick_fixture(game):
    if game == 3:
        base, wild = [125,245,0,7,3], [144,20,0,0,0]
        prizes, wildprizes = ['$300','$100','$50','$30','$30'], ['$100','$34','$17','$10','$10']
        total = 'Total Winners: 544 Total Won: $77,380'
    else:
        base, wild = [25,0,0,244,0,0,0,14,0,5], [12,0,0,31,60,0,0,0,0,8]
        prizes = ['$3,000','$750','$500','$250','$125','$300','$300','$30','$30','$30']
        wildprizes = ['$750','$190','$125','$63','$31','$75','$75','$7.5','$7.5','$7.5']
        total = 'Total Winners: 399 Total Won: $149,443'
    rows = list(zip(PICK_MATCHES[game],base,prizes,wild,wildprizes)) + [('(Based on $.50 Plays)',),(total,)]
    amt = 'Prize amount' if game == 3 else 'Prize Amount'
    table = simple_table(['Numbers Matched','Number of MO Prizes',amt,'Number of MO Prizes',amt],rows)
    table = table.replace('<thead>',f'<thead><tr><th colspan="3">Pick {game}</th><th colspan="2">Pick {game} + Wild ball</th></tr>')
    return f'<html><div class="block-pick{game}-prizes-paid"><div class="content"><div class="h1 text-center">Tuesday, Oct 06, 2026 - Midday</div>{table}</div></div></html>'


class PickReportTests(unittest.TestCase):
    def test_base_wildball_basis_and_fractional_prizes(self):
        for game, count, cents in [(3,544,7738000),(4,399,14944300)]:
            r = parse_pick(pick_fixture(game),'2026-10-06',game,'Midday')
            self.assertEqual((r['sourceWinnerCount'],r['sourcePayoutCents']),(count,cents))
            self.assertEqual(r['playBasisCents'],50)
            self.assertIsNone(r['distinctTicketCount'])
            self.assertEqual(len(r['variants']),2)
        r = parse_pick(pick_fixture(4),'2026-10-06',4,'Midday')
        self.assertEqual(r['variants'][1]['tiers'][-1]['sourceAmountCents'],750)
        self.assertEqual(r['variants'][1]['tiers'][-1]['prizeLabel'],'$7.5')

    def test_reject_session_identity_basis_and_corrupted_totals(self):
        for game in [3,4]:
            raw = pick_fixture(game)
            for broken in [raw.replace('</html>',''), raw.replace('Oct 06','Oct 05'),raw.replace('Midday','Evening'),raw.replace('$.50','$1.00'),raw.replace('Straight*','Straight'),raw.replace('544','545').replace('399','400'),raw.replace('$77,380','$77,381').replace('$149,443','$149,444'),raw.replace('colspan="2"','colspan="3"')]:
                with self.assertRaises(ValueError): parse_pick(broken,'2026-10-06',game,'Midday')
        for value in ['$7.555','$-1','$07.5','7.5']:
            with self.assertRaises(ValueError): parse_pick(pick_fixture(4).replace('$7.5',value),'2026-10-06',4,'Midday')

if __name__ == '__main__': unittest.main()
