"""Collect Wyoming with caller-provided public-site API credential; never log it."""
import argparse
import os
import re
from urllib.parse import urlparse
from urllib.request import Request
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


def official_transport():
    """Read the public site's client configuration without persisting its key."""
    # The configured override is optional; no secret is embedded in the repo.
    key = os.environ.get('WYOMING_GAME_DATA_API_KEY')
    if key:
        return transport(key)
    public_fetch = transport('bootstrap-unused-for-site-host')
    script = public_fetch('https://wyolotto.com/index.js').decode('utf-8')
    roots = set(re.findall(r'GAME_DATA_BASE_URL:"([^"\n]+)"', script))
    keys = set(re.findall(r'GAME_DATA_API_KEY:"([^"\n]+)"', script))
    if roots != {API} or len(keys) != 1:
        raise ValueError('Public Wyoming transport configuration changed')
    return transport(keys.pop())


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    data = refresh(args.output, official_transport())
    print(f"Validated Wyoming: {len(data['results'])} results; {len(data['rules'])} rule contracts")
