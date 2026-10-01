"""Stage reviewed SC reports. Remaining games must be integrated before release."""
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import urlopen
from south_carolina_draw_reports import MEGA_SOURCE, parse_mega_millions


def main():
    output = Path(sys.argv[1])
    with urlopen(MEGA_SOURCE, timeout=45) as response:
        reports = parse_mega_millions(response.read().decode('utf-8'))
    if output.exists():
        previous = json.loads(output.read_text())
        if reports[0]['drawDate'] < previous['reports'][0]['drawDate']:
            raise ValueError('Draw date regressed')
    data = {'state': 'SC', 'retrievedAt': datetime.now(timezone.utc).isoformat(),
            'coverage': 'Mega Millions statewide reports only; other SC games pending integration.', 'reports': reports}
    temporary = output.with_suffix('.tmp')
    temporary.write_text(json.dumps(data, indent=2) + '\n')
    temporary.replace(output)
    print(f"Validated {len(reports)} draws; latest {reports[0]['drawDate']}: {reports[0]['reportedWinners']} winners")


if __name__ == '__main__':
    main()
