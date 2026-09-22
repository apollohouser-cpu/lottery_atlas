"""Stage Census batch address matches for review; never publish retailer pins."""
import argparse
from collections import Counter
import csv
import hashlib
import json
import math
from pathlib import Path
import re


def in_ring(point, ring):
    x, y = point
    inside = False
    for a, b in zip(ring, ring[1:] + ring[:1]):
        x1, y1 = a[:2]; x2, y2 = b[:2]
        cross = (x-x1)*(y2-y1) - (y-y1)*(x2-x1)
        if abs(cross) < 1e-9 and min(x1,x2)-1e-9 <= x <= max(x1,x2)+1e-9 and min(y1,y2)-1e-9 <= y <= max(y1,y2)+1e-9:
            return True
        if (y1 > y) != (y2 > y) and x < (x2-x1)*(y-y1)/(y2-y1)+x1:
            inside = not inside
    return inside


def county_candidates(point, features, state_fips):
    names = []
    for feature in features:
        if feature['properties']['STATEFP'] != state_fips:
            continue
        geometry = feature['geometry']
        if geometry['type'] not in ('Polygon', 'MultiPolygon'):
            raise ValueError('Unsupported county geometry')
        polygons = [geometry['coordinates']] if geometry['type'] == 'Polygon' else geometry['coordinates']
        if any(in_ring(point,p[0]) and not any(in_ring(point,h) for h in p[1:]) for p in polygons):
            names.append(feature['properties']['GEOID'])
    return names


def audit(retailers, rows, features, state_code, state_fips):
    expected = {}
    for retailer in retailers:
        rid = retailer['id']
        if not isinstance(rid,str) or not rid or rid in expected:
            raise ValueError('Invalid or duplicate retailer ID')
        if retailer['stateCode'] != state_code or retailer.get('requiresAddressReview'):
            raise ValueError('Input includes an excluded address')
        expected[rid] = retailer
    if not expected:
        raise ValueError('Empty address batch')
    seen = set(); result = []
    for row in rows:
        if len(row) not in (3,8) or row[0] not in expected or row[0] in seen:
            raise ValueError('Malformed, duplicate, or unexpected result ID')
        rid = row[0]; seen.add(rid); source = expected[rid]
        original = ', '.join(source[k] for k in ('address','city','stateCode','zip'))
        if row[1] != original:
            raise ValueError('Returned input address differs from submitted source')
        record = dict(retailerId=rid,sourceAddress=original,matchStatus=row[2],publishable=False)
        if row[2] in ('No_Match','Tie'):
            if len(row) != 3:
                raise ValueError('Unexpected fields for unmatched address')
            record['reviewReasons'] = ['no_unique_match']
        elif row[2] == 'Match':
            if len(row) != 8 or row[3] not in ('Exact','Non_Exact'):
                raise ValueError('Malformed match')
            coords = row[5].split(',')
            if len(coords) != 2:
                raise ValueError('Malformed coordinate pair')
            x,y = map(float,coords)
            if not all(math.isfinite(v) for v in (x,y)) or not -180 <= x <= 180 or not -90 <= y <= 90 or x == 0 or y == 0:
                raise ValueError('Invalid coordinates')
            if not row[6].isdigit() or row[7] not in ('L','R'):
                raise ValueError('Invalid Census segment reference')
            parts = [p.strip() for p in row[4].rsplit(',',3)]
            if len(parts) != 4:
                raise ValueError('Malformed matched address')
            reasons = []
            if row[3] != 'Exact': reasons.append('non_exact_match')
            if parts[2] != state_code: reasons.append('matched_state_differs')
            if parts[3][:5] != source['zip'][:5]: reasons.append('matched_zip_differs')
            source_number = re.match(r'^\d+[A-Za-z]?(?:-\d+)?\b',source['address'])
            matched_number = re.match(r'^\d+[A-Za-z]?(?:-\d+)?\b',parts[0])
            if not source_number or not matched_number or source_number[0].upper() != matched_number[0].upper():
                reasons.append('house_number_differs_or_unverified')
            counties = county_candidates((x,y),features,state_fips)
            if len(counties) != 1: reasons.append('county_not_unique')
            record.update(matchType=row[3],matchedAddress=row[4],longitude=x,latitude=y,tigerLineId=row[6],side=row[7],countyCandidates=counties,coordinateMethod='Census address-range interpolation; not a verified store entrance',reviewReasons=reasons)
        else:
            raise ValueError('Unknown match status')
        record['addressCandidate'] = not record['reviewReasons']
        result.append(record)
    if seen != set(expected):
        raise ValueError('Incomplete batch response')
    return sorted(result,key=lambda r:r['retailerId'])


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('directory',type=Path);p.add_argument('response',type=Path)
    p.add_argument('counties',type=Path);p.add_argument('output',type=Path)
    p.add_argument('--state-code',required=True);p.add_argument('--state-fips',required=True)
    p.add_argument('--retrieved-at',required=True)
    args=p.parse_args()
    directory=json.loads(args.directory.read_text())
    source=directory['retailers']
    eligible=[r for r in source if r['stateCode']==args.state_code and not r.get('requiresAddressReview')]
    with args.response.open(newline='') as f:rows=list(csv.reader(f))
    result=audit(eligible,rows,json.loads(args.counties.read_text())['features'],args.state_code,args.state_fips)
    report=dict(source='https://geocoding.geo.census.gov/geocoder/locations/addressbatch',benchmark='Public_AR_Current',retrievedAt=args.retrieved_at,directorySourceDate=directory['sourceDate'],sourceFileHashes={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in (args.directory,args.response,args.counties)},excludedSourceIds=[r['id'] for r in source if r not in eligible],submitted=len(eligible),matchStatuses=dict(Counter(r['matchStatus'] for r in result)),matchTypes=dict(Counter(r.get('matchType') for r in result if r['matchStatus']=='Match')),addressCandidates=sum(r['addressCandidate'] for r in result),reviewReasons=dict(Counter(reason for r in result for reason in r['reviewReasons'])),publicationStatus='Staging only: interpolated address candidates are not verified store pins or winning activity',retailers=result)
    args.output.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k not in ('retailers','sourceFileHashes')},indent=2))

if __name__=='__main__':main()
