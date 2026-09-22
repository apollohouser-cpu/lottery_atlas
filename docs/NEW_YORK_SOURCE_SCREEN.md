# New York source screen — September 14, 2026

The Gaming Commission's [Daily Numbers/Win-4 open dataset](https://data.ny.gov/d/hsys-3def)
lists statewide drawing results and describes a daily posting frequency.
Winning numbers and draw dates are not counts of tickets that won at every
prize tier. Its dataset metadata lists `Info@gaming.ny.gov` as a Commission
contact. The [official Scratch-Off game page](https://nylottery.ny.gov/scratch-off-game/)
lists games, printed top prizes, top prizes remaining and deadlines; it does
not establish claims or winning-ticket totals across all prize tiers.

The [retailer locator](https://nylottery.ny.gov/find-a-retailer/) displayed
13,060 locations when screened, but a complete machine-readable active
directory with stable IDs and a join from each winning ticket was not
verified. Existing New York winner activity in Lottery Atlas is a scoped
subset and cannot be promoted to a complete statewide total or ranking.

On September 14, an email data and FOIL-routing inquiry was sent to the
Commission contact from the official open-data metadata. It requests
existing all-tier draw counts, Scratch claims/remaining, retailer records,
definitions, cadence, corrections and any fees. Gmail confirmed “Message
sent.” This is not a confirmed formal FOIL filing. No complete count or
retailer-linked source is verified; New York is not ready for full-state
testing.

On September 15, the Commission replied that these records require a formal
FOIL request through its official GovQA Records Access Center. A requester
account was created and the formal request was submitted on September 16,
2026. The portal assigned reference `R000200-091626` and acknowledged receipt.
It requests the most recent complete 12-month period of all-tier draw and
Scratch-Off records, retailer records and joins, definitions, cadence,
corrections and any existing recurring source, with a fallback to the most
recent complete month. The Commission said it will provide a status update by
October 15, 2026. No fees were authorized.

## September 22 FOIL response — R000200-091626

The Commission sent its fulfillment response at 13:50 UTC, before the previously
promised October 15 status date. It says a responsive document is available in
the records center and that it maintains prize data only for **$600 or more**.
It directs the retailer-directory portion to the State of New York public
retailer dataset. The response closes the request and describes a 30-day appeal
option. No appeal or paid work has been authorized. This is a limited records
offer, not an all-tier delivery or a blanket denial.

The records link was opened but requires portal sign-in. The offered file has
not yet been downloaded or validated; its actual period, fields, retailer joins,
and row count are unknown. A same-thread reply requested the existing document
by attachment or a direct link without login, with no additional compilation or
paid work. Gmail confirmed that reply as `1a0c98ab2e4ebe5b`. Monitor for the file;
do not add it to verified delivery totals or publish an activity layer before
inspection. Existing public catalog, retailer and scoped winner feeds remain
available with their existing limitations.

### Responsive workbook received and inspected

At 15:08 UTC September 22, Robin McFee emailed the requested workbook directly.
This resolves the download obstacle above without a user login. The original is
retained privately at `work/new_york_records/winning_claims.xlsx`, SHA-256
`336276b6473a5dae1d92aaadc26a6c26da0663ccffd077c640e88b3c2eae37cd`.
New York is now the third agency to deliver a directly inspectable dataset,
after Illinois and Rhode Island; that is not a count of full-state-ready layers.

The single sheet, `Claimed $600 or More`, has **159,140 data rows** with claim dates
from **September 1, 2025 through August 31, 2026**, covering all 365 dates. Fields:
CLAIM DATE, GAME, PRIZE AMT, SELLING AGENT, BUSINESS NAME, ADDRESS, CITY1. All prize
amounts are at least $600. There are 12,004 distinct selling-agent field values
and 128 rows missing both address and city. There is no ticket/claim identifier,
Scratch game number, drawing date, ZIP, county, coordinate, correction field or
separate data dictionary. All twelve calendar months are represented.

There are **13,944 identical-row groups**, containing **31,815 repetitions beyond
the first row**. These have been retained: different tickets can share all seven
fields. Do not deduplicate these rows or label the row total a verified distinct
winning-ticket count. Annuity/full-prize/payment meaning also remains unconfirmed.
The raw workbook and audit JSON remain outside the public repository.

A conservative comparison to the current official retailer directory found
152,667 rows matching numeric agent ID, address and city after case/punctuation
normalization; 5,753 rows have an agent absent from today's directory; 695 match
an ID but need address/city review; 25 have an invalid/nonpositive agent ID.
These categories partition all rows. The matching rows are only candidates:
current IDs/addresses do not establish the historical selling location. No fuzzy
or nearest-location matches were made. No claim rows or new map points are public.

A reply to McFee (Gmail `1a0c9c1b731e154d`) asks for existing definitions of row
identity, repeated rows, claim dates, prize amounts, stable selling-agent IDs and
historical addresses, plus existing Scratch IDs and correction/update information.
It authorizes no fees or new paid compilation. Continue independent preparation
while awaiting clarification. New York's app notice now explicitly discloses the
Commission's $600 threshold; existing verified public feeds remain available.
