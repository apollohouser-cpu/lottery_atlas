import unittest
from tooling.connecticut_keno_prizes import parse


def fixture():
    tables = []
    for n in range(1, 11):
        cells = lambda values, role: '<div role="row">' + ''.join(f'<div role="{role}"><span>{v}</span></div>' for v in values) + '</div>'
        tables.append(f'<div role="table" aria-label="{n}-Spot Game">' +
            cells(['Match', 'Prize', 'Odds'], 'columnheader') +
            cells([str(n), '$2.50', '1 in 4'], 'cell') + '</div>')
    return ''.join(tables)


class KenoPrizeTest(unittest.TestCase):
    def test_ten_spots_and_decimal_prize_remain_literal(self):
        tables = parse(fixture())
        self.assertEqual(len(tables), 10)
        self.assertEqual(tables[0]['rows'][1], ['1', '$2.50', '1 in 4'])
        self.assertIn('without Bonus', tables[0]['basis'])

    def test_missing_duplicate_and_changed_headers_fail(self):
        for html in [fixture().replace('10-Spot Game', '9-Spot Game'),
                     fixture().replace('Odds', 'Winner counts'),
                     fixture().replace('$2.50', 'unknown')]:
            with self.assertRaises(ValueError): parse(html)
