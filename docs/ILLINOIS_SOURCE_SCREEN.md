# Illinois source screen — September 18, 2026

Update September 14: The FOIA office said the original request lacked a time
range and was too broad. A clarification specified August 1–31, 2026 for
existing draw and Scratch reports, available selling-retailer fields and the
current directory, with a request for definitions, normal cadence and a fee
estimate before any paid work. Gmail confirmed “Message sent.”

Update September 18: Mike Beavers supplied 25 official Excel workbooks through
the State of Illinois Microsoft 365 tenant. The complete delivery downloaded
successfully and every workbook opened successfully. The five `DBG paid
winning tickets` parts contain **1,235,948 paid draw-game rows** dated August
1–31, 2026 across Lucky Day Lotto, Lotto, Powerball, HotWins, Pick 3, Mega
Millions and Pick 4. The 20 `IWG winning tickets` parts contain **4,745,780
instant-game winning-ticket rows** dated August 1–31, 2026 across 97 game names
(106 game identifiers).
Together the files contain **5,981,728 official winning-ticket rows**.

Both record groups include game identifiers and names, prize-tier category,
ticket identifier, validation status, prize amount, retailer identifier,
retailer name and full retailer address. Draw records also include draw date
and draw identifier; instant records include validation date. All draw rows
are marked `Paid`; all instant rows are marked `Winner`. The instant set has
16 rows without retailer fields. The draw set has no missing retailer fields;
523,835 draw rows have no prize-tier-category value, primarily where the
source represents the prize through game and prize amount instead. There are
no exact duplicate rows. Some draw ticket identifiers legitimately occur on
multiple distinct rows, so ticket-level totals must use the documented row or
distinct-ticket measure explicitly.

This response supplies the requested August winning-record rows and retailer
fields. Whether those fields identify the selling or validating/paying retailer
still requires an explicit agency definition. It does **not** include the separately requested
current active-retailer directory, data definitions, or normal refresh
cadence. It also does not extend outside the clarified August 1–31 period.
Illinois may support an August activity layer and retailer ranking after the
retailer role and ticket-count definitions are confirmed, followed by address
geocoding and aggregation, but it is not yet a 2026
year-to-date state total. Ticket identifiers are retained only for validation
and deduplication and must not be exposed in the public app.

Illinois is not ready for a 2026 year-to-date state winning-ticket total. The
official [Jackpot & Daily Game Wins](https://www.illinoislottery.com/winning/more-wins)
page lists draw-game tickets over $25,000, not all prizes or all games.
Its retailer field includes online sales and pending validation, and it
explicitly says retailer details appear only after a ticket is validated.
These rows cannot establish a complete statewide retailer count. The
[store locator](https://www.illinoislottery.com/store-locator) is a search
tool; a complete stable retailer export was not established in this screen.

The Lottery's [FOIA instructions](https://www.illinoislottery.com/help-center/foia-requests)
publish `LOT.FOIA@Illinois.gov` and ask requesters to identify commercial
purpose. On September 13, 2026, a written FOIA request was sent to that
address for existing all-tier draw counts, Scratch-Off ticket or claim
counts, retailer records and links, definitions, history and cadence. The
request explicitly disclosed potential commercial use of records in the
public-facing app and asked for fees to be stated before incurring them.
Gmail confirmed “Message sent.” On September 18, Mike Beavers at the Illinois
FOIA office shared the secure OneDrive folder for **FOIA Request 26-226**.
Recipient verification completed and the delivery was validated as described
above. No Illinois records from the delivery have been published yet.

## September 19 preparation and definition follow-up

The reproducible local preparation in `tooling/prepare_illinois_records.py`
processed all 25 workbooks and reconciled all 5,981,728 source rows with no
exact duplicate rows. The 1,235,948 draw rows contain **1,156,949 distinct
(game ID, ticket ID) identifiers**; the 4,745,780 instant rows contain
4,745,780 distinct identifiers. These are separate measures, not a claim of
complete statewide winning-ticket counts. There are 7,446 retailer identifiers
with one address variant each and 4,189,297 aggregate rows grouped by record
type, date, game, tier, prize amount and retailer. The 16 instant rows without
retailer fields remain explicitly unresolved. Five entries named `ILLINOIS
LOTTERY`, associated with 493 source rows, correspond to locations in Chicago,
Des Plaines, Springfield, Rockford and Fairview Heights. The retailer columns
must not be assumed to mean selling locations without agency confirmation.

A reply was sent September 19 to the FOIA office, copying Mike Beavers,
acknowledging successful receipt and asking for the retailer-field role,
row/ticket definitions, treatment of online sales, completeness, extraction
date, corrections, active directory, refresh arrangements and availability of
2026 year-to-date records. No fees were authorized. The response is pending.
Illinois is **not yet ready for map testing**.

The original workbooks remain outside the repository. `work/illinois_source`
is a local convenience link to that delivery; `work/` is Git-ignored. To
rebuild the local preparation with Python 3.11+ and lxml 6.1.1:

```sh
python3 tooling/prepare_illinois_records.py \
  --source-dir work/illinois_source \
  --output work/illinois_august_2026.sqlite \
  --summary work/illinois_august_2026_summary.json
```

The SQLite database stores aggregate rows, retailer addresses and hashed
validation keys, never raw ticket identifiers. It is a private working file,
not a public feed. The JSON summary records source-file SHA-256 checksums,
per-file reconciliation and game-level counts. The source date and August
coverage remain fixed; processing this snapshot does not make it current.
Ten regression tests cover source extraction, dates, invalid fields, duplicate
rows, distinct ticket counting and preservation of previous outputs on failure.
