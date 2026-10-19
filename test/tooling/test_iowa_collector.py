"""Transaction tests; source grammar is covered by the separate parser suites."""
from contextlib import ExitStack
from datetime import datetime, timezone, timedelta
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch
import copy
import unittest
from tooling import collect_iowa_draws as collector

NOW = datetime(2026, 10, 19, 10, 50, tzinfo=timezone.utc)


def rows(group):
    return [dict(group=group, drawDate=day, numbers=[1, 2, 3])
            for day in ['2026-10-18', '2026-10-17']]


class CollectorTest(unittest.TestCase):
    def setUp(self):
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        self.directory = self.stack.enter_context(TemporaryDirectory())
        self.output = Path(self.directory) / 'stage.json'
        self.stack.enter_context(patch.object(collector, 'parse_results', side_effect=lambda raw, group, **kw: rows(group)))
        self.stack.enter_context(patch.object(collector, 'parse_team_results', side_effect=lambda raw, **kw: rows('xsos')))
        self.stack.enter_context(patch.object(collector, 'parse_reports', return_value={}))
        self.stack.enter_context(patch.object(collector, 'verified_chart', side_effect=lambda game, raw: dict(game=game)))
        self.stack.enter_context(patch.object(collector, 'verified_html_schedule', side_effect=lambda game, raw: dict(game=game)))
        self.urls = []
        self.baseline = collector.collect(self.output, fetch=self.fetch, now=NOW)
        self.retained = self.output.read_bytes()

    def fetch(self, url):
        self.urls.append(url)
        return b'public source bytes'

    def test_complete_deduplicated_sources(self):
        self.assertEqual(len(self.baseline['results']), 20)
        self.assertEqual(len(self.urls), 31)
        self.assertEqual(len(set(self.urls)), 31)
        for row in self.baseline['results']:
            if row['group'].startswith('pick'):
                self.assertIsNone(row['report'])
                self.assertIn('unverified', row['reportLimitation'])

    def test_every_request_failure_preserves_bytes(self):
        for failing in self.urls[:]:
            def fetch(url):
                if url == failing:
                    raise OSError('controlled source failure')
                return b'public source bytes'
            with self.assertRaises(OSError):
                collector.collect(self.output, fetch=fetch, now=NOW + timedelta(minutes=1))
            self.assertEqual(self.output.read_bytes(), self.retained)

    def test_parser_failure_and_replace_failure_preserve_bytes(self):
        for function in ['parse_results', 'parse_reports', 'verified_chart', 'verified_html_schedule']:
            with patch.object(collector, function, side_effect=ValueError('changed source')):
                with self.assertRaises(ValueError):
                    collector.collect(self.output, fetch=self.fetch, now=NOW)
            self.assertEqual(self.output.read_bytes(), self.retained)
        with patch.object(collector.os, 'replace', side_effect=OSError('disk failure')):
            with self.assertRaises(OSError):
                collector.collect(self.output, fetch=self.fetch, now=NOW)
        self.assertEqual(self.output.read_bytes(), self.retained)
        self.assertEqual(list(self.output.parent.iterdir()), [self.output])

    def test_corrections_regressions_and_missing_groups_rejected(self):
        for change in ['number', 'report', 'date', 'rule', 'group', 'time']:
            current = copy.deepcopy(self.baseline)
            if change == 'number': current['results'][0]['numbers'] = [9]
            if change == 'report': current['results'][0]['report'] = {'new': 1}
            if change == 'date':
                for row in current['results']: row['drawDate'] = row['drawDate'].replace('2026', '2025')
            if change == 'rule': current['rules'][0]['new'] = 1
            if change == 'group': current['results'].pop()
            if change == 'time': current['retrievedAt'] = (NOW - timedelta(minutes=1)).isoformat()
            with self.assertRaises(ValueError): collector.check_continuity(self.baseline, current)

    def test_calendar_uses_chicago_and_requires_timezone(self):
        with patch.object(collector, 'parse_results', side_effect=lambda raw, group, **kw: rows(group)) as parser:
            collector.collect(Path(self.directory) / 'new.json', fetch=self.fetch,
                              now=datetime(2026, 10, 19, 1, tzinfo=timezone.utc))
            self.assertEqual(str(parser.call_args.kwargs['as_of']), '2026-10-18')
        with self.assertRaises(ValueError):
            collector.collect(self.output, fetch=self.fetch, now=datetime(2026, 10, 19))

    def test_successful_refresh_restores_normal_write(self):
        result = collector.collect(self.output, fetch=self.fetch, now=NOW + timedelta(minutes=1))
        self.assertNotEqual(self.output.read_bytes(), self.retained)
        self.assertEqual(result['results'], self.baseline['results'])
