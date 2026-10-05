# Oregon source screen — September 12, 2026

Oregon is **not yet approved for the launch heat map**. Keep the existing Oregon
importers and initial catalog; do not add Oregon to the approved activity feed
until the winner-location source gate passes.

- The official retailer API used by `tooling/import_oregon_retailer_directory.mjs`
  returned 3,761 active retailer rows with addresses and published coordinates;
  the importer reported zero unresolved coordinate rows. The response count
  alone does not independently establish that the API returned every active
  retailer statewide.
- The official Scratch-it API used by
  `tooling/import_oregon_scratch_catalog.mjs` returned 55 currently for-sale
  games with price, top prize, and remaining top-prize count.
- The [official winner list](https://www.oregonlottery.org/winners/list/) says
  that its statewide list is currently unavailable. The visible winner stories
  do not constitute a comprehensive retailer-level winner activity feed from
  January 1, 2026 onward. Oregon Lottery's
  [winner-anonymity policy](https://www.oregonlottery.org/winner-anonymity/)
  permits release of the selling retailer, but does not itself supply the
  required historical feed.

Next step: obtain an official comprehensive winner export with game, prize,
win date, selling retailer identifier or exact address, and source provenance.
Confirm that the retailer API response is a complete statewide active roster.
Then normalize and validate the records before enabling Oregon in the app.

On September 13, 2026, a data inquiry was sent to
`publicaffairs.lottery@lottery.oregon.gov`, the contact listed on the
[Lottery's official legal page](https://www.oregonlottery.org/about/legal/).
It asks for existing draw and Scratch-it winning-ticket/claim counts,
retailer-linked winner records, count definitions, refresh cadence, and
confirmation of retailer API completeness. Gmail confirmed “Message sent.”
The [official records request form](https://www.oregonlottery.org/public-information/request-form/)
is available if the Lottery routes the inquiry to that process. This request
does not change the current source gate.

Update September 16: Jessica Nelson, Oregon Lottery Records Management
Consultant, replied that the Lottery does not offer API data access and
directed this inquiry to its [official public-records form](https://www.oregonlottery.org/public-information/request-form/).
That statement concerns requested data access; the already observed public
retailer and Scratch-it endpoints still require their own provenance and
completeness checks. The formal 2026 year-to-date request was submitted on
September 16 through the linked Wufoo form. The confirmation said “Public
Records Request received.” It asks for existing all-tier draw and Scratch-it
counts, retailer roster and selling-retailer joins, with a recent-month sample
accepted only as a first format check. No fees were authorized. Responsive
records and a repeatable update route remain pending.

An Oregon Lottery confirmation email also arrived at 7:26 p.m. ET September
16 and explicitly confirmed receipt of the public-records request.

## September 20 catalog refresh

The official public Scratch-it API returned 467 records and `NextItems: 0`;
51 records fall within their published availability dates as of retrieval.
`tooling/import_oregon_scratch_catalog.mjs` now validates pagination, unique game
numbers, calendar dates, positive integer prices/prizes and nonnegative integer
unclaimed top-prize counts. Missing counts are rejected rather than coerced to
zero. Ended and future games are excluded, and redemption deadlines are retained
where published. Five regression tests cover source semantics, date boundaries,
unknown versus zero counts, duplicate/truncated responses and redemption dates.

The [official Scratch-it list](https://www.oregonlottery.org/scratch-its/list/)
says prize/ticket information updates once daily and defines top prizes
unclaimed as not yet redeemed, which does not establish store stock. The new
catalog notes preserve that definition, daily cadence and retrieval date;
a separate source publication timestamp is not supplied by this response and
is not invented. The six-hour publisher now checks this catalog and includes
its validated output in the combined state catalog feed. The bundled snapshot
is refreshed for offline use.

This adds a dated game inventory only. It does not establish complete statewide
winning-ticket counts or authorize Oregon retailer heat points. The existing
public-records request and the retailer/winner-location coverage requirements
remain pending. Catalog testing is a separate milestone from full-state
completion; deployment verification is reported in the task.

## October 5 agency delivery

Oregon supplied two attachments, Draw Game Sales 10.5.26.xlsx (357,288 bytes)
and Active Retailer List Statewide 10.5.26.xlsx (496,125 bytes), plus a private
access link described as sales and commission reports from 2015 to present.
The agency warns that historical reports come from different systems with
varying fields and time periods and offers to check for missing material.
No fee is stated. The private access token and requester details are not public.

Attachments and linked reports require private schema/privacy/period audits.
Sales and commissions are not winning-ticket or claim counts. Neither attachment
name nor this response establishes delivery of all requested prize-tier counts,
Scratch claims, winner joins, definitions or an update commitment. No new layer
is approved by receipt alone. No acknowledgment or follow-up sent this session.

## October 5, 17:35 ET — private attachment audit

Both original XLSX attachments were downloaded into ignored private storage;
byte sizes match the agency delivery. Read-only workbook audits leave originals
unchanged. Neither workbook is promoted to a public feed.

The retailer Export sheet has 3,690 business rows with unique account IDs,
plus a total, blank row and applied-filter footer. The footer limits the export
to active regular retailers and excludes an administrative account. This is a
filtered roster, not proof of every possible account class. Of the business rows,
1,521 have both traditional and video flags, 1,675 traditional only, and 494 video
only: 3,196 traditional-enabled accounts and 2,015 video-enabled accounts.
These are source flags, not observed inventory or winning activity. The workbook
has no coordinates. Names and business location fields may support reconciliation
with the official public locator, but positions must come from verified sources.

The attachment also includes primary contact names/phones, shipping addresses,
and parent-account fields. Keep those fields private and exclude them from public
artifacts. Account IDs remain private join evidence unless independently verified
as public locator identifiers. Do not copy full workbook rows into public tests.

The sales Export sheet has 3,980 named dated rows, two additional dated rows
without business identity, a blank row and a filter footer. The named rows span
December 28, 2025 through September 26, 2026; the identity-less rows extend through
October 2. The footer specifies business calendar year 2026, which must not be
silently relabeled calendar-year-to-date. Per-row periods vary and none reverse.
Eight game-sales columns and Total use dollar formatting, including fractional
Pick 4 values and 11 negative numeric cells across named rows. These are monetary
sales measures, never ticket/claim counts. The source's Total differs from the
arithmetic sum of the eight displayed game columns on 3,205 named rows. Preserve
source values privately; aggregation and adjustment semantics remain unresolved.

Sales lacks retailer ID and street address. Exact normalized name/city/county
matches find a unique active roster candidate for 3,650 sales rows, ambiguous
candidates for 18, and no candidate for 312. The roster itself has 18 duplicate
name/city/county keys. A unique text candidate is not an approved historical
retailer join; no sales heat layer or winner layer is authorized by these matches.
The private 2015-present archive remains unaudited. No email sent; broader claims,
counts and repeatable delivery definitions remain separate open gaps.

Next reconcile the full product scope and public locator schema, then implement
an allowlisted directory with explicit traditional/video coverage and strict
coordinate/identity validation. The old importer uses a minimum-row heuristic
and calls its output complete; that assertion needs replacement with evidenced
source coverage before app integration.
