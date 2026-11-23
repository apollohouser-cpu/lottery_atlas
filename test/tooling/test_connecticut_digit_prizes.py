import unittest
from tooling.connecticut_digit_prizes import Matrices, expand


class DigitMatrixTest(unittest.TestCase):
    def test_row_and_column_spans_preserve_wager_binding(self):
        parser = Matrices()
        parser.feed('<table class="prize-chart-table"><tr><th>Play</th><th>$1</th><th>$2</th></tr>'
                    '<tr><td rowspan="2">Straight<br>or Box</td><td>-</td><td>$3</td></tr>'
                    '<tr><td colspan="2">$4</td></tr></table>')
        self.assertEqual(expand(parser.tables[0]), [
            ['Play','$1','$2'], ['Straight or Box','-','$3'], ['Straight or Box','$4','$4']])

    def test_missing_cells_or_unterminated_spans_reject(self):
        for body in ['<tr><td>one</td></tr>', '<tr><td rowspan="2">one</td><td>two</td></tr>']:
            parser=Matrices();parser.feed('<table class="prize-chart-table"><tr><th>A</th><th>B</th></tr>'+body+'</table>')
            with self.assertRaises(ValueError): expand(parser.tables[0])
