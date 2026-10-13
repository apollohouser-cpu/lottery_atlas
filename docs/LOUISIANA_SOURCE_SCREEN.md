# Louisiana source screen — September 13, 2026

Louisiana is not ready for a complete winning-ticket total or retailer
ranking. Its [Top Prizes Remaining](https://louisianalottery.com/scratch-offs/top-prizes-remaining/)
information covers top-prize claims and unclaimed prizes for active games,
not all winning tickets in a selected period. The Lottery's
[retailer terminal report guide](https://louisianalottery.com/static/files/docs/RetailerForms/Terminal-Report-Guide22.pdf)
describes top prizes claimed and remaining; this cannot establish all-tier
Scratch-Off counts. Monthly winnings releases on the
[news page](https://louisianalottery.com/news-and-promotions/) generally
report prize dollars, not complete ticket counts. A complete active
retailer export and retailer-linked wins were not established in this screen.

The [2026 official press kit](https://louisianalottery.com/wp-content/uploads/2026/02/2026-Press-Kit.pdf)
lists Communications Director Chrislyn Maher. On September 13, 2026, a
data inquiry was sent to `Chrislyn.Maher@LouisianaLottery.com` for routing
to the appropriate data or records custodian. It requests existing all-tier
draw counts, Scratch-Off ticket or claim counts, retailer records, definitions,
historical coverage, update cadence and daily access if available. Gmail
confirmed “Message sent.” This is an inquiry rather than a formal records
filing; no complete dataset has been verified from a response yet.

## September 20, 2026 catalog and inventory audit

The current official endpoints are `/scratch-offs/`, `/top-prizes-remaining/`,
`/last-day-to-claim/` and `/expired-games/`. The older nested report link above
should not be used for an importer. Reports embed structured JSON inside
`prize-table` elements; a text-only or HTML-table-only reader misses the rows.

The source catalog contains 40 unique game links. The top-prize report contains
39 unique game numbers, all linked from that catalog, with explicit price,
top prize, start date and remaining/original quantities such as `1 of 6`.
All numeric fields and remaining <= original checks passed. The report is dated
September 20, 2026 01:51:04 AM CDT. The closing report has nine rows and the
expired report has 36; neither overlaps those 39 top-prize entries. The closing
page explicitly states daily updates; do not assume every source shares that
cadence without checking.

The extra catalog link is game 1605 Louisiana Seasons. Its detail page explicitly
marks it expired, with a February 4, 2026 final redemption date. Its prize table
still shows positive remaining lower-tier counts, even though prizes can no
longer be redeemed. Thus neither presence in a catalog nor remaining > 0 proves
eligibility. Exclude this game from a current playable/redeemable catalog.
The expired report is not by itself a complete historical exclusion list.

The detail source distinguishes total, claimed and remaining prize quantities
by tier, including a categorical TICKET tier. These are cumulative game inventory,
not dated winning-ticket totals. Preserve categorical awards and source timestamps.
The separate approximate percent-claimed metric does not equal the percentage
of top prizes claimed (for example 1640 has 1 of 6 top prizes remaining but
97% claimed), so do not derive or relabel it as top-tier claims.

Read-only audit files are in ignored `work/louisiana_catalog/`: catalog, three
report pages, Louisiana Seasons detail and `audit.json`. No Louisiana public
feed changed during this audit. Before import, validate the 39 candidate detail
pages and their explicit eligibility, then test identity joins, expiry, remaining
arithmetic and noncash tiers. The records-routing inquiry remains pending.

### Full candidate-detail validation

All 39 report candidates were fetched and validated against their detail pages.
The 378 detail prize rows reconcile exactly: total = claimed + remaining.
Every detail's maximum cash prize matches its report top prize, and every
top-prize remaining count agrees with the report. No candidate detail is marked
expired. The excluded Louisiana Seasons page remains the negative control for
an expired game that still carries positive lower-tier inventory.

Printed identities in page titles, explicit ticket prices and launch dates
also agree for all 39 candidates. Every detail provides a source timestamp
with an explicit CDT timezone (the parser should also support CST), allowing
per-game inventory timestamps to remain distinct from the earlier summary
report timestamp and importer retrieval time. The only noncash tier label
observed was `TICKET`; do not assign it a cash value or fold it into cash tiers.

The reproducible detail audit is `work/louisiana_catalog/audit_details.py`,
with 39 saved detail pages, `detail_audit.json` and `identity_audit.json`.
No source-validation failures occurred in this pass. Public import remains
pending implementation and regression tests; this audit does not claim that
Louisiana is ready for app testing or a complete statewide heat map.

### Validated publication path

The importer now fetches the report and all candidate detail pages, verifies
printed identity, ticket price, launch date, top prize, full tier arithmetic,
source timestamp and detail eligibility, and writes only after validation.
A fresh run produced 39 eligible games. Inventory counts come from each detail
page rather than combining differently timed summary and detail counts.
Per-game source timestamps retain explicit CDT/CST offsets; the catalog-level
report timestamp describes candidate discovery. Retrieval time is separate.

Expired detail pages and passed claim deadlines are excluded even if remaining
inventory is positive. Noncash TICKET tiers remain categorical. Five importer
regression tests cover expiration, inclusive deadlines, zero/noncash prizes,
arithmetic and identity/price/timestamp errors; an offline app test covers
expired-game exclusion and visible timestamps. The six-hour publisher and
bundled catalog now include Louisiana. This is inventory coverage, not
January-to-current dated claims or verified retailer heat-map completeness.


## October 12, 23:55 ET — Supported scope activation

Louisiana is the sole active state after NC acceptance. Fresh home, Powerball,
Pick 3 and retailer-search HTML captures succeeded; see LOUISIANA_ACCEPTANCE.md
for evidence and gates. Existing scheduled Scratch coverage reduces startup
work, while substantial draw/report integration receives a fresh 120-hour window.
Scope due October 13 at 23:55 ET; release decision due October 17 at 23:55 ET.
No extension used. Historical complete-count gaps above remain separate from
honest supported-app completion. No new correspondence or public dataset change.

## October 13, 00:58 ET — Supported scope closed

Captured eleven additional linked official pages privately: Mega Millions,
Lotto, Easy 5, Pick 4, Pick 5, Fast Play, promotions, Club Lotteaux, unclaimed
prizes, Where Winners Are and ticket bundles. All seven current draw families
now have retained HTML. Python urllib returned 403; ordinary curl fetched the
public pages successfully without authentication or access-control changes.
Capture script and HTML/text evidence remain in work/louisiana_scope.

| Product | Supported target | Required limits / gaps |
| --- | --- | --- |
| [Powerball](https://louisianalottery.com/draw-games/powerball/) | Two dated Louisiana reports; base and Power Play columns | Preserve N/A jackpot cells and literal prizes; schedule separate from actual winner tables |
| [Mega Millions](https://louisianalottery.com/draw-games/mega-millions/) | Two dated reports with all five printed multiplier pairs | Jackpot is repeated across source columns; preserve structure, never sum into distinct winners; pre-April 8, 2025 chart is historical, not current |
| [Lotto](https://louisianalottery.com/draw-games/lotto/) / [Easy 5](https://louisianalottery.com/draw-games/easy-5/) | Two reports each, four source winner/prize rows each | Draw-specific advertised jackpot separate from next jackpot and literal tier prize |
| [Pick 3](https://louisianalottery.com/draw-games/pick-3/) / [Pick 4](https://louisianalottery.com/draw-games/pick-4/) | Two daily reports each; ordered digits, four play-type dollar totals and separate literal schedules | Source reports lack winner-count columns; do not divide totals by schedule awards to invent counts |
| [Pick 5](https://louisianalottery.com/draw-games/pick-5/) | Two daily reports; eight play-type winner/total rows, separate schedule | Preserve Straight, Box and Front/Back 4/3/2 labels; no distinct-ticket/person aggregation |
| Scratch | Existing eligible detail catalog, all literal tiers and timestamps | Existing snapshot 42 games / 408 tiers; revalidate importer/app flow. Cumulative inventory, categorical TICKET, explicit expiry exclusions, not stock or dated claims |
| [Fast Play](https://louisianalottery.com/fast-play/) | Official catalog/detail and expiry/source routes with explicit supported gap | Progressive advertisement is not a winning count. No validated dated winner feed or all-tier inventory yet |
| [Retailers](https://louisianalottery.com/where-to-play/) / [Where Winners Are](https://louisianalottery.com/where-winners-are/) | Usable official search/map routes and exact scope disclosure | Public winner map is $500+ over 60 days, mixing sold draw/Fast Play tickets with claimed Scratch tickets. Power BI embed is not an audited export. No app pins, complete directory or join inferred |
| [Unclaimed prizes](https://louisianalottery.com/unclaimed-prizes/) | Separate official route | Selected outstanding prizes/deadlines do not establish paid claims or all winners |
| [Ticket bundles](https://louisianalottery.com/draw-games/ticket-bundles/) / Multidraw / Advance Play | Official explanation routes | Purchase options, not additional independent winner series; no purchases or account actions |
| [Promotions](https://louisianalottery.com/promotions/) / [Club Lotteaux](https://louisianalottery.com/club-lotteaux/) | Separate official routes and unsupported winnings disclosure | No login, entries, ticket identifiers, promotional counts or account data |
| Historical / replaced products | Explicit gap with official history/chart routes | Two recent reports per family is not ten-year history. Old Mega Millions rules remain separate |

Bounded report target: **14 reports, seven families / seven daily-or-drawing
groups**, not the NC fourteen-session schema. Current pages do not establish
additional Louisiana midday/evening groups. Close scope now; parser validation
must prove each actual report's date, digits/numbers, row identities, columns,
source update text and qualifications before publication.

Named source discrepancy: the fresh Pick 4 and Pick 5 pages contain October 12
rows while their printed Last Updated text remains October 11 at 11:15 PM CDT.
Preserve both draw date and literal update timestamp and disclose this mismatch;
do not advance the source timestamp to retrieval time or silently repair it.
Reject unsupported structural changes while allowing only explicitly modeled,
visible source discrepancies. Other families need the same timestamp audit.

No new report feed, app changes, native acceptance, public directory or agency
response is claimed. Scope closed ahead of October 13 at 23:55 ET; supported
release deadline remains October 17 at 23:55 ET, no extension. Next implement
strict parsers starting with simple Lotto/Easy 5 and explicit Pick summaries,
then PB/MM, refresh transaction and app integration.


## October 13, 01:58 ET — Lotto and Easy 5 bounded parsers

Implemented strict local draw-report parsing for Lotto and Easy 5. Both retained
full source pages validate before selecting two recent reports each (October 10
and 7): four reports / sixteen tier rows privately written under
work/louisiana_scope/{lotto,easy-5}-reports.json. Draw numbers, date/weekday,
unique dates, associated disclosure IDs, Louisiana unit caption, exact columns,
four match identities/symbol counts, nonnegative winners and literal prizes are
validated. Jackpot advertisements remain distinct from the literal Jackpot tier.
The historical purchased-ticket annotation remains literal, not a map location.

Source update text and Central timezone offsets are retained. An update date
preceding the draw date creates an explicit warning rather than a repaired date.
Six tests pass, including twelve malformed variants, missing pairs/tiers,
duplicate history before selection, future dates and mismatch preservation.
Observed Load More control is validated separately from dated row pairs; source
DOM extraction includes every embedded history row, not an unverified complete
history claim. Fixtures contain two bounded public reports per family.

This is parser groundwork, not a complete report collection or acceptance.
Remaining families, literal Pick schedules and full qualifications, atomic
refresh/publication and app/native integration are still pending. No public
feed change, simulator/build, Gmail or deadline change.


## October 13, 03:01 ET — Pick dated summaries parsed

Strict Pick 3, Pick 4 and Pick 5 summary parsers now validate every embedded
history pair before selecting two recent reports per family. Six private reports
contain 32 play-type rows: Pick 3 October 11/10, Pick 4 and Pick 5 October 12/11.
Pick 3/4 retain literal statewide dollar totals and exact cents, with no inferred
winner counts. Pick 5 retains the eight source play-type winner counts and dollar
totals, including explicit zero rows. Ordered digits preserve zeros and repeats.
Date/weekday, row association, exact columns/play types, numeric formats and
Central source timestamps are checked. The Pick 4/5 October 12 versus October 11
source-update mismatch is preserved with an explicit warning for later UI display.

Eleven Louisiana parser tests pass, including eleven new malformed Pick variants,
missing rows, duplicate history, zero/repeated digits and absent Pick 3/4 counts.
Bounded public-source fixtures are tracked; full captures and parsed outputs stay
private under work/louisiana_scope. Literal payout schedules and source
qualifications remain pending, as do PB/MM parsers, atomic collection, publication
and app/native integration. This is not state acceptance. No public feed, build,
simulator or Gmail changes; October 17 at 23:55 ET deadline remains unchanged.


## October 13, 03:59 ET — Literal Pick payout schedules

Added separate strict schedule parsing for all three Pick families: twelve tables,
51 physical rows (Pick 3: 9; Pick 4: 17; Pick 5: 25). Literal example wagers,
winning combinations, odds descriptions, payout labels, combo play costs and
row/column spans are retained. Pick 5 front/back examples preserve line-break
separation. Each family's Straight/Box wager note and liability-limit explanation
are required and retained. These are published schedules, never observed winners.

Thirteen Louisiana tests pass, including changed spans, missing tables/rows,
malformed payouts, missing combo costs/qualifications and changed labels/columns.
Full captured pages parsed successfully; private outputs are pick*-schedule.json
under work/louisiana_scope and public schedule fixtures are tracked. Schedules
remain separate from dated summaries until collection integration. PB/MM parsers,
remaining family qualifications, atomic refresh/publication and app/native work
remain open. No feed/build/UI/Gmail changes or acceptance; deadline unchanged.


## October 13, 05:00 ET — Powerball dated reports

Strict Powerball parsing validates every embedded source history pair before
selecting October 10/7: two private reports with nine match rows each. Separate
Non Power Play and Power Play winner/prize columns remain distinct. The jackpot
Power Play cells retain N/A with a null count, never zero or an invented count.
White/red number ranges, white-number uniqueness, multiplier, date/weekday,
Louisiana caption, exact column/match labels and symbols, associated report IDs,
counts, literal prizes and Central source timestamps are validated.

Sixteen Louisiana parser tests pass, including eleven malformed PB variants,
missing tiers and duplicated older history. The complete retained source capture
parsed successfully; work/louisiana_scope/powerball-reports.json stays private,
with a bounded two-report public fixture tracked. Mega Millions remains the last
family parser; remaining source qualifications, collection/transaction integration,
publication and app/native work remain pending. No public feed/build/UI/Gmail or
deadline changes; this is not acceptance.


## October 13, 06:00 ET — Mega Millions dated reports

The final family parser validates all embedded current-rule Mega Millions reports
before selecting October 9/6: two private reports, nine match rows with five
separate multiplier winner/prize pairs each. Literal $2M–$10M labels remain intact.
Repeated jackpot entries remain separate source cells, with a required warning
against summing them. Source match descriptions say Megaplier while the symbol
class denotes Mega Ball; both are retained with an explicit warning for the UI.
Pre-April 8, 2025 rules fail closed into the separate historical gap.

Nineteen Louisiana tests pass, including nine malformed MM variants, old-rule
dates and missing multiplier cells. All seven family parsers now produce fourteen
private bounded reports from the retained captures; this is not a collected,
refreshed or published feed. Remaining qualifications and attaching Pick schedules,
atomic collection/refresh, app validation/UI and native acceptance remain open.
No public feed/build/UI/Gmail or deadline changes. Private output:
work/louisiana_scope/mega-millions-reports.json; two-report fixture tracked.
