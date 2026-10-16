import unittest
from datetime import date
from tooling.nebraska_draw_results import parse_results, SPECS

TODAY = date(2026, 10, 16)


def page(family, values, dates=('10/15/2026', '10/14/2026')):
    heading = 'Powerball Xs & Os' if family == 'Powerball Xs and Os' else 'Nebraska ' + family
    result = f'<div class="ld_left"><h2>{heading}</h2></div>'
    for spec, fields in zip(SPECS[family], values):
        result += '<table><tr>' + ''.join(f'<th>{x}</th>' for x in ['Date'] + spec[1]) + '</tr>'
        for d in dates:
            result += '<tr>' + ''.join(f'<td>{x}</td>' for x in [d] + fields) + '</tr>'
        result += '</table>'
    return result


class NebraskaResultsTest(unittest.TestCase):
    def test_all_families_and_groups(self):
        for family, specs in SPECS.items():
            fields = []
            for _, columns, domains in specs:
                fields.append([''.join(f'<p>{t}</p>' for t in 'ARI DEN DET MIA MIN NYG TEN WAS'.split())] if domains is None else [', '.join(str(low+i) for i in range(n)) for n, low, _, _ in domains])
            dates = ('10/11/2026', '10/04/2026') if family == 'Powerball Xs and Os' else ('10/13/2026', '10/09/2026') if family == 'Mega Millions' else ('10/14/2026', '10/12/2026')
            with self.subTest(family=family):
                parsed = parse_results(page(family, fields, dates), family, today=TODAY)
                self.assertEqual(len(parsed), 2*len(specs))
                self.assertTrue(all('winners' not in r and 'prize' not in r for r in parsed))

    def test_ordered_digits_repetition_and_leading_zero(self):
        out = parse_results(page('Pick 3', [['0, 0, 7']]), 'Pick 3', today=TODAY)
        self.assertEqual(out[0]['fields'][0]['values'], [0, 0, 7])
        self.assertEqual(out[0]['fields'][0]['sourceText'], '0, 0, 7')

    def test_reject_numeric_shape_and_range(self):
        for bad in ['1, 1, 3, 4, 5', '1, 2, 3, 4, 41', '1, 2, 3, 4', '-1, 2, 3, 4, 5', '1.0, 2, 3, 4, 5', '1, 2, 3, 4, 5, 6']:
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                parse_results(page('Pick 5', [[bad]]), 'Pick 5', today=TODAY)

    def test_date_validation(self):
        for dates in [('10/17/2026', '10/15/2026'), ('10/15/2026', '10/15/2026'), ('10/14/2026', '10/15/2026'), ('02/30/2026', '02/28/2026')]:
            with self.subTest(dates=dates), self.assertRaises(ValueError):
                parse_results(page('Pick 3', [['1, 2, 3']], dates), 'Pick 3', today=TODAY)

    def test_calendar_year_zero_and_invalid_dates(self):
        good = page('MyDaY', [['02', '29', '00']])
        self.assertEqual(parse_results(good, 'MyDaY', today=TODAY)[0]['fields'][2]['values'], [0])
        for fields in [['02', '29', '01'], ['04', '31', '24']]:
            with self.assertRaises(ValueError):
                parse_results(page('MyDaY', [fields]), 'MyDaY', today=TODAY)

    def test_group_identity_and_multiplier(self):
        good = page('Powerball', [['1, 2, 3, 4, 5', '1', '3'], ['6, 7, 8, 9, 10', '2']], ('10/14/2026', '10/12/2026'))
        for bad in [good.replace('Double Play White', 'White'), good.replace('<td>3</td>', '<td>6</td>'), good.replace('Nebraska Powerball', 'Nebraska Pick 5'), good+good[good.index('<table>'):]]:
            with self.assertRaises(ValueError):
                parse_results(bad, 'Powerball', today=TODAY)

    def test_teams_not_concatenated_or_unknown(self):
        for value in ['ARIDENDETMIAMINNYGTENWAS', ''.join(f'<p>{x}</p>' for x in 'ARI DEN DET MIA MIN NYG TEN XYZ'.split())]:
            with self.assertRaises(ValueError):
                parse_results(page('Powerball Xs and Os', [[value]], ('10/11/2026', '10/04/2026')), 'Powerball Xs and Os', today=TODAY)

    def test_validate_older_rows_before_bounding(self):
        good = page('Pick 3', [['1, 2, 3']], ('10/15/2026','10/14/2026','10/13/2026'))
        self.assertEqual(len(parse_results(good, 'Pick 3', today=TODAY)), 2)
        with self.assertRaises(ValueError):
            parse_results(good.replace('10/13/2026', '10/16/2026'), 'Pick 3', today=TODAY)


if __name__ == '__main__':
    unittest.main()
