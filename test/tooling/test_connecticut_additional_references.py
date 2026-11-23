import unittest
from unittest.mock import patch
from tooling.connecticut_additional_references import parse


class AdditionalReferenceTest(unittest.TestCase):
    def test_team_prizes_ignore_script_and_preserve_jackpot(self):
        html = '<script>8 Teams JACKPOT 1 in 9</script>' + ' '.join(
            f'{n} Teams {"JACKPOT" if n == 8 else "$7"} 1 in 15' for n in range(8,3,-1))
        self.assertEqual(parse(html,'xsandos')[0]['rows'][1],['8','JACKPOT','1 in 15'])
        with self.assertRaises(ValueError): parse(html+' 4 Teams $7 1 in 15','xsandos')

    def test_no_bonus_preserved_and_odds_not_counts(self):
        table = {'title':'KENO Bonus Multiplier Odds','rows':[
            ['BONUS MULTIPLIER','NO BONUS','2','3','4','5','10'],
            ['Odds']+['1 in 2.5']*6]}
        with patch('tooling.connecticut_additional_references.Tables') as cls:
            cls.return_value.tables=[table]
            result=parse('', 'keno')[0]
        self.assertEqual(result['rows'][1],['NO BONUS','1 in 2.5'])
        self.assertIn('not winning-ticket counts',result['basis'])
