"""Stage reviewed SC reports. Remaining games must be integrated before release."""
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import urlopen
from south_carolina_draw_reports import MEGA_SOURCE, XO_SOURCE, PALMETTO_SOURCE, CASH_POP_SOURCE, POWERBALL_SOURCE, parse_powerball, parse_mega_millions, parse_powerball_xo, parse_palmetto, parse_cash_pop


def main():
    output = Path(sys.argv[1])
    reports = []
    for source, parser in [(MEGA_SOURCE, parse_mega_millions), (XO_SOURCE, parse_powerball_xo), (PALMETTO_SOURCE, parse_palmetto), (CASH_POP_SOURCE, parse_cash_pop), (POWERBALL_SOURCE, parse_powerball)]:
        with urlopen(source, timeout=45) as response:
            reports.extend(parser(response.read().decode('utf-8')))
    if output.exists():
        previous = json.loads(output.read_text())
        for game, session in {(r['gameName'], r['drawingSession']) for r in previous['reports']}:
            before = max(r['drawDate'] for r in previous['reports'] if (r['gameName'], r['drawingSession']) == (game, session))
            after = max(r['drawDate'] for r in reports if (r['gameName'], r['drawingSession']) == (game, session))
            if after < before:
                raise ValueError('Draw date regressed: ' + game)
    data = {'state': 'SC', 'retrievedAt': datetime.now(timezone.utc).isoformat(),
            'coverage': 'Mega Millions, Powerball Xs & Os, Palmetto Cash 5 CASH POP and Powerball variant statewide reports; other SC games pending integration.', 'reports': reports}
    temporary = output.with_suffix('.tmp')
    temporary.write_text(json.dumps(data, indent=2) + '\n')
    temporary.replace(output)
    print(f"Validated {len(reports)} draws; latest {reports[0]['drawDate']}: {reports[0]['reportedWinners']} winners")


if __name__ == '__main__':
    main()
