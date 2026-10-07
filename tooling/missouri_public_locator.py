"""Parse bounded official locator results without inventing coordinates or IDs."""
import re
from urllib.parse import urlparse,unquote_plus
from lxml import html
from missouri_scratch_catalog import plain,one


def parse_results(raw):
    if b'</html>' not in raw.lower():raise ValueError('Incomplete locator response')
    tree=html.fromstring(raw)
    table=one(tree.xpath('//table'),'locator results')
    headers=[[plain(c) for c in r.xpath('./th')] for r in table.xpath('./thead/tr')]
    if headers != [['Click on store name for map and driving directions'],['Retailer','Address','City','Games Offered']]:
        raise ValueError('Changed locator columns')
    results=[];identities=set()
    for row in table.xpath('./tbody/tr'):
        cells=row.xpath('./td')
        if len(cells)!=4:raise ValueError('Incomplete retailer row')
        name,address,city=[plain(c) for c in cells[:3]]
        if not all([name,address,city]):raise ValueError('Missing retailer identity')
        link=one(cells[0].xpath('./a'),'directions link').get('href')
        u=urlparse(link)
        marker='https://www.google.com/maps/search/?api=1&query='
        if not link.startswith(marker) or u.path!='/maps/search/':
            raise ValueError('Changed address directions route')
        prefix=f'{name}, {address}, {city} MO '
        # Official hrefs contain unescaped &/# in names; inspect literal suffix,
        # never treat these links as coordinates or navigate a repaired URL.
        value=unquote_plus(link[len(marker):])
        # Source link may retain extra whitespace around a business name.
        normalized=re.sub(r'\s+,', ',', ' '.join(value.split()));prefix=' '.join(prefix.split())+' '
        if not normalized.startswith(prefix):raise ValueError('Directions/address mismatch')
        zipcode=normalized[len(prefix):]
        if not re.fullmatch(r'\d{5}(?:-\d{4})?',zipcode):raise ValueError('Invalid ZIP')
        products=[' '.join(s.split()) for s in cells[3].xpath('./text()') if s.strip()]
        if not products or len(set(products))!=len(products) or not set(products)<={'Draw Games','Scratchers','Keno 2 Go','Club Keno'}:
            raise ValueError('Unknown product labels')
        key=(name,address,city,zipcode)
        if key in identities:raise ValueError('Duplicate locator identity')
        identities.add(key)
        results.append(dict(name=name,address=address,city=city,zip=zipcode,products=products,
                            latitude=None,longitude=None,sourceRetailerId=None))
    if not results:raise ValueError('Empty locator results require explicit handling')
    return results
