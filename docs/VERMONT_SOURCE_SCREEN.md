# Vermont source screen — September 15, 2026

The Vermont Lottery's official [Winners](https://vtlottery.com/win/winners)
page publishes claim date, store name, town, game and prize amount for selected
draw, instant and Fast Play winners. It includes many current 2026 records and
is useful as a verified public subset. The page does not state its prize
threshold or whether every qualifying claim is included, and it supplies only
the retailer town rather than an exact address or stable retailer identifier.
It therefore cannot support a complete all-tier total or exact retailer heat
points by itself.

Individual official game pages publish ticket count, percentage sold and
unclaimed prizes by tier. The Lottery warns that remaining prizes depend on
tickets distributed, sold and redeemed. Those inventory figures are not actual
winning-ticket or claim counts and must retain that limitation in the app.

The Lottery's official [contact page](https://vtlottery.com/contact-info)
identifies its Director of Communications and Legislative Affairs as the route
for public information requests and links a public-records database. A focused
Vermont Public Records Act request was emailed to that published address on
September 15. It seeks existing August 1–31, 2026 all-tier draw, instant and
Fast Play ticket counts, a complete active-retailer directory, winner-to-
retailer joins, definitions, cadence and corrections. Gmail confirmed “Message
sent.” Requester contact information was supplied directly and is not stored in
this repository.

Vermont remains suitable only for a clearly labeled public winner subset until
the prize threshold and completeness are confirmed and exact retailer records
are obtained. It is not ready for map testing.

Update September 16: Hannah Chauvin, Director of External Affairs, acknowledged
the September 15 request and extended the response deadline to ten business
days from receipt because of the volume of distinct records to search and
examine. No responsive data or fee estimate accompanied the notice. Track the
agency response around September 29, subject to its business-day calendar;
keep the existing partial-coverage limitation meanwhile.

## September 21 catalog source audit

The working official catalog is `/games/instant-tickets`; `/games` returns
404. The catalog explicitly reports 82 games and has seven pages (`?page=0`
through `?page=6`). Detail links may be short aliases such as `/full-100s`,
not paths containing `instant-tickets`; collect the actual card links.
The reproducible `work/vermont_catalog/audit_listing.py` checks printed game
IDs, names, explicit ticket prices and advertised top prizes across pagination.

Inspected detail `/games/instant-tickets/bank-vault` identifies game 1824,
price $5, top prize $20,000, start January 10, 2025 and last cash date April
10, 2027. It explicitly shows zero unclaimed $20,000 and $1,000 prizes, four
$500 prizes, 420,000 printed tickets, 98 percent sold and $73,790 total
unclaimed dollars. Do not substitute dollars paid/unclaimed, tickets printed,
or percentage sold for winning-ticket counts. Preserve published zeroes.

No inventory verification timestamp or publication cadence was established
from this initial detail check. Full detail/date/eligibility joins, top-prize
report semantics and any reserved second-chance inventory require validation
before import. No Vermont data was published in this pass. Source HTML and
listing audit materials are retained under ignored `work/vermont_catalog/`.

Pagination did **not** pass: the seven saved pages contain 82 rows but only
77 unique printed IDs. Games 1854, 1838, 1871, 1799 and 1839 repeat across
page boundaries. The default ordering appears unstable among tied entries,
but its cause is not established. Do not silently deduplicate and label 77
games complete. The importer must establish a stable sort/full export or an
independently reconciled source before publication. The audit intentionally
fails its uniqueness check; saved pages preserve the evidence.

### September 21 unpaginated report reconciliation

The official `/games/instant-tickets/outstanding-prizes` page contains one
unpaginated table with **82 unique printed IDs and 217 listed prize tiers**.
It includes every ID found in the earlier pagination audit plus the five
missing games: 1811, 1836, 1852, 1873 and 1880. Each row supplies a detail
link, price, name and matching parallel prize/count lists, including explicit
zeroes. This provides a candidate source that avoids the pagination gap.

The separate `/games/instant-tickets/last-day-to-redeem` table contains 108
unique IDs. All 82 report games join to it; their advertised top prizes agree
with the maximum report tier and none has a passed claim deadline as of
September 21. Dates mix two- and four-digit years and use TBD for unknowns.
Preserve TBD as unknown. Printed tickets, percent sold and total unclaimed
dollars remain separate from tier counts.

`work/vermont_catalog/audit_reports.py` reproduces these joins and records
`report_audit.json`. The earlier failing pagination audit remains useful
regression evidence. Full detail validation, source-date/cadence verification
and second-chance inventory interpretation remain before enabling an import.
No Vermont app/feed data changed during this pass.

### September 21 complete detail reconciliation

Fetched all 82 report-linked detail pages with bounded requests and two
concurrent workers. `work/vermont_catalog/audit_details.py` validated each
printed game ID, ticket price, advertised top prize, start date and last cash
date against the report/deadline tables. It parsed 217 explicit unclaimed
prize tiers, preserving zero counts; all tier labels and counts exactly matched
the report snapshot. Printed-ticket totals were positive and percent-sold
fields were within 0–100. Results and HTML are retained in ignored
`detail_audit.json` and `detail-ID.html` files.

No published inventory timestamp or update cadence was established on the
inspected detail/report pages or FAQ. A future importer must use null for
sourceDate/cadence, retain retrieval time separately and say that remaining
prizes are not store inventory or dated winning-ticket totals. The official
FAQ says some expired unclaimed prize money funds promotions/second-chance
drawings; that statement does not establish a reserved-prize adjustment to
these current table counts. Do not subtract an invented reserve or apply
Tennessee's separate reservation rule to Vermont.

The report/detail/deadline combination is now a validated importer candidate,
independent of the unstable paginated catalog. Next implementation should
require unique printed IDs, exact price/top-prize/date joins, parallel tier
lists, explicit unknown dates, inclusive claim deadlines, and source-specific
coverage notices. No Vermont app data changed or state-testing readiness was
claimed in this audit. Pennsylvania's previously reviewed interim letter is
still the only September 21 agency reply found during this check.

### September 21 catalog implementation

The importer now publishes all 82 eligible report games and 217 verified listed
tiers, preserving explicit zeroes. It checks report/detail/deadline identities,
prices, top prizes and dates, excludes future launches and expired claim
periods, and retains ended games through the inclusive redemption deadline.
Unknown inventory dates remain null; retrieval time and the six-hour checking
schedule do not imply a published update cadence. Each game carries these
limitations and any announced end/redemption dates.

The catalog is bundled for offline use and included in the combined feed and
scheduled publisher. Vermont is ready for local catalog testing; this does not
establish all-tier claims, retailer-linked activity or complete map coverage.
Validation passed: 99 Python tests, 39 Node tests, 63 Flutter tests, five HTTP
checks, Flutter analysis (12 existing informational notices only), and a macOS
debug build. Publication verification is tracked separately from local readiness.

Publication verified September 21: workflow 35628051981 succeeded and the live
combined catalog contains all 82 Vermont games. This confirms feed deployment;
the local macOS build and catalog tests remain separate from complete map coverage.

## September 24 records update

September 24: Hannah Chauvin estimated $1,368.00 to provide the requested records and asked whether to continue. No fee or paid work is authorized. Keep the request on hold; use public data for scoped app completion. No records delivered.
