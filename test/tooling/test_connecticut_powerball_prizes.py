import unittest
from unittest.mock import patch
from tooling.connecticut_powerball_prizes import parse


def tables():
    base = [['Match', 'Powerball Prize', 'Double PlayPrize', 'Odds']]
    power = [['Match', '2XPrize', '3XPrize', '4XPrize', '5XPrize', '10XPrize']]
    for n in range(9):
        base.append([str(n), 'JACKPOT' if n == 0 else '$4', '$7', '1 in 39'])
        power.append([str(n), 'Power Play does not multiply jackpot amount'] if n == 0 else
                     [str(n), '$2 MILLION'] if n == 1 else [str(n)] + ['$8']*5)
    return [{'rows': base}, {'rows': power}]


class PowerballPrizeTest(unittest.TestCase):
    def test_spanning_exceptions_separate_and_all_multiplier_columns_retained(self):
        with patch('tooling.connecticut_powerball_prizes.Tables') as cls:
            cls.return_value.tables = tables()
            result = parse('fixture')
        self.assertEqual(len(result), 3)
        self.assertEqual(result[1]['rows'][2][1], '$2 MILLION')
        self.assertEqual(len(result[2]['rows'][1]), 6)
        self.assertIn('Double Play', result[0]['title'])

    def test_changed_exception_and_misaligned_columns_fail(self):
        for change in [lambda t: t[1]['rows'][2].__setitem__(1, '$3 MILLION'),
                       lambda t: t[1]['rows'][3].pop()]:
            data = tables(); change(data)
            with patch('tooling.connecticut_powerball_prizes.Tables') as cls:
                cls.return_value.tables = data
                with self.assertRaises(ValueError): parse('fixture')
