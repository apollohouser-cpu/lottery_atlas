from datetime import date
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tooling'))
from north_carolina_draw_reports import parse_cash_pop, CASH_POP_SESSIONS


def fixture():
    rows=[]
    for day in [6,7,8]:
        for name,clock in CASH_POP_SESSIONS.items():
            values=dict(lblDrawDate=f'2026, Oct {day}',lblSlotTime=clock,lblSlotName=name,lblPop='3',lblTotalWinners='633',lblTotalPayout='$21,908')
            span=lambda k:f'<span id="fixture_{k}">{values[k]}</span>'
            rows.append('<tr><td>'+span('lblDrawDate')+'</td><td>'+span('lblSlotTime')+' - '+span('lblSlotName')+'</td><td>'+span('lblPop')+'</td><td>'+span('lblTotalWinners')+'</td><td>'+span('lblTotalPayout')+'</td><td>Watch</td></tr>')
    return ('<html><main><table class="datatable past_draws"><thead><tr>'+''.join(f'<th>{v}</th>' for v in ['Date','Drawing','Pop','Winners','Payout','Watch*'])+'</tr></thead><tbody>'+''.join(rows)+'</tbody></table><table><tr><td>Promotional unrelated counts</td></tr></table></main></html>').encode()


class NCReportTests(unittest.TestCase):
    def test_two_latest_per_session_and_no_invented_tiers(self):
        rows=parse_cash_pop(fixture(),today=date(2026,10,8))
        self.assertEqual(len(rows),10)
        for name in CASH_POP_SESSIONS:
            self.assertEqual([r['drawDate'] for r in rows if r['session']==name],['2026-10-08','2026-10-07'])
        self.assertEqual(rows[0]['reportedWinners'],633)
        self.assertEqual(rows[0]['reportedPayoutCents'],2190800)
        self.assertNotIn('tiers',rows[0]);self.assertNotIn('latitude',rows[0])

    def test_malformed_source_rejected_even_in_old_unselected_rows(self):
        raw=fixture()
        for before,after in [(b'2026, Oct 6',b'2026, Feb 30'),(b'2026, Oct 6',b'2027, Oct 6'),
            (b'9:00 AM',b'10:00 AM'),(b'Morning Buzz',b'Unknown'),(b'>3</span>',b'>16</span>'),
            (b'>633</span>',b'>-1</span>'),(b'$21,908',b'$21,90'),(b'<th>Winners</th>',b'<th>Sales</th>'),
            (b'</html>',b''),(b'lblTotalWinners',b'missing')]:
            with self.subTest(before=before):
                with self.assertRaises(ValueError):parse_cash_pop(raw.replace(before,after,1),today=date(2026,10,8))

    def test_duplicate_or_missing_session_rejected(self):
        raw=fixture()
        with self.assertRaises(ValueError):parse_cash_pop(raw.replace(b'2026, Oct 6',b'2026, Oct 7'),today=date(2026,10,8))
        from lxml import html,etree
        doc=html.fromstring(raw)
        for row in doc.xpath('//tbody/tr')[1::5]:row.getparent().remove(row)
        with self.assertRaises(ValueError):parse_cash_pop(etree.tostring(doc),today=date(2026,10,8))

    def test_zero_and_fractional_payout_preserve_source_units(self):
        raw=fixture().replace(b'>633</span>',b'>0</span>').replace(b'$21,908',b'$0')
        self.assertEqual(parse_cash_pop(raw,today=date(2026,10,8))[0]['reportedWinners'],0)
        with self.assertRaises(ValueError):parse_cash_pop(raw.replace(b'$0',b'$1'),today=date(2026,10,8))
        rows=parse_cash_pop(fixture().replace(b'$21,908',b'$21,908.50'),today=date(2026,10,8))
        self.assertEqual(rows[0]['reportedPayoutCents'],2190850)


from north_carolina_draw_reports import parse_pick_summary, parse_pick_reports


def pick_fixture(size=3, day=7, session='Evening'):
    prefix=f'ctl00_MainContent_PayoutPick{size}_PayoutRepeater_ctl00_'
    values={
        'lblDrawDate':f'<svg aria-label="{session} Draw"></svg>'+date(2026,10,day).strftime('%A %b %d, %Y'),
        'lblFireball':'0', 'lblWinningsLabel':'Total Combined Winnings',
        'lblWinnings':'1,527 winners won a total of $227,915',
        **{f'lblBall{i}':str(i-1) for i in range(1,size+1)},
    }
    return ('<html><head><meta charset="utf-8"></head><main>'+''.join(f'<span id="{prefix}{k}">{v}</span>' for k,v in values.items())+
        pick_schedule_fixture(size)+'</main></html>').encode()


class NCPickReportTests(unittest.TestCase):
    def test_summary_preserves_leading_zero_and_source_units(self):
        for size in [3,4]:
            r=parse_pick_summary(pick_fixture(size),f'Pick {size}',f'https://nclottery.com/Pick{size}-Draw?dn=123',today=date(2026,10,8))
            self.assertEqual(r['winningDigits'],list('0123')[:size])
            self.assertEqual(r['fireball'],'0')
            self.assertEqual(r['reportedWinners'],1527)
            self.assertEqual(r['reportedPayoutCents'],22791500)
            self.assertEqual(r['reportType'],'combined-summary')
            self.assertNotIn('tiers',r)
            self.assertNotIn('latitude',r)

    def test_invalid_identity_date_session_counts_and_structure_rejected(self):
        for before,after in [(b'Wednesday',b'Tuesday'),(b'2026',b'2027'),
            (b'Evening Draw',b'Morning Draw'),(b'1,527',b'1,52'),
            (b'$227,915',b'$-1'),(b'$227,915',b'$0'),
            (b'lblBall1',b'lblBall4'),(b'>0</span>',b'>10</span>'),
            (b'Total Combined Winnings',b'Total Sales'),(b'</html>',b''),
            (b'lblWinnings"',b'unknown"'),(b'won a total of',b'claimed')]:
            with self.subTest(before=before),self.assertRaises(ValueError):
                parse_pick_summary(pick_fixture().replace(before,after,1),'Pick 3','https://nclottery.com/Pick3-Draw?dn=123',today=date(2026,10,8))
        for url in ['https://nclottery.com/Pick4-Draw?dn=123','https://other.example/Pick3-Draw?dn=123','https://nclottery.com/Pick3-Draw?dn=123&extra=1']:
            with self.assertRaises(ValueError):parse_pick_summary(pick_fixture(),'Pick 3',url)
        with self.assertRaises(ValueError):parse_pick_summary(pick_fixture(4),'Pick 3','https://nclottery.com/Pick3-Draw?dn=123')

    def test_complete_groups_validate_old_rows_and_reject_duplicates(self):
        documents=[(f'https://nclottery.com/Pick3-Draw?dn={day*2+index}',pick_fixture(day=day,session=session))
                   for day in [6,8,7] for index,session in enumerate(['Daytime','Evening'])]
        rows=parse_pick_reports(documents,'Pick 3',today=date(2026,10,8))
        self.assertEqual([(r['session'],r['drawDate']) for r in rows],[(s,d) for s in ['Daytime','Evening'] for d in ['2026-10-08','2026-10-07']])
        with self.assertRaises(ValueError):parse_pick_reports(documents+documents[:1],'Pick 3',today=date(2026,10,8))
        with self.assertRaises(ValueError):parse_pick_reports(documents[::2],'Pick 3',today=date(2026,10,8))
        documents[0]=(documents[0][0],documents[0][1].replace(b'1,527',b'-1'))
        with self.assertRaises(ValueError):parse_pick_reports(documents,'Pick 3',today=date(2026,10,8))

    def test_zero_fractional_and_duplicate_fields(self):
        raw=pick_fixture().replace(b'1,527',b'0').replace(b'$227,915',b'$0')
        self.assertEqual(parse_pick_summary(raw,'Pick 3','https://nclottery.com/Pick3-Draw?dn=123')['reportedWinners'],0)
        raw=pick_fixture().replace(b'$227,915',b'$227,915.50')
        self.assertEqual(parse_pick_summary(raw,'Pick 3','https://nclottery.com/Pick3-Draw?dn=123')['reportedPayoutCents'],22791550)
        extra=b'<span id="ctl00_MainContent_PayoutPick3_PayoutRepeater_ctl00_lblWinnings">1 winners won a total of $1</span>'
        with self.assertRaises(ValueError):parse_pick_summary(raw.replace(b'</main>',extra+b'</main>'),'Pick 3','https://nclottery.com/Pick3-Draw?dn=123')


from north_carolina_draw_reports import parse_pick_report, parse_pick_schedules

def pick_schedule_fixture(size=3):
    header=lambda label: '<thead><tr><th>Play Type</th><th>Match</th><th colspan="2">'+label+'</th></tr><tr><td></td><td></td><td>50¢ Base Play</td><td>$1 Base Play</td></tr></thead>'
    base='<tbody><tr><td>EXACT</td><td>0‑1‑2</td><td>$250</td><td>$500</td></tr></tbody>'
    base+='<tbody><tr><td>ANY</td><td rowspan="3">6-Way<br><span>0‑1‑2</span><span>0‑2‑1</span></td><td>$40</td><td>$80</td></tr>'
    base+='<tr><td>50/50</td><td>N/A</td><td>Exact+Any $290<br>Any $40</td></tr>'
    base+='<tr><td>COMBO</td><td>$3 Play<br>$250</td><td>$6 Play<br>$500</td></tr></tbody>'
    base+='<tbody><tr><td>PAIR</td><td>0‑1 Front | 1‑2 Back</td><td>$25</td><td>$50</td></tr></tbody>'
    ways=['3-Way','6-Way'] if size==3 else ['4-Way','6-Way','12-Way','24-Way']
    fire='<tbody><tr><td>EXACT</td><td></td><td>$90</td><td>$180</td></tr>'
    for play in ['ANY','50/50','COMBO']:
        for i,way in enumerate(ways):
            fire+='<tr>'+(f'<td rowspan="{len(ways)}">{play}</td>' if i==0 else '')+f'<td>{way}</td><td>$15</td><td>$30</td></tr>'
    fire+='<tr><td>PAIR</td><td>Front | Back</td><td>$9</td><td>$18</td></tr></tbody>'
    fire+='<tfoot><tr><td colspan="4">Fireball wins are dependent on your numbers chosen and play type.</td></tr></tfoot>'
    return f'<table class="datatable payout_results"><caption>Pick {size} Prizes</caption>'+header('Payout')+base+'</table><table class="datatable payout_results"><caption>Fireball Prizes</caption>'+header('Payout / Win')+fire+'</table>'


class NCPickScheduleTests(unittest.TestCase):
    def test_literal_cells_keep_match_and_wager_alignment(self):
        for size in [3,4]:
            r=parse_pick_report(pick_fixture(size),f'Pick {size}',f'https://nclottery.com/Pick{size}-Draw?dn=123')
            base,fire=r['payoutSchedules']
            self.assertEqual(len(fire['rows']),8 if size==3 else 14)
            self.assertEqual(base['rows'][1]['matchLabel'],'6-Way 0‑1‑2 0‑2‑1')
            self.assertEqual(base['rows'][2]['matchLabel'],base['rows'][1]['matchLabel'])
            self.assertEqual(base['rows'][3]['payoutLabels'],['$3 Play $250','$6 Play $500'])
            self.assertEqual(base['rows'][2]['payoutLabels'],['N/A','Exact+Any $290 Any $40'])
            self.assertEqual(fire['rows'][2]['playType'],'ANY')
            self.assertNotIn('winners',base['rows'][0])
            self.assertIn('dependent',fire['notes'][0])

    def test_schedule_changes_and_incomplete_rows_fail_closed(self):
        for before,after in [(b'rowspan="3"',b'rowspan="4"'),(b'rowspan="3"',b'rowspan="0"'),
            (b'<td>$40</td>',b''),(b'<td>$40</td>',b'<td colspan="2">$40</td>'),
            (b'$3 Play',b'$3 Sales'),(b'$250',b'$2,50'),(b'Pick 3 Prizes',b'Other Prizes'),
            (b'Fireball Prizes',b'Pick 3 Prizes'),(b'Payout / Win',b'Winners'),
            (b'50/50',b'Unknown'),(b'3-Way',b'9-Way'),
            (b'Fireball wins are dependent on your numbers chosen and play type.',b''),
            (b'</html>',b'')]:
            with self.subTest(before=before),self.assertRaises(ValueError):
                parse_pick_schedules(pick_fixture().replace(before,after,1),'Pick 3')

    def test_batch_rejects_malformed_schedule_before_recent_selection(self):
        docs=[(f'https://nclottery.com/Pick3-Draw?dn={day*2+i}',pick_fixture(day=day,session=session))
              for day in [6,7,8] for i,session in enumerate(['Daytime','Evening'])]
        docs[0]=(docs[0][0],docs[0][1].replace(b'Payout / Win',b'Winners'))
        with self.assertRaises(ValueError):parse_pick_reports(docs,'Pick 3',today=date(2026,10,8))


from north_carolina_draw_reports import parse_cash5_report, parse_cash5_reports


def cash5_fixture(day=7):
    parts=[]
    for i,logo in enumerate(['Cash 5 Logo','Double Play Logo']):
        def span(suffix,value):return f'<span id="ctl00_MainContent_rptCash5_ctl0{i}_{suffix}">{value}</span>'
        date_field=span('lblDateValue',date(2026,10,day).strftime('%A, %b %d, %Y')) if i==0 else ''
        balls=''.join(span('lblBall'+str(b),str(b)) for b in range(1,6))
        parts.append(f'<div class="box parts details Cash5"><img alt="{logo}">{date_field}{balls}</div>')
        rows=''
        for n in [5,4,3,2]:
            prize='$171,000*' if i==0 and n==5 else '$50,000' if n==5 else '$5'
            rows+=f'<tr><td>{n} of 5</td><td>'+span('lblPrize'+str(n),prize)+'</td><td>'+span('lblWin'+str(n),'0' if n==5 else '20')+'</td></tr>'
        note='*Rollover <br>Advertised Jackpot estimate at time of draw: $171,000.' if i==0 else ''
        parts.append('<table class="datatable payout_results"><caption>Prize Distribution</caption><thead><tr><th>Match</th><th>Prize</th><th>Wins</th></tr></thead><tbody>'+rows+'</tbody><tfoot><tr><td colspan="3">'+span('lblTopPrizeFootnote',note)+'</td></tr></tfoot></table>')
    return ('<html><main>'+''.join(parts)+'</main></html>').encode()


class NCCash5Tests(unittest.TestCase):
    def test_variants_separate_literal_rollover_and_wins(self):
        r=parse_cash5_report(cash5_fixture(),'https://nclottery.com/cash5?dd=10/07/2026',today=date(2026,10,8))
        self.assertEqual([v['name'] for v in r['variants']],['Cash 5','Double Play'])
        base,dp=r['variants']
        self.assertEqual(base['tiers'][0],dict(matchLabel='5 of 5',prizeLabel='$171,000*',reportedWins=0))
        self.assertIn('Advertised Jackpot estimate',base['notes'][0])
        self.assertEqual(dp['tiers'][0]['prizeLabel'],'$50,000')
        self.assertEqual(dp['notes'],[])
        self.assertNotIn('totalPayout',r)
        self.assertNotIn('prizeCents',base['tiers'][0])

    def test_structure_identity_dates_and_tier_values_fail_closed(self):
        raw=cash5_fixture()
        for before,after in [(b'Wednesday',b'Tuesday'),(b'2026',b'2027'),(b'lblDateValue',b'missingDate'),
            (b'Double Play Logo',b'Cash 5 Logo'),(b'>1</span>',b'>44</span>'),(b'>1</span>',b'>2</span>'),
            (b'lblBall5',b'missingBall'),(b'<th>Wins</th>',b'<th>Sales</th>'),(b'5 of 5',b'4 of 5'),
            (b'$171,000*',b'$171,00*'),(b'>20</span>',b'>-20</span>'),(b'>0</span>',b'>1</span>'),
            (b'*Rollover',b''),(b'lblPrize4',b'lblPrize3'),(b'</html>',b'')]:
            with self.subTest(before=before),self.assertRaises(ValueError):
                parse_cash5_report(raw.replace(before,after,1),'https://nclottery.com/cash5?dd=10/07/2026',today=date(2026,10,8))
        for url in ['https://nclottery.com/cash5?dd=10/06/2026','https://other.example/cash5?dd=10/07/2026','https://nclottery.com/cash5?dd=10/07/2026&extra=1']:
            with self.assertRaises(ValueError):parse_cash5_report(raw,url)
        with self.assertRaises(ValueError):parse_cash5_report(raw,'https://nclottery.com/cash5?dd=10/07/2026',today=date(2026,10,6))

    def test_batch_bounds_after_validation_and_requires_two_unique_draws(self):
        docs=[(f'https://nclottery.com/cash5?dd=10/0{day}/2026',cash5_fixture(day)) for day in [5,7,6]]
        self.assertEqual([r['drawDate'] for r in parse_cash5_reports(docs,today=date(2026,10,8))],['2026-10-07','2026-10-06'])
        with self.assertRaises(ValueError):parse_cash5_reports(docs[:1])
        with self.assertRaises(ValueError):parse_cash5_reports(docs+docs[:1])
        docs[0]=(docs[0][0],docs[0][1].replace(b'<th>Wins</th>',b'<th>Sales</th>'))
        with self.assertRaises(ValueError):parse_cash5_reports(docs)

    def test_swapped_variant_tables_rejected(self):
        from lxml import html,etree
        root=html.fromstring(cash5_fixture());tables=root.xpath('//table');parent=tables[0].getparent()
        parent.remove(tables[1]);parent.insert(1,tables[1])
        with self.assertRaises(ValueError):parse_cash5_report(etree.tostring(root),'https://nclottery.com/cash5?dd=10/07/2026')


from north_carolina_draw_reports import parse_millionaire_report, parse_millionaire_reports, MFL_SCOPE


def millionaire_fixture(day=7):
    def span(key,value):return f'<span id="ctl00_MainContent_{key}">{value}</span>'
    fields=span('lblDrawdate',date(2026,10,day).strftime('%A, %b %d, %Y'))
    fields+=''.join(span('lblBall'+str(i),str(i)) for i in range(1,6))+span('lblBallM','5')
    rows=''
    for i,match in enumerate(['5+MB','5','4+MB','4','3+MB','3','2+MB','2','1+MB'],1):
        prize=['$1 Million/year for life','$100,000/year for life'][i-1] if i<3 else '$8'
        rows+=f'<tr><td aria-label="{match}">graphic</td><td>'+span('lblPay'+str(i),prize)+'</td><td>'+span('lblt'+str(i),'0' if i<3 else '1,178')+'</td></tr>'
    return ('<html><main>'+fields+'<table class="datatable payout_results"><caption>Winnings</caption><thead><tr><th>Match</th><th>Prize</th><th>Wins</th></tr></thead><tbody>'+rows+'</tbody><tfoot><tr><td>'+MFL_SCOPE+'</td></tr></tfoot></table></main></html>').encode()


class NCMillionaireTests(unittest.TestCase):
    def test_annuity_labels_nc_scope_and_source_units_retained(self):
        r=parse_millionaire_report(millionaire_fixture(),'https://nclottery.com/millionaire-for-life?dd=10/07/2026')
        self.assertEqual(r['tiers'][0]['prizeLabel'],'$1 Million/year for life')
        self.assertEqual(r['tiers'][1]['prizeLabel'],'$100,000/year for life')
        self.assertEqual(r['tiers'][8]['matchLabel'],'1+MB')
        self.assertEqual(r['tiers'][8]['reportedWins'],1178)
        self.assertEqual(r['notes'],[MFL_SCOPE])
        self.assertNotIn('totalPayout',r)
        self.assertNotIn('cashValue',r['tiers'][0])

    def test_changed_dates_numbers_tiers_and_annuity_fail_closed(self):
        for before,after in [(b'Wednesday',b'Tuesday'),(b'lblDrawdate',b'noDate'),(b'>1</span>',b'>59</span>'),
            (b'>1</span>',b'>2</span>'),(b'lblBallM">5',b'lblBallM">6'),(b'lblBall5',b'noBall'),
            (b'5+MB',b'5+PB'),(b'$1 Million/year for life',b'$1 Million'),(b'$8',b'$-8'),
            (b'1,178',b'1,17'),(b'lblPay9',b'lblPay8'),(b'<th>Wins</th>',b'<th>Sales</th>'),
            (MFL_SCOPE.encode(),b'Nationwide wins'),(b'</html>',b'')]:
            with self.subTest(before=before),self.assertRaises(ValueError):
                parse_millionaire_report(millionaire_fixture().replace(before,after,1),'https://nclottery.com/millionaire-for-life?dd=10/07/2026')
        with self.assertRaises(ValueError):parse_millionaire_report(millionaire_fixture(),'https://nclottery.com/millionaire-for-life?dd=10/06/2026')
        with self.assertRaises(ValueError):parse_millionaire_report(millionaire_fixture(),'https://nclottery.com/millionaire-for-life?dd=10/07/2026',today=date(2026,10,6))
        with self.assertRaises(ValueError):parse_millionaire_report(millionaire_fixture(),'https://other.example/millionaire-for-life?dd=10/07/2026')

    def test_unique_bounded_reports_validate_old_source_rows(self):
        docs=[(f'https://nclottery.com/millionaire-for-life?dd=10/0{d}/2026',millionaire_fixture(d)) for d in [5,7,6]]
        self.assertEqual([r['drawDate'] for r in parse_millionaire_reports(docs)],['2026-10-07','2026-10-06'])
        with self.assertRaises(ValueError):parse_millionaire_reports(docs[:1])
        with self.assertRaises(ValueError):parse_millionaire_reports(docs+docs[:1])
        docs[0]=(docs[0][0],docs[0][1].replace(b'1,178',b'-1'))
        with self.assertRaises(ValueError):parse_millionaire_reports(docs)


from north_carolina_draw_reports import parse_xo_report, parse_xo_reports, XO_SCOPE


def xo_fixture(day=4):
    def span(key,value):return f'<span id="ctl00_MainContent_{key}">{value}</span>'
    fields=span('lblDrawdate',date(2026,10,day).strftime('%A, %b %d, %Y'))
    fields+=''.join(span('lblTeam'+str(i),t) for i,t in enumerate(['ATL','BAL','CAR','DEN','DET','JAX','LAC','WAS'],1))
    rows=''.join(f'<tr><td aria-label="Match {9-i}">Match {9-i}</td><td>'+span('lblPay'+str(i),'$1,220,000' if i==1 else '$7')+'</td><td>'+span('lblTier'+str(i),'0' if i==1 else '1,810')+'</td></tr>' for i in range(1,6))
    return ('<html><main>'+fields+'<table class="datatable payout_results"><caption>Prize Payout</caption><thead><tr><th>Match</th><th>Cash Prize*</th><th>Wins</th></tr></thead><tbody>'+rows+'</tbody><tfoot><tr><td>'+XO_SCOPE+'</td></tr></tfoot></table></main></html>').encode()


class NCXsOsTests(unittest.TestCase):
    def test_labels_and_shared_prize_qualification_preserved(self):
        r=parse_xo_report(xo_fixture(),'https://nclottery.com/Powerball-Xs-and-Os?dd=10/04/2026')
        self.assertEqual(r['tiers'][0],dict(matchLabel='Match 8',prizeLabel='$1,220,000',reportedWins=0))
        self.assertEqual(r['tiers'][-1]['reportedWins'],1810)
        self.assertEqual(r['teamLabels'],['ATL','BAL','CAR','DEN','DET','JAX','LAC','WAS'])
        self.assertEqual(r['notes'],[XO_SCOPE]);self.assertNotIn('totalPayout',r)

    def test_invalid_identity_structure_dates_and_units(self):
        for before,after in [(b'Sunday',b'Monday'),(b'lblDrawdate',b'missing'),(b'ATL',b'BAL'),(b'ATL',b'12'),
            (b'lblTeam8',b'missingTeam'),(b'Match 8',b'Match 7'),(b'lblPay5',b'lblPay4'),
            (b'$1,220,000',b'$1,22,000'),(b'1,810',b'-1'),(b'Cash Prize*',b'Cash Prize'),
            (XO_SCOPE.encode(),b'Nationwide wins'),(b'</html>',b'')]:
            with self.subTest(before=before),self.assertRaises(ValueError):
                parse_xo_report(xo_fixture().replace(before,after,1),'https://nclottery.com/Powerball-Xs-and-Os?dd=10/04/2026')
        for url in ['https://nclottery.com/Powerball-Xs-and-Os?dd=10/05/2026','https://other.example/Powerball-Xs-and-Os?dd=10/04/2026']:
            with self.assertRaises(ValueError):parse_xo_report(xo_fixture(),url)
        with self.assertRaises(ValueError):parse_xo_report(xo_fixture(),'https://nclottery.com/Powerball-Xs-and-Os?dd=10/04/2026',today=date(2026,10,3))

    def test_bounded_reports_reject_old_bad_rows_and_duplicates(self):
        docs=[(f'https://nclottery.com/Powerball-Xs-and-Os?dd=10/0{d}/2026',xo_fixture(d)) for d in [1,3,2]]
        self.assertEqual([r['drawDate'] for r in parse_xo_reports(docs)],['2026-10-03','2026-10-02'])
        with self.assertRaises(ValueError):parse_xo_reports(docs[:1])
        with self.assertRaises(ValueError):parse_xo_reports(docs+docs[:1])
        docs[0]=(docs[0][0],docs[0][1].replace(b'1,810',b'1.5'))
        with self.assertRaises(ValueError):parse_xo_reports(docs)


from north_carolina_draw_reports import parse_powerball_report, parse_powerball_reports


def powerball_fixture():
    return (Path(__file__).resolve().parents[1]/'fixtures/north_carolina/powerball-2026-10-07.html').read_bytes()


class NCPowerballTests(unittest.TestCase):
    def test_variants_and_source_disagreement_preserved(self):
        r=parse_powerball_report(powerball_fixture(),'https://nclottery.com/powerball?dd=10/07/2026')
        base,power,dp=r['variants']
        self.assertEqual([len(v['tiers']) for v in r['variants']],[9,8,9])
        self.assertEqual(base['tiers'][2]['reportedWins'],1)
        self.assertEqual(power['tiers'][1]['reportedWins'],0)
        self.assertEqual(power['multiplierLabel'],'POWER PLAY 2x')
        self.assertEqual(dp['tiers'][3]['matchLabel'],'4')
        self.assertEqual(dp['tiers'][3]['sourceMatchLabel'],'4+PB')
        self.assertEqual(dp['tiers'][3]['reportedWins'],1)
        self.assertEqual(len(r['sourceWarnings']),1)
        self.assertNotIn('totalPayout',r)

    def test_malformed_date_identity_and_values_rejected(self):
        raw=powerball_fixture()
        for before,after in [(b'Wednesday',b'Tuesday'),(b'lblDrawDateDP',b'missingDate'),
            (b'>11</span>',b'>70</span>'),(b'>11</span>',b'>13</span>'),(b'>19</span>',b'>27</span>'),
            (b'2x',b'6x'),(b'lblPay3DP',b'lblPay2DP'),
            (b'$484,800,000',b'$484,80,000'),(b'>7228</span>',b'>-1</span>'),
            (b'North Carolina wins.',b'National wins.'),(b'aria-label="5+PB"',b'aria-label="4+PB"'),(b'</html>',b'')]:
            with self.subTest(before=before),self.assertRaises(ValueError):
                parse_powerball_report(raw.replace(before,after,1),'https://nclottery.com/powerball?dd=10/07/2026')
        with self.assertRaises(ValueError):parse_powerball_report(raw,'https://nclottery.com/powerball?dd=10/05/2026')
        with self.assertRaises(ValueError):parse_powerball_report(raw,'https://nclottery.com/powerball?dd=10/07/2026',today=date(2026,10,6))

    def test_bounded_unique_reports_and_source_label_repair(self):
        raw=powerball_fixture();old=raw.replace(b'Wednesday, Oct 7',b'Monday, Oct 5')
        docs=[('https://nclottery.com/powerball?dd=10/05/2026',old),('https://nclottery.com/powerball?dd=10/07/2026',raw)]
        self.assertEqual([r['drawDate'] for r in parse_powerball_reports(docs)],['2026-10-07','2026-10-05'])
        with self.assertRaises(ValueError):parse_powerball_reports(docs[:1])
        with self.assertRaises(ValueError):parse_powerball_reports(docs+docs[:1])
        from lxml import html,etree
        root=html.fromstring(raw)
        row=root.xpath('//span[@id="ctl00_MainContent_lblPay3DP"]/../..')[0]
        row.xpath('./td')[0].set('aria-label','4')
        self.assertEqual(parse_powerball_report(etree.tostring(root),'https://nclottery.com/powerball?dd=10/07/2026')['sourceWarnings'],[])
        row.xpath('./td')[0].set('aria-label','3')
        with self.assertRaises(ValueError):parse_powerball_report(etree.tostring(root),'https://nclottery.com/powerball?dd=10/07/2026')
