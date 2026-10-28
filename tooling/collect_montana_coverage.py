"""Collect reviewed public Montana sources without redirect or status fallbacks."""
import argparse
import subprocess
from tooling.montana_coverage import refresh, source_urls


def official_fetch(url):
    if url not in source_urls():
        raise ValueError('Unreviewed Montana source URL')
    response = subprocess.run(['curl', '--silent', '--show-error', '--max-time', '45',
                               '--write-out', '%{http_code}', url], capture_output=True, check=True)
    if response.stdout[-3:] != b'200':
        raise ValueError('Montana source HTTP status requires review')
    return response.stdout[:-3]


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    data = refresh(args.output, official_fetch)
    print(f"Validated Montana: {len(data['results'])} results, {len(data['sources'])} sources, collected {data['updatedAt']}")
