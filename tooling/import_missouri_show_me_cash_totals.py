"""Refresh a clearly scoped Missouri Show Me Cash draw-ticket count."""

import json
import sys
import urllib.request
import xml.etree.ElementTree as ET
from datetime import date, datetime, timedelta
from io import BytesIO
from pathlib import Path
from zipfile import ZipFile


SOURCE_URL = "https://www.molottery.com/show-me-cash/past-winning-numbers.do?order=desc"
NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
TIERS = ("5of5", "4of5", "3of5", "2of5")
START = date(2026, 1, 1)


def workbook_rows(raw):
    with ZipFile(BytesIO(raw)) as archive:
        strings = []
        if "xl/sharedStrings.xml" in archive.namelist():
            root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
            strings = [
                "".join(node.itertext()) for node in root.findall("m:si", NS)
            ]
        sheet = ET.fromstring(archive.read("xl/worksheets/sheet1.xml"))
        for row in sheet.findall(".//m:sheetData/m:row", NS):
            cells = {}
            for cell in row.findall("m:c", NS):
                value = cell.find("m:v", NS)
                if value is None:
                    continue
                column = "".join(ch for ch in cell.attrib["r"] if ch.isalpha())
                cells[column] = (
                    strings[int(value.text)] if cell.get("t") == "s" else value.text
                )
            yield cells


def refresh(path):
    request = urllib.request.Request(SOURCE_URL, headers={"User-Agent": "LotteryAtlas/1.0"})
    with urllib.request.urlopen(request, timeout=30) as response:
        raw = response.read()
    rows = list(workbook_rows(raw))
    if len(rows) < 3 or [rows[1].get(col) for col in "ABCDEFGHI"] != [
        "Draw Date", "Draw Time", "Numbers As Drawn", "Numbers In Order",
        "Jackpot", *TIERS,
    ]:
        raise ValueError("Unexpected Show Me Cash workbook columns")

    counts = {}
    for row in rows[2:]:
        if not row.get("A"):
            continue
        day = datetime.strptime(row["A"], "%d-%b-%y").date()
        if day < START:
            continue
        if day > date.today() or day in counts or row.get("B", "").lower() != "evening":
            raise ValueError(f"Unexpected or duplicate draw: {day}")
        values = [row.get(col) for col in "FGHI"]
        if any(value is None or not value.isdecimal() for value in values):
            raise ValueError(f"Missing or noninteger tier count: {day}")
        counts[day] = sum(int(value) for value in values)

    if not counts:
        raise ValueError("No 2026 Show Me Cash draws")
    latest = max(counts)
    expected = {START + timedelta(days=offset) for offset in range((latest - START).days + 1)}
    if set(counts) != expected:
        raise ValueError("Missing or noncontinuous year-to-date draw dates")

    payload = json.loads(path.read_text())
    if not isinstance(payload.get("totals"), list):
        raise ValueError("Missing totals list")
    existing = next((row for row in payload["totals"] if row.get("state") == "MO"), None)
    result = {
        "state": "MO",
        "winningTickets": sum(counts.values()),
        "periodStart": START.isoformat(),
        "periodEnd": latest.isoformat(),
        "sourceDate": date.today().isoformat(),
        "sourceUrl": SOURCE_URL,
        "coverage": "Show Me Cash draw tickets sold in Missouri, 5-of-5 through 2-of-5 tiers only; excludes all other draw games and Scratchers. No retailer locations verified by this count.",
    }
    if existing and existing["winningTickets"] == result["winningTickets"] and existing["periodEnd"] == result["periodEnd"]:
        return result, False
    payload["totals"] = [row for row in payload["totals"] if row.get("state") != "MO"] + [result]
    payload["totals"].sort(key=lambda row: row["state"])
    path.write_text(json.dumps(payload, indent=2) + "\n")
    return result, True


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: import_missouri_show_me_cash_totals.py totals.json")
    result, changed = refresh(Path(sys.argv[1]))
    print(f"Missouri Show Me Cash: {result['winningTickets']} through {result['periodEnd']}; changed={changed}")
