import json
import unittest
from tooling.connecticut_source_inventory import EXPECTED, draw_inventory


def capture(games, repeat=False):
    text = '19:' + json.dumps({'games': games})
    if repeat:
        text += '\n20:' + json.dumps({'games': games})
    mid = len(text) // 2
    return ''.join('<script>self.__next_f.push(' + json.dumps([1, part]) + ')</script>'
                   for part in [text[:mid], text[mid:]])


class InventoryTest(unittest.TestCase):
    def setUp(self):
        self.games = [dict(apiSlug=s, title=s, detailsUrl='/games/draw-games/'+s,
                           draws='$19:props:data:games:0:latest') for s in sorted(EXPECTED)]

    def test_chunked_source_preserves_unresolved_references(self):
        self.assertEqual(draw_inventory(capture(self.games)), self.games)

    def test_missing_or_duplicate_products_rejected(self):
        for games in [self.games[:-1], self.games + [self.games[0]]]:
            with self.assertRaises(ValueError):
                draw_inventory(capture(games))

    def test_ambiguous_or_missing_inventory_rejected(self):
        for source in [capture(self.games, True), '<html>Unavailable</html>']:
            with self.assertRaises(ValueError):
                draw_inventory(source)

    def test_external_detail_route_rejected(self):
        self.games[0]['detailsUrl'] = 'https://example.org/unverified'
        with self.assertRaises(ValueError):
            draw_inventory(capture(self.games))


if __name__ == '__main__':
    unittest.main()
