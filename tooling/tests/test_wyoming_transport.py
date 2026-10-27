import os
import unittest
from unittest.mock import patch
from tooling.collect_wyoming_coverage import official_transport, transport
from tooling.wyoming_coverage import API

class WyomingTransportTests(unittest.TestCase):
    def test_unapproved_host_and_missing_configuration(self):
        for key in (None, '', ' '):
            with self.assertRaises(ValueError):transport(key)
        with self.assertRaises(ValueError):transport('test')('https://example.com/')

    def test_bootstrap_identity_and_no_key_logging(self):
        with patch.dict(os.environ,{},clear=True):
            for script,valid in [(f'GAME_DATA_BASE_URL:"{API}" GAME_DATA_API_KEY:"synthetic"',True),
                                 ('GAME_DATA_BASE_URL:"https://example.com" GAME_DATA_API_KEY:"synthetic"',False),
                                 (f'GAME_DATA_BASE_URL:"{API}"',False)]:
                with patch('tooling.collect_wyoming_coverage.transport') as factory:
                    factory.return_value.return_value=script.encode()
                    if valid:
                        official_transport()
                        self.assertEqual(factory.call_args.args,('synthetic',))
                    else:
                        with self.assertRaises(ValueError) as caught:official_transport()
                        self.assertNotIn('synthetic',str(caught.exception))
