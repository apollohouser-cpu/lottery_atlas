# Louisiana supported-coverage acceptance — active

Activated October 12, 2026 at **23:55 ET** as the sole active state, after
North Carolina acceptance. Scope/gap matrix due **October 13 at 23:55 ET**;
supported release decision due **October 17 at 23:55 ET** (fresh 120 hours for
substantial draw/report integration). No extension used. Louisiana is not accepted.

## Selection and opening evidence

Louisiana has an existing scheduled, detail-validated Scratch catalog, including
expiry guards, categorical TICKET tiers and per-game timestamps. This gives it
a stronger reusable foundation than the unscheduled Georgia/Tennessee routes.
Draw report parsing, app integration and native acceptance remain substantial;
a working Scratch import alone does not justify a 72-hour completion assumption.

Fresh official [home](https://louisianalottery.com/),
[Powerball](https://louisianalottery.com/draw-games/powerball/),
[Pick 3](https://louisianalottery.com/draw-games/pick-3/) and
[retailer search](https://louisianalottery.com/where-to-play/) HTML captures
succeeded. Private files are work/louisiana_scope/{home,powerball,pick3,retailers}.html.
Home navigation exposes seven draw families (Powerball, Mega Millions, Lotto,
Easy 5, Pick 3/4/5), Scratch, Fast Play, promotions/Club Lotteaux, unclaimed
prizes and retailer search. Full option/history scope remains to be closed.

The Powerball page exposes dated Louisiana winner tables with separate base
and Power Play count/prize columns and explicit update timestamps. Jackpot
Power Play cells are N/A; do not manufacture counts there. The printed prize
chart is a payout schedule, distinct from the dated winner tables. Preserve
literal jackpot labels and source qualifications; no cash conversion or
retailer joins from statewide tiers. This is opening evidence, not a validated
new report import. Inspect the other six families and any extra options next.

## Acceptance gates

- [x] Current product/options/history scope and explicit gaps (October 13, 00:58 ET).
- [ ] Strict bounded draw reports with source dates, units and qualifications.
- [ ] Current Scratch integration audited against the existing validated importer.
- [ ] Retailer and winner coverage audited or honest supported limits established.
- [ ] Atomic refresh, regression/failure retention and public publication verified.
- [ ] App report/catalog/source flows with clear coverage limits.
- [ ] Compact/wide native use, source returns, newer adoption and request recovery.
- [ ] Consolidated checks and supported release decision.

No public feed was changed at activation. No coordinates, statewide claim counts,
complete directory or new agency response is inferred. Missing broader agency
records do not block honest supported completion. No Gmail, fees, attestations,
simulator actions or mobile signing occurred. Mobile beta work remains independent.

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


## October 13, 07:01 ET — Complete private report collection

Added a strict seven-page collection assembler requiring exactly fourteen reports,
two per family, with matching official routes. Pick schedules and wager/liability
qualifications are now attached to each dated Pick report. Lotto pari-mutuel and
fixed-tier explanation, Easy 5 cash/rollover explanation, PB/MM annuity/cash
qualifications, and MM per-play multiplier explanation are required and retained.
Missing groups, schedules or qualifications fail the collection before output.

All seven retained full captures assemble successfully into the private
work/louisiana_scope/draw-collection.json. Twenty-one Louisiana tests pass,
including missing-group/qualification/schedule failures and all previous parser
checks. Bounded fixtures now include required public qualifications and schedules.
This is an in-memory collection assembler, not a fresh network import or atomic
publisher. Next implement atomic fetching/regression protection, scheduled
transaction integration and app/native coverage. No public feed/build/UI/Gmail,
acceptance or deadline change.
