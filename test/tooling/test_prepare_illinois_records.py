import importlib.util
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest.mock import patch
import zipfile

MODULE_PATH = Path(__file__).resolve().parents[2] / 'tooling/prepare_illinois_records.py'
SPEC = importlib.util.spec_from_file_location('illinois', MODULE_PATH)
il = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(il)


def source_row(kind='DBG', **changes):
    row = {
        'Draw Date': '46235', 'Validation Date': '46235', 'Draw ID': '10',
        'Game ID': '1', 'Game Name': 'Example', 'Prize Tier Category': '2',
        'Winning Ticket ID': 'PRIVATE-TICKET-001', 'validation_status': 'Paid' if kind == 'DBG' else 'Winner',
        'Prize Amount': '5.50', 'Retailer ID': '0001', 'Retailer Name': 'Example Store',
        'Retailer Address': '1 Main St', 'Retailer City': 'Chicago', 'Retailer Zip Code': '60601',
    }
    row.update(changes)
    return tuple(row[h] for h in il.HEADERS[kind])


class IllinoisPreparationTest(unittest.TestCase):
    def test_xlsx_sparse_cells_and_shared_strings(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'fixture.xlsx'
            with zipfile.ZipFile(path, 'w') as archive:
                archive.writestr('xl/workbook.xml',
                    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
                    '<sheets><sheet name="DBG paid winning tickets"/></sheets></workbook>')
                archive.writestr('xl/sharedStrings.xml',
                    '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
                    '<si><t>Leading 001</t></si></sst>')
                archive.writestr('xl/worksheets/sheet1.xml',
                    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
                    '<sheetData><row r="1"><c r="A1"><v>46235</v></c>'
                    '<c r="C1" t="s"><v>0</v></c>'
                    '<c r="M1" t="inlineStr"><is><t>60601</t></is></c>'
                    '</row></sheetData></worksheet>')
            row = next(il.xlsx_rows(path, 'DBG'))
            self.assertEqual(len(row), 13)
            self.assertEqual(row[:3], ('46235', '', 'Leading 001'))
            self.assertEqual(row[-1], '60601')

    def test_xlsx_formula_cells_fail(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'fixture.xlsx'
            with zipfile.ZipFile(path, 'w') as archive:
                archive.writestr('xl/workbook.xml',
                    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
                    '<sheets><sheet name="IWG winning tickets"/></sheets></workbook>')
                archive.writestr('xl/worksheets/sheet1.xml',
                    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
                    '<sheetData><row><c r="A1"><f>1+1</f><v>2</v></c></row></sheetData></worksheet>')
            with self.assertRaisesRegex(ValueError, 'Formulas'):
                list(il.xlsx_rows(path, 'IWG'))

    def test_period_boundaries(self):
        self.assertEqual(il.source_day('46235'), '2026-08-01')
        self.assertEqual(il.source_day('46265'), '2026-08-31')
        for value in ['46234', '46266', '46235.5', 'NaN']:
            with self.assertRaises(ValueError):
                il.source_day(value)

    def test_distinct_draw_rows_keep_one_ticket_hash(self):
        first = il.normalize_record('DBG', source_row())
        second = il.normalize_record('DBG', source_row(**{'Draw ID': '11'}))
        self.assertNotEqual(first[0], second[0])
        self.assertEqual(first[1], second[1])
        self.assertEqual(first[2], second[2])
        self.assertEqual(first[2][5], 550)
        self.assertNotIn('PRIVATE-TICKET', str(first))

    def test_ticket_hash_is_scoped_to_game_and_record_type(self):
        first = il.normalize_record('DBG', source_row())[1]
        self.assertNotEqual(first, il.normalize_record('DBG', source_row(**{'Game ID': '2'}))[1])
        self.assertNotEqual(first, il.normalize_record('IWG', source_row('IWG'))[1])

    def test_prize_tier_may_be_unavailable_without_becoming_zero(self):
        self.assertEqual(il.normalize_record('DBG', source_row(**{'Prize Tier Category': ''}))[2][4], '')

    def test_missing_retailer_is_explicit(self):
        changes = {k: '' for k in il.COMMON if k.startswith('Retailer')}
        self.assertEqual(il.normalize_record('IWG', source_row('IWG', **changes))[2][-1], '')

    def test_invalid_fields_fail(self):
        for changes in [{'Prize Amount': '-1'}, {'Prize Amount': '1.001'},
                        {'Prize Amount': 'NaN'}, {'validation_status': 'Pending'},
                        {'Winning Ticket ID': ''}, {'Retailer City': ''},
                        {'Retailer Zip Code': 'unknown'}, {'Game ID': '1.2'},
                        {'Retailer ID': ''}]:
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                il.normalize_record('DBG', source_row(**changes))

    def test_aggregate_reconciliation_and_private_ids(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            files = [('DBG', root / 'draw.xlsx'), ('IWG', root / 'instant.xlsx')]
            for _, file in files:
                file.write_bytes(b'fixture source bytes')
            data = {'DBG': [source_row(), source_row(**{'Draw ID': '11'})],
                    'IWG': [source_row('IWG')]}
            def rows(_path, kind):
                return iter([il.HEADERS[kind]] + data[kind])
            with patch.object(il, 'source_files', return_value=files), \
                 patch.object(il, 'xlsx_rows', side_effect=rows), \
                 patch.object(il, 'EXPECTED_COUNTS', {'DBG': 2, 'IWG': 1}):
                output, summary = root / 'out.sqlite', root / 'summary.json'
                il.prepare(root, output, summary)
                report = json.loads(summary.read_text())
                self.assertEqual(report['sourceRows'], {'DBG': 2, 'IWG': 1})
                self.assertEqual(report['games'][0]['distinctTicketIdentifiers'], 1)
                self.assertEqual(report['games'][0]['sourceRows'], 2)
                with sqlite3.connect(output) as db:
                    self.assertEqual(db.execute('SELECT SUM(source_rows) FROM activity').fetchone()[0], 3)
                self.assertNotIn(b'PRIVATE-TICKET', output.read_bytes())
                self.assertNotIn('PRIVATE-TICKET', summary.read_text())
                old_db, old_report = output.read_bytes(), summary.read_bytes()
                # Duplicate rows in the source must fail, leaving prior outputs intact.
                data['DBG'][1] = data['DBG'][0]
                with self.assertRaises(sqlite3.IntegrityError):
                    il.prepare(root, output, summary)
                self.assertEqual(output.read_bytes(), old_db)
                self.assertEqual(summary.read_bytes(), old_report)

    def test_missing_parts_fail_before_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaisesRegex(ValueError, 'Missing source workbook'):
                il.source_files(Path(tmp))


if __name__ == '__main__':
    unittest.main()
