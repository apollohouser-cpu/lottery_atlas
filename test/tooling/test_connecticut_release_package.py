import hashlib
import json
import unittest
from tooling.package_connecticut_release import package


class ReleasePackageTest(unittest.TestCase):
    def fixture(self):
        return dict(schemaVersion=1,stateCode='CT',productionReady=False,
            recordType='private development candidate',observedDate='2026-11-22',
            draws=[{}]*12,reports=[{}]*9,ruleReferences=[{}]*9,
            scratchCatalog={'games':[]},scratchCatalogSha256='fixture',
            evidence=[{'privatePath':'work/fixture'}],limitations=['Development only'])

    def encode(self,p):
        raw=json.dumps(p).encode();return package(raw,hashlib.sha256(raw).hexdigest())

    def test_projection_omits_private_evidence_not_original_observation_date(self):
        p=json.loads(self.encode(self.fixture()))
        self.assertNotIn('evidence',p)
        self.assertEqual(p['observedDate'],'2026-11-22')
        self.assertTrue(p['productionReady'])
        self.assertNotIn('Development only',p['limitations'])

    def test_nested_private_data_and_unreviewed_bytes_rejected(self):
        for key,value in [('privatePath','secret'),('sourceUrl','https://example.com/a'),('note','work/private')]:
            p=self.fixture();p['draws'][0]={key:value}
            with self.assertRaises(ValueError):self.encode(p)
        with self.assertRaises(ValueError):package(b'{}','0'*64)
