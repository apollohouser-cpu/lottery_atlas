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


## October 13, 08:01 ET — Fresh atomic report importer

Implemented the seven-page network importer with complete parsing before atomic
replacement, exact family/date-window validation, per-family window regression
rejection and same-report source timestamp regression protection. Unchanged
content retains prior retrieval time and exact file bytes. Fetch/parse/replace
failures preserve the previous file; temporary files are cleaned on failure.
Retrieval time is timezone-aware and source future-date checks use Central time.

Twenty-five Louisiana tests pass, including request/parse failures, unchanged
reuse, date/source regressions and simulated replacement failure. A fresh official
network import succeeded with fourteen reports, written privately to
work/louisiana_scope/fresh-draw-reports.json. This is not public publication or
scheduled integration. Next wire catalog/report rollback transaction and staging,
then strict app loader/UI and native acceptance. No public feed/build/UI/Gmail,
acceptance or deadline change.


## October 13, 09:02 ET — Catalog/report transaction and publication staging

Louisiana's scheduled job now owns both catalog and draw-report outputs. Failure
at either importer restores both prior files and dates. Eleven transaction tests
pass, including failure at each Louisiana command with byte-for-byte restoration.
The fourteen-report fresh baseline is tracked and staged for the public report
endpoint; the publisher copies and commits both baseline and endpoint files.

This wires publication and future refreshes; a successful deployed endpoint and
first scheduled two-output run are not yet verified. App loader/UI/native work
remain open and no state acceptance is claimed. No build/UI/Gmail or deadline
change. Report baseline retrieval: October 13 at 12:01:51.986729 UTC.


## October 13, 10:06 ET — Initial report publication verified

Publisher run 38401891117 completed successfully for commit 0e2c120. The deployed
Louisiana report endpoint matches both the tracked fourteen-report baseline and
staged endpoint byte for byte (SHA-256
`e70b6f87dadc66fb32703ac94620959c5eb0d4c0710b50c2f046fbca8c9332c6`).
Retrieval remains October 13 at 12:01:51.986729 UTC. Public endpoint:
https://apollohouser-cpu.github.io/lottery_atlas/louisiana_draw_reports.json

Initial publication is verified. The latest scheduled run returned by the API,
38328596468, predates the two-output wiring; first scheduled catalog/report
transaction success therefore remains open. Push publication does not execute
source refreshes. Strict Flutter validation/cache/remote/bundle loading, report UI
and native acceptance remain next. No new acceptance, build, UI, Gmail or deadline
change; Louisiana remains the sole active state with October 17 at 23:55 ET due.


## October 13, 11:09 ET — Strict app report loader and bundle

Added the Louisiana report asset, strict Dart validator and cache/remote/bundle
loader. Validation requires fourteen reports across seven families, exact routes,
source dates and printed timestamps, required qualifications and source warnings,
number ranges, tier identities and literal currency units. Pick 3/4 dollar totals
cannot acquire invented winner counts; Pick 5 counts remain separate. Powerball
jackpot Power Play stays N/A/null. Mega Millions multiplier columns and repeated
jackpot entries remain separate with mandatory warnings. Pick schedule rows,
columns, spans, labels, payout syntax and combo costs are validated.

Retrieval/family-window/same-report source-time regressions are rejected. Failed
requests or invalid remote data retain validated cache or bundled data without
writing; a valid response survives cache-write failure. Six Flutter tests pass,
including twenty-two malformed variants and continuity/failure/storage checks.
Three-file analysis is clean. This is loader/bundle groundwork; report UI is not
yet wired and no native adoption, full build or acceptance is claimed. Next wire
all seven families with source warnings and literal Pick schedules, then validate
compact/wide and native flows. Scheduled two-output checkpoint remains open.
No Gmail, deadline or state-acceptance change.


## October 13, 12:07 ET — Report UI and scheduled publication checkpoint

Connected the Louisiana source screen to all fourteen reports across seven
families. The sheet shows printed source timestamps and mandatory warnings before
report rows, separate base/Power Play and MM multiplier entries, literal jackpot
advertisements, Pick dollar totals and Pick 5 winners. Published Pick schedules
show their examples, odds, wager costs and inherited Straight/Box continuation
labels separately from actual reports. Qualifications, retrieval time, scope
limits and dated official report links remain visible. Selecting a report resets
the list; a widget-test failure exposed retained list layout after a selection,
resolved by rebuilding the list for the selected report and resetting its offset.

Three widget tests pass, traversing all fourteen reports and footers at 390×844
and 1400×1000 and checking warning/selection reset behavior. Three-file analysis
is clean. No full build or native/source-return/adoption acceptance yet.

First scheduled two-output run 38411673931 completed successfully, publishing bot
commit c30a8d7. Louisiana status lists both outputs as updated. The report content
was unchanged and correctly retained retrieval 12:01:51.986729 UTC. Scratch now
has 43 games / 418 tiers, retrieval 09:16:04.096943 CDT on October 13. Public
report, combined catalog and refresh-status bytes exactly match committed files.
The scheduled publication checkpoint is closed; this does not prove native
adoption. Next audit the existing Louisiana Scratch app experience and remaining
source disclosures, then integrated native coverage. Deadline October 17 at
23:55 ET unchanged; no Gmail or state acceptance.


## October 13, 13:07 ET — Coverage disclosures and Scratch UI audit

Added Louisiana-specific source/cadence notices and eight verified official routes
from the closed scope: Scratch inventory, retailer search, Where Winners Are,
Fast Play, unclaimed prizes, bundles, promotions and Club Lotteaux. Notices retain
the mixed sale/claim basis and $500+/60-day official-map scope, no approved app
positions/joins, separate Pick dollar/count units and bounded report/history
limits. Six-hour app polling is distinct from unconfirmed agency publication
cadence. Three edited registry files analyze cleanly; diff check passes.

Code audit found the existing generic Scratch path does not yet satisfy the
all-tier acceptance scope: StateScratchGame retains top-prize summary fields and
inventoryNote but drops prizeTiers, published odds, sourceUrl and detailed source
metadata when parsing/serializing. The map panel only renders the top-prize
summary. The scheduled 43-game/418-tier source data is available, but its richer
fields need a strict Louisiana loader/cache/bundle and literal tier UI before
native acceptance. This is an unfinished integration gate, not a failure of the
accepted states or evidence of a bad scheduled source. Next implement that path,
including TICKET labels, per-game timestamps, search/price/reset and official
game-detail returns; then build and run integrated native acceptance. No build,
UI session, Gmail, acceptance or deadline change.


## October 13, 14:08 ET — Literal Scratch app loader and bundle

Added a dedicated Louisiana Scratch loader and the current generated bundle.
The combined public endpoint is filtered to exactly one Louisiana catalog;
only that complete catalog is cached, retaining all 43 games / 418 tiers and
source metadata. Validation rejects duplicate games/tiers, incorrect game URLs,
malformed dates/odds/counts, inconsistent total/claimed/remaining arithmetic,
inconsistent top-prize fields and cash conversion of literal TICKET prizes.
Retrieval, discovery-report and same-game timestamps cannot regress; game
identity changes and large catalog shrinkage are rejected. Scale guards are not
claims of completeness. Counts may change with validated source updates.

Five Flutter tests pass, covering fourteen malformed variants, five continuity
failures, request/parse failures with cache and cold bundle, Louisiana-only cache
serialization and storage-write failure. Two-file analysis is clean. Tier UI is
still pending, so this does not close Scratch app or native acceptance. Next add
search/price/reset, literal all-tier inventory with per-game dates and official
detail links, wire source/map entry points, then integrated native checks. No
full build/UI/Gmail, acceptance or deadline change.


## October 13, 15:08 ET — Literal Scratch UI connected

Louisiana Scratch now has an all-tier inventory sheet reachable from the source
page, compact map Scratch action and desktop catalog action. Search by game/name,
ticket-price filter and explicit Reset filters restore usable selections. Each
game shows its start date, detail inventory timestamp, literal prize labels
(including TICKET), total/claimed/remaining counts and published odds. Discovery
report timestamp, retrieval, source scope/cadence and official game-detail/list
links are separate. No map positions or dated winner counts are generated.

Three widget tests pass: all 43 games traversed through the source footer at
390×844 and 1400×1000, plus empty search/price recovery and reset. Four-file
analysis reports only the existing unrelated live-map line 289 brace info; the
new sheet/test and source-screen integration are clean. No full build or native
interaction/source-return/adoption/retention acceptance yet. Next prepare the
ordinary iOS simulator build and perform integrated Louisiana report/Scratch
native checks with at most one simulator active. Deadline October 17 at 23:55 ET
unchanged; no Gmail or state acceptance.


## October 14, 09:32 ET — Restart recovery and native Scratch checkpoint

The ordinary iOS simulator debug build at e1eb950 completed October 13
(Xcode 33.0 seconds), was installed and launched on iPhone 17e / iOS 26.5.
The session was interrupted by the user-reported Mac shutdown during source-link
inspection; no shutdown cause is established. After restart, the checkout was
clean, PNY mounted with build/work links intact, and internal free space about
15 GiB. The unrelated booted iPhone 17 was shut down before reopening the original
17e, preserving its app data and keeping one simulator active. No rebuild needed.

Native Scratch now demonstrates newer remote adoption: 43 games, discovery
report October 14 at 03:21:05 -05:00, displayed retrieval
2026-10-14T12:05:21.285Z, and game #1625 detail timestamp October 14 at
06:58:17 -05:00. The packaged catalog remains October 13. Traversed all ten
#1625 tiers including literal TICKET and the coverage/retrieval footer. Its
correct official URL opened in Safari, rendered Color Me Happy / game 1625,
and returned with the same selection and inventory retained. Empty search
produced 0/43; Reset restored 43/43. The $20 filter produced 3/43 and Reset
restored all prices and 43/43. No invented cash value or store-stock claim.

This is a partial native checkpoint, not state acceptance. Report-family native
interaction/source returns, wide layouts and production-loader request-failure
retention remain open. Scratch newer-native-adoption and the checked compact
filter/detail-return flows are evidenced; no need to repeat them absent a defect.
Deadline October 17 at 23:55 ET unchanged. No Gmail, fees or store submission.


## October 14, 09:37 ET — Native report adoption and three family returns

On the existing e1eb950 iPhone 17e build, reports loaded retrieval
2026-10-14T04:58:38.376027+00:00, newer than the installed October 13
bundle. The selector exposes fourteen reports, including October 13 Mega
Millions and Pick drawings. This closes newer native report adoption only.

Lotto October 10 and Easy 5 October 10 each displayed all four tiers, literal
advertised jackpot, printed update time, qualifications and retrieval footer.
Powerball October 12 displayed all nine match rows with base and Power Play
columns separate, jackpot Power Play N/A, numbers/multiplier and annuity/cash
qualification. Each official link opened its correct game URL with the selected
date fragment in Safari and returned with the same in-app selection retained.
The official pages rendered, but the viewport landed near general prize schedules
or qualifications; this proves correct route/return, not automatic focus on the
dated report inside the external page. No app data defect established.

Source-page coverage/cadence notices and both dedicated app entry cards are
present natively. Remaining: Mega Millions and Pick 3/4/5 native traversal and
source returns, remaining dated selections, wide layouts, request-failure
retention and consolidated acceptance. No rebuild, Gmail, state acceptance or
deadline change; October 17 at 23:55 ET remains the release deadline.


## October 14, 10:37 ET — Mega Millions and Pick 3 native traversal

Existing e1eb950 iPhone 17e build: Mega Millions October 13 traversed all nine
match rows, each with five separate multiplier count/prize pairs. Literal
$2M–$10M prizes and repeated jackpot cells remain separate. All three warnings
were visible before the rows: Megaplier source label, repeated jackpot columns,
and the October 10 printed update preceding the October 13 drawing. Annuity,
nonjackpot multiplier and per-play assignment qualifications reached the footer.

Pick 3 October 13 displayed four play-type dollar totals without winner counts,
ordered digits, the printed-date conflict warning, and all nine physical payout
schedule rows. Straight/Box continuation labels, literal odds/examples, Combo
play costs, wager restrictions and liability qualification were traversed.
Both families opened their correct dated-fragment official URLs, rendered the
official page and returned retaining selection and scroll position. As previously
noted, external pages landed around general schedules, not proven automatic
focus on the dated report. Retrieval stayed October 14 at 04:58:38.376027 UTC.

Partial acceptance only. Next Pick 4/Pick 5 full traversal and source returns,
remaining dated selections, wide layouts, request-failure retention and final
consolidation. No rebuild, Gmail, fees, state acceptance or deadline change.


## October 14, 11:41 ET — Pick 4 native traversal and source return

Existing e1eb950 iPhone 17e build: Pick 4 October 13 displayed its four
play-type dollar totals without winner counts, ordered digits and the printed
October 12 update-date warning. All 17 physical schedule rows were traversed,
including Straight/Box continuations, literal examples/odds and all four Combo
cost pairs. Wager defaults, liability qualification and coverage footer remained
visible. Retrieval stayed October 14 at 04:58:38.376027 UTC.
The official link opened the correct pick-4/#2026-10-13 URL in Safari and
rendered the official schedule; return retained selection and footer position.
The existing caveat remains: automatic focus on the dated report is unproven.

Pick 5 October 13 displayed all eight separate winner/dollar summary rows,
including zeros, ordered repeated digits and its printed-date warning. Schedule
traversal reached Straight and the 5/10/20/30-Way Box rows. The exposed 60-Way
Box accessibility text was truncated; clicking that long row dismissed the
sheet. No data or layout defect is established by this automation action. The
sheet was reopened and Pick 5 October 13 restored at its summary. Remaining
Pick 5 rows and source return are not claimed complete.

Next: finish Pick 5 using fresh screenshots for long rows, remaining dated
selections, wide layouts, request-failure retention and consolidated acceptance.
One portrait simulator remains active. No rebuild, Gmail, acceptance or deadline
change; October 17 at 23:55 ET remains the release deadline.
