import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('refresh_states', ROOT / 'tooling/refresh_states.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class RefreshStatesTest(unittest.TestCase):
    def test_failure_rolls_back_entire_state_and_other_state_advances(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            original = b'{"date":"2026-09-01","value":1}\n'
            for name in ['a.json', 'b.json', 'c.json']:
                (root / name).write_bytes(original)
            jobs = [dict(state='First', outputs=['a.json', 'b.json'], commands=[['tool','first'],['tool','fail'],['tool','skip']]),
                    dict(state='Second', outputs=['c.json'], commands=[['tool','second']])]
            seen = []
            def run(command, **kwargs):
                seen.append(command[1])
                if command[1] == 'first': (root/'a.json').write_text('{"new":true}')
                if command[1] == 'fail': (root/'b.json').write_text('partial corrupt write')
                if command[1] == 'second': (root/'c.json').write_text('{"new":true}')
                return subprocess.CompletedProcess(command, 1 if command[1] == 'fail' else 0)
            result, fatal = m.refresh(jobs, root, run)
            self.assertFalse(fatal)
            self.assertEqual(seen, ['first','fail','second'])
            self.assertEqual((root/'a.json').read_bytes(), original)
            self.assertEqual((root/'b.json').read_bytes(), original)
            self.assertEqual(result[0]['status'], 'retained_after_failure')
            self.assertEqual(result[1]['status'], 'updated')

    def test_timeout_without_baseline_blocks_publish_and_removes_partial_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            def run(command, **kwargs):
                (root/'new.json').write_text('{}')
                raise subprocess.TimeoutExpired(command, 1200)
            _, fatal = m.refresh([dict(state='New',outputs=['new.json'],commands=[['tool','slow']])],root,run)
            self.assertTrue(fatal)
            self.assertFalse((root/'new.json').exists())

    def test_zero_exit_with_bad_json_restores_baseline(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);(root/'a.json').write_text('{}')
            def run(command, **kwargs):
                (root/'a.json').write_text('broken')
                return subprocess.CompletedProcess(command,0)
            rows,fatal=m.refresh([dict(state='A',outputs=['a.json'],commands=[['tool','bad']])],root,run)
            self.assertFalse(fatal);self.assertEqual((root/'a.json').read_text(),'{}')
            self.assertEqual(rows[0]['status'],'retained_after_failure')

    def test_manifest_owns_each_output_once_and_commands_reference_owned_data(self):
        jobs=json.loads((ROOT/'tooling/state_refresh_jobs.json').read_text())
        self.assertEqual(len(jobs),29)
        outputs=[p for j in jobs for p in j['outputs']]
        self.assertEqual(len(outputs),len(set(outputs)))
        for job in jobs:
            for p in job['outputs']:
                self.assertTrue((ROOT/p).is_file(),p)
            for command in job['commands']:
                for arg in command:
                    if arg.startswith('data/') and arg.endswith('.json'):
                        self.assertIn(arg,job['outputs'])

if __name__ == '__main__': unittest.main()
