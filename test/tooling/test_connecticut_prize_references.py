import unittest
from tooling.connecticut_prize_references import parse


def fixture():
    rows = [['Match', 'Prize', 'Odds'], ['6', 'JACKPOT*', '1 in 100'],
            ['5', '$2,000*', '1 in 50'], ['4', '$50*', '1 in 10'], ['3', '$2', '1 in 5']]
    return '<div role="table">' + ''.join('<div role="row">'+''.join(
        f'<div role="{("rowheader" if i == 0 else "cell")}">{v}</div>'
        for i,v in enumerate(row))+'</div>' for row in rows)+'</div>'


class ReferenceTest(unittest.TestCase):
    def test_starred_and_jackpot_labels_not_coerced_to_cash(self):
        table = parse(fixture(), 'lotto')[0]
        self.assertEqual(table['rows'][1][1], 'JACKPOT*')
        self.assertEqual(table['rows'][2][1], '$2,000*')
        self.assertIn('can differ', table['basis'])

    def test_changed_and_duplicate_rows_fail(self):
        for html in [fixture().replace('1 in 100', 'unknown'),
                     fixture().replace('>5<', '>6<'), fixture()+fixture()]:
            with self.assertRaises(ValueError): parse(html, 'lotto')
