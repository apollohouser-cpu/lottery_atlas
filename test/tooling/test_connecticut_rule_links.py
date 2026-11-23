import unittest
from tooling.connecticut_rule_links import extract


class RuleLinksTest(unittest.TestCase):
    def test_relative_duplicate_navigation_links_are_one_reference(self):
        href = '/sites/default/files/2026-07/Play3-OfficialGameRules-6-10-24.pdf'
        result = extract(f'<a href="{href}">Rules</a>' * 2, 'play3')
        self.assertEqual(result['sourceUrl'], 'https://ctlottery.com' + href)
        self.assertIn('not bundled or validated', result['coverage'])

    def test_foreign_host_and_ambiguous_versions_fail(self):
        path = '/sites/default/files/Play3-OfficialGameRules-1.pdf'
        for html in [f'<a href="https://other.example{path}">Rules</a>',
                     f'<a href="{path}">Rules</a><a href="{path.replace("-1", "-2")}">Rules</a>']:
            with self.assertRaises(ValueError):
                extract(html, 'play3')

    def test_other_product_cannot_supply_missing_rules(self):
        with self.assertRaises(ValueError):
            extract('<a href="/sites/default/files/Play4-OfficialGameRules-1.pdf">Rules</a>', 'play3')
