"""Collect Wyoming with caller-provided public-site API credential; never log it."""
import argparse
import os
from urllib.parse import urlparse
from urllib.request import Request, urlopen
from tooling.wyoming_coverage import API, refresh


def transport(key):
    if not isinstance(key, str) or not key.strip():
        raise ValueError('Missing Wyoming public-site transport configuration')
    def fetch(url):
        host = urlparse(url).hostname
        if host not in ('wyolotto.com', 'images.ctfassets.net', urlparse(API).hostname):
            raise ValueError('Unapproved Wyoming source host')
        headers = {'User-Agent': 'LotteryAtlas/1.0'}
        if host == urlparse(API).hostname:
            headers.update({'X-API-Key': key, 'X-Client-ID': 'product-portal-server'})
        # Do not allow credential-bearing requests to redirect to another host.
        from urllib.request import HTTPRedirectHandler, build_opener
        class NoRedirect(HTTPRedirectHandler):
            def redirect_request(self, req, fp, code, msg, hdrs, newurl):
                raise ValueError('Source redirect requires review')
        with build_opener(NoRedirect).open(Request(url, headers=headers), timeout=40) as response:
            return response.read()
    return fetch


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    data = refresh(args.output, transport(os.environ.get('WYOMING_GAME_DATA_API_KEY')))
    print(f"Validated Wyoming: {len(data['results'])} results; {len(data['rules'])} rule contracts")
