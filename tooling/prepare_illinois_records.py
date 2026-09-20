"""Prepare the September 18 Illinois FOIA delivery locally, without publishing it.

Read-only XLSX extraction needs lxml. The private SQLite output contains hashed
deduplication keys, aggregate rows, and retailer addresses, never ticket IDs.
No coordinate is inferred and no statewide winning-ticket total is emitted.
"""
import argparse
from collections import Counter
from datetime import date, timedelta
from decimal import Decimal
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import tempfile
import zipfile

from lxml import etree

NS = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
COMMON = ('Game ID', 'Game Name', 'Prize Tier Category', 'Winning Ticket ID',
          'validation_status', 'Prize Amount', 'Retailer ID', 'Retailer Name',
          'Retailer Address', 'Retailer City', 'Retailer Zip Code')
HEADERS = {'DBG': ('Draw Date', 'Draw ID') + COMMON,
           'IWG': ('Validation Date',) + COMMON}
EXPECTED_COUNTS = {'DBG': 1235948, 'IWG': 4745780}


def digest(values):
    return hashlib.sha256(json.dumps(values, separators=(',', ':'),
                                     ensure_ascii=False).encode()).digest()


def clear_element(element):
    element.clear()
    while element.getprevious() is not None:
        del element.getparent()[0]


def xlsx_rows(path, kind):
    """Stream the known official layout, preserving empty cells and text IDs."""
    with zipfile.ZipFile(path) as archive:
        workbook = etree.fromstring(archive.read('xl/workbook.xml'))
        props = workbook.find(NS + 'workbookPr')
        if props is not None and props.get('date1904') in ('1', 'true'):
            raise ValueError('Unexpected 1904 date system')
        sheets = workbook.findall(NS + 'sheets/' + NS + 'sheet')
        expected_sheet = 'DBG paid winning tickets' if kind == 'DBG' else 'IWG winning tickets'
        if len(sheets) != 1 or sheets[0].get('name') != expected_sheet:
            raise ValueError('Unexpected source worksheet layout')
        strings = []
        if 'xl/sharedStrings.xml' in archive.namelist():
            with archive.open('xl/sharedStrings.xml') as stream:
                for _, element in etree.iterparse(stream, events=('end',), tag=NS + 'si'):
                    strings.append(''.join(element.itertext()))
                    clear_element(element)
        with archive.open('xl/worksheets/sheet1.xml') as stream:
            for _, element in etree.iterparse(stream, events=('end',), tag=NS + 'row'):
                row = [''] * len(HEADERS[kind])
                for cell in element:
                    ref = re.match(r'([A-Z]+)', cell.get('r', ''))
                    if ref is None:
                        raise ValueError('Cell has no column reference')
                    column = 0
                    for letter in ref[1]:
                        column = column * 26 + ord(letter) - 64
                    if column > len(row):
                        raise ValueError('Unexpected extra source column')
                    if cell.find(NS + 'f') is not None:
                        raise ValueError('Formulas are not accepted as source records')
                    value = cell.findtext(NS + 'v', '')
                    cell_type = cell.get('t')
                    if cell_type == 's':
                        value = strings[int(value)]
                    elif cell_type == 'inlineStr':
                        value = ''.join(cell.find(NS + 'is').itertext())
                    elif cell_type in ('e', 'b'):
                        raise ValueError('Unexpected error or boolean source cell')
                    row[column - 1] = value
                yield tuple(row)
                clear_element(element)


@lru_cache(maxsize=100)
def source_day(value):
    serial = Decimal(str(value))
    if not serial.is_finite() or serial != serial.to_integral_value():
        raise ValueError('Source date must be a whole Excel date')
    result = (date(1899, 12, 30) + timedelta(days=int(serial))).isoformat()
    if not '2026-08-01' <= result <= '2026-08-31':
        raise ValueError('Source date is outside the delivered August period')
    return result


def integer_id(value, optional=False):
    value = str(value).strip()
    if not value and optional:
        return ''
    if not re.fullmatch(r'\d+', value):
        raise ValueError('Invalid integer identifier')
    return value


def normalize_record(kind, values):
    row = dict(zip(HEADERS[kind], values))
    day = source_day(values[0])
    game_id = integer_id(row['Game ID'])
    game_name = row['Game Name'].strip()
    if not game_name:
        raise ValueError('Missing game name')
    if row['validation_status'] != ('Paid' if kind == 'DBG' else 'Winner'):
        raise ValueError('Unexpected validation status')
    ticket = row['Winning Ticket ID'].strip()
    if not ticket:
        raise ValueError('Missing ticket identifier')
    tier = integer_id(row['Prize Tier Category'], optional=True)
    amount = Decimal(row['Prize Amount']) * 100
    if not amount.is_finite() or amount < 0 or amount != amount.to_integral_value():
        raise ValueError('Invalid prize amount or fractional cent')
    cents = int(amount)
    retailer_id = integer_id(row['Retailer ID'], optional=True)
    retailer = tuple(row[key].strip() for key in
                     ('Retailer Name', 'Retailer Address', 'Retailer City', 'Retailer Zip Code'))
    if retailer_id and (not all(retailer) or not re.fullmatch(r'\d{5}(?:-\d{4})?', retailer[-1])):
        raise ValueError('Incomplete retailer address')
    if not retailer_id and any(retailer):
        raise ValueError('Retailer address without an identifier')
    retailer_key = digest((retailer_id,) + retailer).hex() if retailer_id else ''
    draw_id = integer_id(row['Draw ID']) if kind == 'DBG' else ''
    ticket_hash = digest((kind, game_id, ticket))
    row_hash = digest((kind, day, draw_id, game_id, game_name, tier, ticket,
                       row['validation_status'], cents, retailer_id) + retailer)
    aggregate = (kind, day, game_id, game_name, tier, cents, retailer_key)
    return row_hash, ticket_hash, aggregate, (retailer_key, retailer_id) + retailer


def source_files(source_dir):
    result = []
    for kind, count in [('DBG', 5), ('IWG', 20)]:
        for part in range(1, count + 1):
            # This is the agency's actual filename, not a missing 120-part set.
            denominator = 120 if kind == 'IWG' and part == 11 else count
            path = source_dir / f'{kind} Winning Tickets_part_{part}_of_{denominator}.xlsx'
            if not path.is_file():
                raise ValueError(f'Missing source workbook: {path.name}')
            result.append((kind, path))
    if set(source_dir.glob('*.xlsx')) != {path for _, path in result}:
        raise ValueError('Unexpected XLSX files in delivery directory')
    return result


def prepare(source_dir, output, summary_path):
    files = source_files(source_dir)
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='illinois-prepare-', dir=output.parent) as tmp:
        staging = Path(tmp) / 'records.sqlite'
        db = sqlite3.connect(staging)
        try:
            db.executescript('''
                PRAGMA journal_mode=OFF;
                PRAGMA synchronous=OFF;
                PRAGMA cache_size=-100000;
                CREATE TABLE records(row_hash BLOB PRIMARY KEY, ticket_hash BLOB,
                    kind TEXT, game_id TEXT) WITHOUT ROWID;
                CREATE TABLE activity(kind TEXT, day TEXT, game_id TEXT, game_name TEXT,
                    tier TEXT, prize_cents INTEGER, retailer_key TEXT, source_rows INTEGER,
                    PRIMARY KEY(kind,day,game_id,game_name,tier,prize_cents,retailer_key)) WITHOUT ROWID;
                CREATE TABLE retailers(retailer_key TEXT PRIMARY KEY, retailer_id TEXT,
                    name TEXT, address TEXT, city TEXT, postal_code TEXT) WITHOUT ROWID;
            ''')
            manifest, counts, missing, no_tier = [], Counter(), Counter(), Counter()
            for kind, path in files:
                rows = xlsx_rows(path, kind)
                if next(rows) != HEADERS[kind]:
                    raise ValueError(f'Unexpected headers in {path.name}')
                aggregates, retailers, batch = Counter(), {}, []
                count = 0
                for row_number, row in enumerate(rows, 2):
                    if not any(row):
                        continue
                    try:
                        row_hash, ticket_hash, aggregate, retailer = normalize_record(kind, row)
                    except (ValueError, ArithmeticError) as error:
                        raise ValueError(f'{path.name}, row {row_number}: {error}') from error
                    batch.append((row_hash, ticket_hash, kind, aggregate[2]))
                    aggregates[aggregate] += 1
                    if retailer[0]:
                        retailers[retailer[0]] = retailer
                    else:
                        missing[kind] += 1
                    if not aggregate[4]:
                        no_tier[kind] += 1
                    count += 1
                    if len(batch) == 10000:
                        db.executemany('INSERT INTO records VALUES(?,?,?,?)', batch)
                        batch.clear()
                db.executemany('INSERT INTO records VALUES(?,?,?,?)', batch)
                db.executemany('''INSERT INTO activity VALUES(?,?,?,?,?,?,?,?)
                    ON CONFLICT DO UPDATE SET source_rows=source_rows+excluded.source_rows''',
                    [key + (value,) for key, value in aggregates.items()])
                db.executemany('INSERT OR IGNORE INTO retailers VALUES(?,?,?,?,?,?)', retailers.values())
                db.commit()
                counts[kind] += count
                with path.open('rb') as stream:
                    checksum = hashlib.file_digest(stream, 'sha256').hexdigest()
                manifest.append({'file': path.name, 'sha256': checksum, 'sourceRows': count})
                print(f'Prepared {path.name}: {count:,} rows', flush=True)
            if dict(counts) != EXPECTED_COUNTS:
                raise ValueError(f'Delivery counts do not reconcile: {dict(counts)}')
            games = []
            print('Reconciling aggregate rows and distinct ticket identifiers...', flush=True)
            distinct = {(kind, game): total for kind, game, total in db.execute(
                'SELECT kind, game_id, COUNT(DISTINCT ticket_hash) FROM records GROUP BY kind, game_id')}
            for kind, game, name, total, cents, start, end in db.execute('''
                    SELECT kind,game_id,game_name,SUM(source_rows),
                    SUM(source_rows*prize_cents),MIN(day),MAX(day)
                    FROM activity GROUP BY kind,game_id,game_name ORDER BY kind,game_id'''):
                games.append({'recordType': kind, 'gameId': game, 'game': name,
                    'dateBasis': 'drawDate' if kind == 'DBG' else 'validationDate',
                    'sourceRows': total, 'distinctTicketIdentifiers': distinct[(kind, game)],
                    'prizeAmountCents': cents, 'startDate': start, 'endDate': end})
            if sum(g['sourceRows'] for g in games) != sum(counts.values()):
                raise ValueError('Aggregate totals do not reconcile with source rows')
            ambiguous_games = db.execute('''SELECT kind,game_id FROM activity
                GROUP BY kind,game_id HAVING COUNT(DISTINCT game_name)>1''').fetchall()
            if ambiguous_games:
                raise ValueError('Conflicting names for the same game identifier')
            summary = {
                'source': 'Illinois Lottery FOIA Request 26-226',
                'receivedDate': '2026-09-18', 'periodStart': '2026-08-01', 'periodEnd': '2026-08-31',
                'status': 'prepared locally; geocoding and app integration pending',
                'coverage': 'August delivery only. Paid draw rows use draw date; instant Winner rows '
                    'use validation date. Source rows and distinct ticket identifiers are separate '
                    'measures. No complete 2026 statewide total or refresh cadence is established.',
                'sourceRows': dict(counts), 'rowsWithoutRetailer': dict(missing),
                'rowsWithoutPrizeTier': dict(no_tier), 'exactDuplicateRows': 0,
                'retailerAddressVariants': db.execute('SELECT COUNT(*) FROM retailers').fetchone()[0],
                'retailerIdsWithMultipleAddresses': db.execute('''SELECT COUNT(*) FROM
                    (SELECT retailer_id FROM retailers GROUP BY retailer_id HAVING COUNT(*)>1)''').fetchone()[0],
                'aggregateRows': db.execute('SELECT COUNT(*) FROM activity').fetchone()[0],
                'games': games, 'files': manifest,
            }
            db.execute('CREATE TABLE metadata(summary TEXT)')
            db.execute('INSERT INTO metadata VALUES(?)', (json.dumps(summary),))
            db.commit()
        finally:
            db.close()
        staging.replace(output)
        summary_path.parent.mkdir(parents=True, exist_ok=True)
        summary_path.write_text(json.dumps(summary, indent=2) + '\n')
        print(f'Prepared {sum(counts.values()):,} rows; {summary["retailerAddressVariants"]:,} '
              'retailer address variants require coordinate verification.', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-dir', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--summary', type=Path, required=True)
    args = parser.parse_args()
    prepare(args.source_dir, args.output, args.summary)
