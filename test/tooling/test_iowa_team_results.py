from datetime import date
import unittest
from tooling.iowa_team_results import parse_team_results
TODAY=date(2026,10,19)
def fixture():
    codes=['ARI','DEN','DET','MIA','MIN','NYG','TEN','WAS']
    teams=' - '.join('<img src="/images/game-logos/PBXO_Teams/'+c+'.png" alt="Team '+str(i)+'">' for i,c in enumerate(codes,1))
    return '<table id="colorPBXO"><tr><th>Date</th><th>Teams</th></tr>'+''.join('<tr><td>'+d+'</td><td>'+teams+'</td></tr>' for d in ['10/11/2026','10/4/2026'])+'<tr class="footercolor"><td></td></tr></table>'
class IowaTeamsTest(unittest.TestCase):
    def test_preserves_source_codes_not_alt(self):
        r=parse_team_results(fixture(),as_of=TODAY)
        self.assertEqual(r[0]['teamCodes'],['ARI','DEN','DET','MIA','MIN','NYG','TEN','WAS'])
        self.assertNotIn('numbers',r[0])
    def test_unknown_duplicate_and_external_images(self):
        for a,b in [('ARI.png','ZZZ.png'),('ARI.png','DEN.png'),('/images/','https://example.com/images/'),('Team 1','Team 2')]:
            with self.assertRaises(ValueError):parse_team_results(fixture().replace(a,b),as_of=TODAY)
    def test_missing_image_and_ambiguous_table(self):
        for raw in [fixture().replace('<img','<span',1),fixture()+fixture()]:
            with self.assertRaises(ValueError):parse_team_results(raw,as_of=TODAY)
    def test_date_boundary(self):
        for replacement in ['10/4/2026','10/20/2026','02/21/2026']:
            with self.assertRaises(ValueError):parse_team_results(fixture().replace('10/11/2026',replacement),as_of=TODAY)
