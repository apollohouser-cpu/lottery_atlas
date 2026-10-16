# Kansas supported-coverage acceptance — active

Activated October 14, 2026 at **19:40 ET**, after Louisiana acceptance, as the
sole active state. Scope/gap matrix due **October 15 at 19:40 ET**; supported
release decision due **October 19 at 19:40 ET** (fresh 120 hours for substantial
draw/report and app integration). No extension used. Kansas is not accepted.

## Selection and opening evidence

Selected for its existing strict scheduled Scratch importer, including detail
identity validation, free-ticket semantics, expiry exclusion and separate launch
date representations. The current committed catalog contains **46 games**, with
retrieval October 14 at 12:13:36.236975-05:00. Source verification date is null;
this is a retained importer baseline, not new native acceptance or a dated claim
count. Compared with Iowa's unresolved winner/address matching, Kansas offers a
reusable validated catalog without requiring those joins for supported coverage.
A working Scratch importer alone does not remove substantial draw integration.

Fresh official home, draw directory and Super Kansas Cash detail responses were
captured under private work/kansas_scope/. The /games landing route returned 404;
the actual linked /games/draw-games route returned successfully. Its rendered
HTML is a shell; the embedded Next.js drawGames collection contains 12 entries:
Powerball Xs & Os, Millionaire for Life, Lotto America, Powerball, Pick 3, 2by2,
Mega Millions, Keno, Super Kansas Cash, Lucky for Life, Racetrax and Holiday
Millionaire Raffle. This is a source directory inventory, not proof that all 12
are current independent drawing series: Lucky for Life remains listed alongside
Millionaire for Life, and null metadata end dates do not resolve that history.
Pick 3 instructions explicitly describe two daily drawings. Prize legends and
advertised jackpots are schedules/advertisements, not actual Kansas winner counts.

The home navigation also exposes digital instant games and PlayOn loyalty,
rewards and promotions; the established catalog covers only explicitly typed
Scratch games with no announced end/claim deadline, excluding Pull Tabs and
historical/closing listings. Retailer search has an official route but no audited
statewide export/coordinate join is approved. No login or purchase is needed for
public-source research; private account data and ticket identifiers are excluded.

## Acceptance gates

- [x] Close current products/options/sessions/history scope and explicit gaps (October 14, 20:41 ET).
- [ ] Verify actual dated draw reports and source winner units where available;
      otherwise implement honest usable supported results and explicit gaps.
- [ ] Audit current literal Scratch tiers, source dates, exclusions and app UI.
- [ ] Audit retailer/winner routes; do not infer joins from selected notices.
- [ ] Validate atomic refresh, regression/failure retention and public publication.
- [ ] Verify native compact/wide use, sources/returns, adoption and recovery.
- [ ] Consolidated checks and supported release decision.

Next inspect the official draw-data requests and dated detail structures, resolve
current versus historical products, then fix the bounded supported scope before
implementing strict collectors/loaders/UI. Preserve all source unit/date limits.
Missing broader agency records do not block honest supported-app completion.
No public feed, app build, simulator action, Gmail or fee occurred at activation.
Louisiana and the other accepted states remain closed. Mobile beta preparation
continues independently; October 20–27 remains a provisional beta estimate only.


## October 14, 20:41 ET — Supported scope closed; public result API audited

Scope closed ahead of October 15 at 19:40 ET. Captured all twelve linked draw
detail pages, their public scripts and read-only public result API responses
privately under work/kansas_scope/. The site's own JackpotService uses
`/services/jackpot/api/v1/jackpot-results` on
`https://gateway-web.loyalty.playonkansas.com`, with COMPLETE status, game ID,
page/size and a separate doublePlay filter. No credentials or account actions
were needed. Detail CMS confirms distinct Pick 3 IDs 9 (Midday) and 10 (Evening),
not one combined result group. The public game directory labels both explicitly.

| Product | Supported integration target | Limits |
| --- | --- | --- |
| Powerball | Two recent base results and two Double Play results, literal number groups/Power Play and published prize schedules | Separate variants; no inferred Kansas winner counts or cash conversion |
| Mega Millions | Two current-rule results and literal multiplier/prize rules | CMS still labels a field Megaplier; retain/disclose source wording, no fabricated draw-wide current multiplier |
| Lotto America | Two results, All Star Bonus and literal schedule | No regional winner count inferred from raw shares |
| Super Kansas Cash | Two results, cash jackpot source field and schedule | All-zero raw share fields are not proof of zero Kansas winners |
| 2by2 | Two results with separate number groups and published bonus rules | Categorical free-ticket awards remain categorical; no count aggregation |
| Millionaire for Life | Two results and literal lifetime award schedule | No multiplication into lifetime totals or cash-option conversion |
| Powerball Xs & Os | Two results with official team mapping and schedule | IDs must map exactly to source teams; no invented labels |
| Pick 3 | Two Midday plus two Evening results; ordered/repeated/leading-zero digits and literal wager schedules | No winner rows in sampled result payloads; missing counts stay unavailable |
| Keno / Racetrax | Two bounded recent results each, explicit draw numbers/times and official rules routes | Not a live stream or all-draw history; no wager-specific calculated payout or winner count |
| Scratch | Existing no-announced-end/claim-deadline catalog with all published remaining tiers and provenance | 46-game baseline; no source inventory verification timestamp, no dated claims/stock |
| Pull Tabs | Official shared catalog/detail route and explicit gap | Excluded from existing Scratch importer; do not relabel as Scratch |
| Holiday Millionaire Raffle | Current official schedule/rules/source route | Current page describes January 4, 2027 final drawing; sampled historical results end in 2025 and must not appear as current 2026/27 winners |
| Lucky for Life / old Mega Millions | Separate historical routes and explicit gap | Lucky result feed ends February 21 local date with no next draw; current MM ID12 separate from old ID2 |
| Digital instants / PlayOn promotions, loyalty, rewards | Official source routes and unsupported winning-data disclosure | No account, purchases, ticket identifiers, balances or promotional winner totals |
| Retailers / selected winner stories | Official search/news routes with clear limitations | No validated full directory/export, exact location join or retailer heat ranking |
| Earlier history | Explicit bounded-history gap | Two results per group is not ten years or complete statewide claims |

Target **24 bounded results across ten current families and twelve groups**:
Powerball base/Double Play and Pick 3 Midday/Evening are separate; each other
family has one group. Historical Lucky for Life and raffle are not counted as
current daily families. The [North Dakota Lottery's official historical page](https://lottery.nd.gov/games/lucky-for-life/)
confirms the final Lucky for Life drawing February 21, consistent with the
Kansas retained API history; a null CMS end date does not establish activity.

Two named source issues must be handled before publication. First, raw
`prizeTiers.shareCount/shareAmount` have no demonstrated Kansas geographic unit;
some games have all-zero placeholders while others have large share counts.
The site's visible past-results component disables its details column. Exclude
these raw count/amount fields from the supported result model rather than
claiming Kansas winners or zero wins. Published prize legends remain separate
schedules. Broader counts remain a records/source-audit outcome, not a reason
to leave the supported results unusable.

Second, API `drawingDate` follows UTC in sampled evening draws: Super Kansas
Cash 2026-10-13T02:10:00Z is October 12 in America/Chicago, while drawingDate says
October 13. Preserve raw timestamp/date and explicitly derive local date with
the named zone; never silently label UTC date the local draw date. Pick 3
Midday October14 is 18:13Z and retains repeated digits 2,7,7. Keno/Racetrax
must retain actual draw times; next-draw metadata can be stale and is not a
source verification date. Strict parsing and source-display cross-check remain
required before feed promotion.

Next implement strict bounded result parsing, local-date provenance and exact
family/variant/session validation, then literal schedule/catalog UI and atomic
publication/native acceptance. No generated public data, app build, simulator,
Gmail or acceptance changed. Release deadline remains October 19 at 19:40 ET;
no extension. Private captures are research evidence, not validated app output.


## October 14, 21:42 ET — Strict Pick 3 and Super Kansas Cash results

Implemented tooling/kansas_draw_results.py for Pick 3 Midday/Evening and Super
Kansas Cash. Six bounded results from retained public captures validate; all
supplied rows are checked before selecting two per group. Number identity,
order, ranges, repeats/leading zeros, result association, completion/variant,
page counts, unique draw IDs/dates, descending timestamps and session-local
hours are guarded. UTC source timestamps/dates remain separate from derived
America/Chicago draw dates, with explicit warnings on evening date differences.

Seven focused Python tests pass, including thirteen malformed row variants,
page/date/duplicate/future failures, cash-ball limits and rejection of a bad
older row beyond the selected window. Unverified raw share counts, share amounts
and advertised jackpot fields are deliberately absent from this result output;
changing those fields cannot create Kansas winner counts or paid payouts.
Advertised jackpots and literal schedules still require separate integration.

Private normalized evidence is work/kansas_scope/validated-local-results.json;
three bounded public-response fixtures are tracked for reproducibility. This
is retained-capture parsing, not a fresh network importer or public feed.
Next extend to the other families with exact variants/types/team mapping, then
literal schedules, atomic refresh and app/native integration. Kansas remains
unaccepted; October 19 at 19:40 ET deadline unchanged. No build/UI/Gmail.


## October 14, 22:42 ET — Five multistate result groups validated

Extended the strict parser to Powerball base and Double Play, current Mega
Millions, Lotto America and Millionaire for Life. Ten retained results validate
across these five groups, in addition to the prior six local results. Public
CMS rules establish each normal/special ball range. Exact variant flags,
current game IDs, unique normal balls and required Power Play/All Star Bonus
multipliers validate; Double Play and current per-play Mega Millions reject a
fabricated draw-wide multiplier. Historical MM ID2/pre-April8 rules are excluded.

Opaque public result IDs remain sourceExternalId, not displayed draw numbers;
numeric local-game draw numbers remain separate. Date provenance and warnings
are unchanged. No raw share counts, actual payouts or advertised jackpots are
promoted. Literal schedule and advertised-prize integration remains pending.

Ten Python tests pass, including variant mismatch, all four special-ball limits,
missing/boolean/invalid multipliers and historical MM rejection. Five bounded
public fixtures are tracked; private normalized output is
work/kansas_scope/validated-multistate-results.json. Powerball fixtures separate
the two actual variants from the retained mixed response; the future collector
must request each variant explicitly and preserve two per group.

Next 2by2, Xs & Os exact team mapping, Keno and Racetrax, then schedules and
atomic collector/app integration. This is retained-source parser evidence,
not fresh feed publication or acceptance. No build/UI/Gmail/deadline change.


## October 14, 23:43 ET — All twelve result groups validate

Extended strict result parsing to 2by2, Powerball Xs & Os, Keno and Racetrax.
The retained official rules establish 2by2's two 1–26 groups, Keno's 1–80 range
and Racetrax's twelve horses/ordered finishing positions/allowed bonus values.
2by2 permits overlap across groups but rejects duplicates within each; Tuesday
multiplier 2 is validated against the derived local weekday and accompanied by
its qualifying consecutive-day-play limitation. No universal doubled payout is
inferred. Racetrax retains FIRST/SECOND/THIRD/FOURTH order and source bonus 1
without manufacturing a prize amount.

Keno retains all twenty source numbers in original order with the one SPECIAL
marker explicitly preserved; frequent results may share a local date but must
have unique identities and strictly descending timestamps. No live-stream or
all-day-history claim is made. Fetched the site's public game-number/15 mapping
without authentication; all 32 unique mapping IDs and labels must validate before
the eight Xs & Os values receive official team abbreviations. Team images and
unneeded mapping fields are excluded from the small tracked mapping fixture.

Thirteen Python tests pass, including missing/duplicate/wrong-game team mappings,
number ranges/types, special-marker multiplicity, finishing-order types and
bonus/day mismatches. All retained fixtures now produce **24 results across
12 groups / 10 families**, privately saved in
work/kansas_scope/validated-all-results.json. This remains parser evidence, not
an atomic fresh importer or public feed. No share counts or payouts are promoted.

Next literal schedule/qualification extraction and separately labeled advertised
prizes, then atomic collection/regression guards, app loader/UI and native
acceptance. Kansas release remains due October 19 at 19:40 ET; no extension,
Gmail, build, simulator or state acceptance change.


## October 15, 00:45 ET — Eight families' literal schedules extracted

Added strict Next.js detail CMS extraction and schedule parsing for Powerball,
Mega Millions, Lotto America, Millionaire for Life, Pick 3, Super Kansas Cash,
2by2 and Xs & Os: nine tables / 66 literal rows from retained official captures.
Exact game/session IDs, table/column order and row identities are required;
missing cells/rows/qualifications fail closed. Rules, source disclaimers,
table descriptions/footers and prize qualifications remain distinct. Lifetime
awards, free tickets, base/Double Play columns and Mega Millions' multiplier-odds
table are preserved without calculated payouts or winner totals.

CMS values containing doubled dollar markers are retained verbatim with an
explicit warning. Pick 3 source prose and table disagree on Any Order box
descriptions; both are retained with a separate source warning, not silently
repaired. Required qualification phrases guard pari-mutuel/shared jackpot,
Power Play/Double Play exclusion, lifetime cash-option source text and Tuesday
eligibility. Quoted source cash options are not computed conversions.

Seventeen combined Kansas Python tests pass, including schedule identity/schema,
missing/partial qualification and ambiguous Next.js payload rejection. All eight
retained HTML pages parse; private normalized schedules are saved under
work/kansas_scope/validated-schedules.json. System Python lacked lxml during an
inspection; the established dependency runtime completed extraction/tests.

Keno/Racetrax schedules, separately labeled advertised prizes and collection
assembly remain next, followed by atomic fresh import/publication and app/native
acceptance. This is not a new public feed or accepted state. No build/UI/Gmail;
October 19 at 19:40 ET release deadline remains unchanged, no extension.


## October 15, 01:46 ET — Keno long-text source decoding

Inspection of the remaining Keno schedule found its qualification text stored as
an inline Flight long-text reference (`$14`), rather than direct CMS prose. The
CMS extractor now resolves rich-text leaf references from exactly one text record
using the advertised hexadecimal UTF-8 byte length. Missing/ambiguous references,
truncated text and invalid byte boundaries fail closed. Other CMS strings remain
untouched. The retained Keno capture now yields all three qualification paragraphs,
including progressive 6/7/8-spot awards, ticket limits and the $1,500,000
pari-mutuel threshold; no values were inferred from the reference token.

Eighteen combined Kansas Python tests pass, including Unicode byte lengths and
four malformed reference cases. The resolved qualification evidence is private
under work/kansas_scope/keno-resolved-qualifications.json. Keno's ten schedule
tables and Racetrax's two tables/cards still need strict integration; no public
feed, app acceptance, build or simulator change. Release remains due October 19
at 19:40 ET, without extension.


## October 15, 02:48 ET — Remaining literal schedules extracted

Keno and Racetrax now have strict schedule extraction from the retained official
CMS captures. Keno preserves ten tables / 56 rows, distinct basic and Bull's-eye
columns (including their distinct source keys), spot-game titles, overall odds,
progressive and liability qualifications. Its 6-spot match-one basic prize cell
is literally blank: retained with an explicit warning, never converted to zero.
Progressive bonus amounts are not supplied by these tables.

Racetrax preserves two tables / 17 rows, horse Win/Show odds and returns, bonus
probabilities, four named prize-range cards and their exact official PDF routes,
wager instructions and liability/pari-mutuel notes. Full PDF payout matrices are
not embedded; the output discloses that boundary. No award arithmetic or winner
counts were introduced. Table titles and primary schedule descriptions are now
retained separately from rules and qualifications.

All ten current families parse from retained HTML: 21 tables / 139 literal rows.
Nineteen combined Kansas Python tests pass, including ten new malformed
Keno/Racetrax cases covering titles, blank cells, missing qualifications/cards,
invalid prize ranges and changed PDF routes. Private normalized evidence updated
at work/kansas_scope/validated-schedules.json. Separately labeled advertised
prizes and collection assembly remain next, then atomic fresh import/publication,
app loaders/UI and native acceptance. No new public feed/build/UI/Gmail or state
acceptance; October 19 at 19:40 ET deadline remains unchanged, no extension.


## October 15, 03:47 ET — Bounded collection assembly

Added a pure collection assembler requiring exactly all twelve current result
groups and ten schedule families. Every raw result page, official team mapping
and literal schedule validates before any collection is returned. The output
contains 24 results and ten separately keyed schedules, with explicit associations
for both Pick 3 sessions and Powerball base/Double Play. Keno/Racetrax retain
bounded-snapshot labeling. UTC/local date provenance and all source qualifications
remain intact; raw share counts, actual payout claims, retailer joins and historical
Lucky for Life/raffle results remain excluded.

Twenty-three combined Kansas Python tests pass. New collection checks cover
complete associations, missing/extra groups or schedules, invalid individual
result/schedule/mapping inputs, and missing/too-early retrieval timestamps.
Private fixture assembly is saved as assembled-fixture-collection.json under
work/kansas_scope; it is not a fresh network capture or published dataset.

Separately labeled advertised-prize handling remains pending; the collection
explicitly states it does not yet provide an advertised jackpot feed. Next complete
that source handling and atomic fresh import/regression protection, then scheduled
publication, app loaders/UI and native acceptance. No build/UI/Gmail, public feed
or state acceptance change. October 19 at 19:40 ET deadline remains unchanged.


## October 15, 04:48 ET — Separate advertised jackpot metadata

The collection now validates four separately dated advertised prize records for
Powerball, Lotto America, Super Kansas Cash and current-rules Mega Millions.
Direct source cash values and annuity values remain distinct; cash-only Super
Kansas Cash's zero annuity placeholder becomes no annuity value, never a zero
prize claim. Lifetime, fixed-prize and historical products are excluded from this
jackpot layer and retain their literal schedule treatment.

Raw UTC draw timestamps/source dates and derived America/Chicago dates are
preserved. A source draw time already passed at retrieval is explicitly marked
and must not be presented as upcoming. Advertised values are not actual winnings
or computed cash conversions. Required families, unique game identities, dates
and positive integer amounts validate before collection output.

Twenty-seven combined Kansas Python tests pass, including direct amount/date
provenance, historical/lifetime exclusion, passed-time labeling and ten invalid
metadata cases. This uses retained source fixtures, not a new network capture.
Next atomic fresh importer/regression guards and scheduled publication, then app
loaders/UI and native acceptance. No public feed/build/UI/Gmail or acceptance
change; October 19 at 19:40 ET remains the supported release deadline.


## October 15, 05:47 ET — Atomic fresh collection importer

Added the Kansas importer with explicit Powerball base/Double Play request
filters, twelve result-page requests, ten schedule pages, official team mapping
and advertised metadata. All inputs validate before atomic replacement. Per-group
window regression, changed timestamps on existing result identities, advertised
draw-date regression and retrieval-time regression reject the refresh. Unchanged
content retains prior bytes and retrieval time; failed requests/parses/replacement
preserve the prior file and temporary files are cleaned up.

Thirty-one combined Kansas Python tests pass, including request/parse/storage
failure preservation, unchanged timestamp/bytes, five regression variants and
explicit variant URLs. A fresh official network run succeeded with 24 results,
ten schedules and four advertised-prize records at
2026-10-15T09:47:02.440545+00:00. Private output is
work/kansas_scope/fresh-collection.json. Latest local dates include October 14
for Pick 3 and Powerball, October 15 for frequent-game snapshots and October 11
for Xs & Os; this is a bounded source window, not complete historical coverage.

Next scheduled Scratch/report transaction, staged publication and app loader/UI,
then native acceptance. No public feed promoted, build/UI/Gmail or acceptance
change. October 19 at 19:40 ET deadline remains unchanged, no extension.


## October 15, 06:48 ET — Scheduled collection transaction and publication staging

Kansas now declares Scratch plus the draw collection as a two-output scheduled
transaction. The collection command runs as a Python module from the repository
root. Failure at either importer restores both prior files and dates. The targeted
transaction suite passes with the Kansas failure-at-each-command case added.

The validated 24-result / ten-schedule / four-advertised-prize baseline retrieved
2026-10-15T09:47:02.440545+00:00 is staged in data and the public docs endpoint.
The publisher copies and commits this endpoint alongside existing state feeds.
Publication success and deployed-byte verification are still pending; the first
scheduled two-output success is a separate open checkpoint. App loader/UI and
native adoption remain pending. No build/UI/Gmail or state acceptance change;
October 19 at 19:40 ET deadline remains unchanged, no extension.


## October 15, 07:49 ET — Initial publication failed; repair retry queued

Publisher 38722671385 (049d1be) failed in the Python record/catalog test step;
deployment was skipped. This is not a verified public endpoint. The exact remote
traceback was unavailable through the accessible log endpoint. The full same
Python discovery command passes locally: 282 tests. Inspection identified a
cross-test import through the generic `test` namespace in the new importer tests,
which can collide with Python's installed standard-library test package. Removed
that dependency in 47f86f9 and reran all 282 tests successfully. This is a plausible
portability repair, not a proven remote root cause until CI confirms it.

Replacement publisher 38729732959 was queued on 47f86f9 at last check. Next verify
its result and deployed bytes before closing initial publication; scheduled
transaction success and app/native integration remain open. No acceptance or
deadline change; no build/UI/Gmail.


## October 15, 08:47 ET — Publication recovered and public bytes verified

Replacement publisher 38729732959 completed successfully on repair 47f86f9.
The deployed Kansas collection endpoint exactly matches both the committed data
baseline and docs copy (SHA-256
cbe8c3644e02aee8c3106debb3a9669133d94c31b608698e1a0d9292a7a9ddd9).
It contains 24 results, ten schedule families and four separately dated advertised
prize records; retrieval remains 2026-10-15T09:47:02.440545+00:00.
Public endpoint: https://apollohouser-cpu.github.io/lottery_atlas/kansas_draw_collection.json

Initial publication/recovery checkpoint is CLOSED. CI now passes after removal
of the cross-test namespace dependency; the earlier inaccessible traceback still
does not independently establish its precise failure mechanism. Latest scheduled
run 38728061316 used pre-repair 049d1be and failed before refresh/deployment, so
first successful scheduled two-output transaction remains OPEN. Do not equate
successful push publication with a successful scheduled source refresh.

Next strict Flutter collection validator/cache-remote-bundle loader, then UI and
native acceptance; native adoption is not yet claimed. No build/UI/Gmail or state
acceptance change. October 19 at 19:40 ET deadline remains unchanged.


## October 15, 09:50 ET — Flutter result validation foundation

Added result-only Dart validation for all 24 results / twelve groups. It checks
family/session/source/schedule identity, ordered number groups and bounds,
multiplier rules, official Xs & Os team mapping, Keno special-ball placement,
Racetrax order and per-group newest-first windows. America/Chicago timezone data
recomputes local dates from strict UTC source timestamps. Required provenance and
Tuesday eligibility warnings remain mandatory; unverified winner fields reject.

Two Flutter tests pass, covering the full baseline and thirteen malformed
variants; analysis of both files is clean. This is deliberately a result-only
validator, not full collection acceptance: schedule/advertised metadata validation,
continuity and cache/remote/bundle loader remain next before UI integration.
No full build/install or native claim. The user's Android emulator review remains
undisturbed following the separately recorded first-launch checkpoint. Kansas
release deadline remains October 19 at 19:40 ET; no Gmail or acceptance change.


## October 15, 10:49 ET — Flutter schedule validation

Added Dart validation for all ten schedule families / 21 tables / 139 rows.
Audited column order, row identities, spot-game titles, official PDF-card routes,
notes, qualifications, source warnings and coverage text are required. The one
known blank Keno basic-prize cell is permitted only at its exact source position;
other blank cells reject. Literal prize-cell updates can pass without arithmetic
or conversion. Changes to audited qualification/eligibility wording and card
metadata fail closed pending source review, rather than silently replacing limits.

Five combined result/schedule Flutter tests pass, including fourteen malformed
schedule variants and a valid changed literal prize value. Both new files analyze
cleanly. Full collection validation still needs advertised metadata and continuity,
then cache/remote/bundle loading before UI integration. No build/install/native
acceptance or Android review interruption. Kansas deadline remains October 19 at
19:40 ET; no Gmail or acceptance change.


## October 15, 11:50 ET — Complete collection validation and loading

Added full Flutter collection validation combining the prior result/schedule
checks with four separately dated advertised-prize records, literal cash/annuity
units, Chicago date provenance, passed-draw flag consistency and coverage limits.
Continuity rejects retrieval, per-group result-window and advertised-date
regressions, plus timestamp changes on existing result identities.

Added the cache/remote/bundle loader and registered the validated collection as
an app asset. Remote validation or request failure retains validated cache/bundle;
cache-write failure does not discard a valid response. Nine combined Kansas
Flutter tests pass, including malformed advertised metadata, continuity failures,
request/parse fallback, cold bundle and storage failure. Three new files analyze
cleanly. An initial test assumed the first advertised drawing had passed; changed
that test to invert the actual source flag, preserving the validation rule.

UI is not wired and no full build/native adoption is claimed. Next bounded
report/schedule/advertised-prize UI with mandatory source limits, followed by
Scratch all-tier audit and integrated native acceptance. Android user review
remains undisturbed. October 19 at 19:40 ET deadline unchanged; no Gmail or state
acceptance change.


## October 15, 12:51 ET — Collection UI connected

Kansas source page now opens the bounded collection sheet with all 24 selections,
separate sessions/variants, source timestamps/local dates, number order and team
labels. Advertised amounts appear in a separately dated section and passed draw
times are evaluated at display time. Literal schedules retain distinct column
labels, the explicit Keno blank, source currency strings, Racetrax PDF-card
routes, rules/qualifications and mandatory warnings. Fields have independent
semantic text nodes for long schedule traversal. Selection changes reset scroll.

Three widget tests pass: all 24 selections at compact and wide widths plus Keno
warning/retrieval/footer traversal. Three-file analysis is clean. The footer test
initially skipped a short text node with overly large scroll steps; smaller steps
verified it without changing app code. No full build/install/native/source-return
claim; Android user review remains undisturbed.

Next audit Kansas Scratch all-tier app coverage and remaining source disclosures,
then integrated native checks and scheduled transaction evidence. October 19 at
19:40 ET deadline remains unchanged. No Gmail or state acceptance change.


## October 15, 13:50 ET — Scratch app audit and coverage disclosures

Code inspection confirms the generic StateScratchGame projection retains only
name/cost/top prize/top-prize remaining and inventory note; it drops Kansas's
literal prizeTiers, source URL and both conflicting launch fields. The retained
Kansas catalog has 46 games / 425 tiers, including categorical FREE TICKET rows,
and null sourceDate. This is not yet all-tier app coverage. A dedicated strict
Kansas Scratch loader and literal tier UI are required before acceptance.

Added Kansas source-screen notices separating bounded results, literal schedules,
advertised values, excluded unverified winner counts, Scratch scope and missing
retailer joins. Cadence distinguishes six-hour app attempts from source-stated
hourly Scratch updates and unpublished verification time; UTC/local and launch
conflicts remain explicit. Added five official directory/retailer/promotion/
historical routes from retained source evidence. Three-file analysis is clean.
No runtime/source-return validation is claimed by these registry edits.

Next dedicated Scratch validation/cache/bundle and all-tier UI, then integrated
native acceptance and scheduled transaction evidence. No build/UI/Gmail or Android
review interruption. Kansas release deadline remains October 19 at 19:40 ET.


## October 15, 14:51 ET — Dedicated Scratch validation and loading

Added a Kansas-only Scratch cache/remote/bundle loader and registered its baseline
asset. Validation preserves every literal tier and both launch fields, requires
null source verification date, categorical FREE TICKET without cash conversion,
exact cash-label/value agreement and top-tier/count consistency. Source URLs,
unique game/tier identities, nonnegative remaining counts, scope limits and
launch-conflict disclosures are checked. Normalized start/source timestamps and
invented claimed/total fields reject. Continuity rejects retrieval/identity
regressions and anomalous large catalog loss; remaining counts may change without
being interpreted as sales or claims.

Five Flutter tests pass, including nine malformed variants, cold-bundle/cache
request failure retention, combined-feed Kansas-only caching, cache-write failure
and launch identity continuity. Two-file analysis is clean. The literal-tier UI
is still pending; no full build/install/native acceptance or Android review
interruption. Next search/price/reset/all-tier UI and official detail links, then
integrated native checks. October 19 at 19:40 ET remains unchanged; no Gmail.


## October 15, 15:51 ET — Literal Scratch UI connected

Kansas Scratch inventory now opens from the source page, compact Scratch action
and desktop catalog action. Search, ticket-price filtering and reset retain all
46 listed games and 425 literal tiers, including categorical FREE TICKET. Each
tier shows remaining prizes only; no claimed/total counts or cash conversion are
invented. Both conflicting launch fields, the inventory limitation, unpublished
source verification timestamp, retrieval time, cadence and coverage remain
visible, with official game-detail and catalog links.

Four widget tests pass: every game's literal tiers and footer at compact/wide
sizes, readable short-landscape viewport, and search/price empty-result recovery
and reset. Four-file analysis reports only the existing live-map brace-style
information at line 290. No full build/install/native or source-return claim;
Android user review remains undisturbed. Next integrated native checks and first
scheduled two-output transaction evidence. Kansas is not accepted; October 19 at
19:40 ET deadline unchanged. No Gmail or additional state activation.


## October 15, 16:50 ET — Scheduled two-output publication verified

Scheduled workflow 38774077176 succeeded from 92ef390 and produced bot commit
440e491. Kansas status explicitly reports updated for both Scratch and draw
collection outputs. Independent public downloads of collection, combined Scratch
catalog and refresh status exactly match committed bytes. Collection retrieval
is 2026-10-15T17:03:48.811238+00:00; Scratch retrieval is
2026-10-15T12:03:43.041103-05:00 with 46 games. Private downloaded evidence remains
in work/kansas_scope. The first scheduled two-output checkpoint is closed; native
adoption and integrated interactions remain open. Deadline unchanged.


### October 15, 16:50 ET — Current Android artifact prepared

Ordinary main.dart Android debug APK at 2c4b6ed builds successfully (Gradle14.3s;
167,669,700 bytes). Packaged Kansas collection and Scratch assets byte-match their
committed baselines. Build log is private work/mobile_beta/android-kansas-build.log.
Not installed or launched: the user's existing emulator review remains untouched.
This artifact includes the newly connected Kansas UI, but establishes compilation
only. Native Kansas interactions/source returns/adoption and full mobile acceptance
remain open; debug signing is not distribution signing. No additional emulator,
Gmail, account action or fees. No repeat build needed absent code changes.


## October 15, 17:51 ET — Android Kansas native checks started

Installed the prepared 2c4b6ed ordinary debug APK successfully on the existing
Android emulator; cold launch returned Status ok. No iOS simulator was booted,
no new build was needed and no additional emulator was started. Continued under
the user's authorization to control Android and the explicit cleared-review
instruction; earlier notes preserving the initial review are superseded.

Native search selected Kansas, displayed its no-mapped-activity notice, and the
compact menu opened the dedicated Scratch inventory. All 46 games are listed.
Game 257 shows separate conflicting launch fields and inventory limitations;
scrolling reaches FREE TICKET, unpublished verification time, cadence/coverage
and official source buttons. Footer screenshot confirms readable portrait layout.
Native retrieval 2026-10-15T21:33:00.108Z is newer than the packaged Scratch
baseline, establishing newer remote adoption for Scratch. Private screenshot and
UI evidence are in work/mobile_beta/android-kansas-*.

This is partial native evidence only: full tier traversal, filters, source return,
report interactions/adoption, wide layout and request-failure retention remain.
The app remains portrait at the Scratch footer. No state/mobile acceptance,
Gmail, fee or deadline change; Kansas remains due October 19 at 19:40 ET.


## October 15, 18:52 ET — Android Scratch interaction checkpoint

On the existing 2c4b6ed Android build, the official game-detail action opened the
correct Fire & Ice Tripler URL in the emulator's external WebView Browser Tester;
the official page rendered the game title, $75,000 top prize and $10 price.
Android Back restored game 257 and the exact footer scroll position. This is an
external browser return, not a Chrome/Safari-specific claim.

Native search for an absent name produced 0 of 46 and the empty-state message;
reset cleared the query. The $50 filter produced 2 of 46 games and selected game
417; reset returned 46 of 46 and game 257. Smaller scroll steps exposed all eleven
game-257 prize labels and remaining values, including $25 and FREE TICKET, without
converting categorical prizes or adding claimed counts. Source-date conflict and
scope notices remain visible. Private evidence: work/kansas_native/*.xml.

No build or reinstall was needed. The emulator remains portrait in the game-257
tier list. Remaining acceptance includes report groups/source returns/adoption,
wide layouts and native request-failure retention. No acceptance, deadline change,
Gmail or fees; Kansas remains sole active, due October 19 at 19:40 ET.


## October 15, 19:52 ET — Android collection adoption and 2by2

The source/coverage page opens the native collection on installed 2c4b6ed.
Retrieval 2026-10-15T21:25:47.612140+00:00 is newer than the packaged collection,
closing newer native collection adoption. Native 2by2 October 14 shows red/white
number groups and separate local date/raw UTC provenance. All eight literal
schedule rows, doubled-dollar source warning, free-ticket categories, Tuesday
eligibility and pari-mutuel qualifications, rules and footer were traversed.
The official 2by2 URL opened and rendered in the external WebView Browser Tester;
Android Back retained selection and footer scroll position.

Selecting October 13 reset scrolling and showed its different red/white groups,
source multiplier 2x and the qualifying-consecutive-day warning. Both 2by2 dates
are now checked. Private XML evidence is in work/kansas_native/2by2-*.xml.
No build/reinstall or second emulator. Remaining nine families/other groups,
wide layouts and native request-failure retention remain open. App left portrait
on October 13 2by2 summary. Kansas is not accepted; deadline October 19 at 19:40 ET
unchanged, scope already closed October 14. No Gmail, fees or user action.


## October 15, 20:53 ET — Android Lotto America checkpoint

On installed 2c4b6ed, Lotto America October 14 and October 12 selections show
distinct drawn numbers/Star Ball, multiplier and local/UTC dates; changing the
selection resets scroll. The advertised October 17 drawing remains separately
dated with source-supplied $2,250,000 annuity and $920,000 cash, not a calculated
award for either selected result. All nine literal schedule rows, doubled-dollar
warning, pari-mutuel/shared-jackpot qualifications, All Star Bonus jackpot
exclusion, rules and footer were traversed.

The official Lotto America page opened at its correct URL in the external
WebView Browser Tester and rendered the game title and October 17 next draw.
Android Back preserved October 14 selection/footer scroll. The external page's
compact headline reads $2.2 Million; no claim of exact headline formatting parity
with the retained API amount is made. Private XML evidence is in
work/kansas_native/lotto-america-*.xml. Same collection retrieval as previous
checkpoint; no repeat adoption claim or build. App left on October 12 summary.

Eight families plus remaining groups, wide layouts and request-failure retention
remain open. Kansas not accepted; October 19 at 19:40 ET deadline unchanged.
No Gmail, fees, second emulator or user action.


## October 15, 22:55 ET — Enlarged-text Scratch correction

Independent 390x844 widget checks at 2x text reproduced a 23px horizontal and
372px vertical overflow in Kansas Scratch: the unconstrained Reset filters
button squeezed the count label into an extremely narrow column. Constraining
the reset button with Flexible lets both labels wrap while preserving the tier
viewport. Six tests now pass (two new enlarged-text/footer checks for Scratch
and reports plus four existing Scratch layout/filter tests). Two-file analysis
is clean. No source validation or data changed.

The user-visible emulator was not navigated or restarted. Installed 2c4b6ed does
not yet contain this fix; a new ordinary build and native enlarged-text check
remain necessary. No full mobile/accessibility acceptance is claimed. Kansas
remaining native groups and retention checks remain open, deadline unchanged.


## October 15, 23:55 ET — Enlarged-text Android artifact ready

Ordinary main.dart debug APK at eeae509 builds successfully (Gradle 15.9s),
including the Kansas enlarged-text fix. Build log is private
work/mobile_beta/android-kansas-large-text-build.log. Not installed or launched;
existing emulator session remains untouched. No repeat build is needed absent
code changes. Prepared a private Kansas production-loader request-failure probe
for the remaining native cache-retention gate, adapted to the real Kansas cache
keys and retrievedAt field; it has not been built or executed and establishes
no retention result. No tracked probe code.

Next install ordinary artifact and verify enlarged text, then continue remaining
native report families and controlled retention/restoration. State and mobile
acceptance remain open, deadline October 19 at 19:40 ET unchanged. No Gmail,
fees, account action or additional emulator.


## October 16, 00:55 ET — Native enlarged-text correction verified

Installed the existing eeae509 ordinary debug APK; cold launch succeeded without
another build. Only the existing Android emulator was active. At system font
scale 2.0, Kansas Scratch count/reset controls remain separately readable, with
a usable tier viewport. Native scrolling traversed game 257's tiers, FREE TICKET,
source limits and both official-source buttons. Screenshot and XML evidence in
work/kansas_native confirm the corrected portrait layout. Search hint ellipsis
is visible at this scale; no broad accessibility certification is claimed.

Restored the exact prior system font setting and confirmed normal-size controls.
New installed build supersedes 2c4b6ed; the named enlarged-text Scratch overflow
checkpoint is closed. Eight remaining report families/other groups, wide layouts
and native request-failure retention remain open. App left on Scratch with normal
text. No Gmail, fees, additional emulator or deadline change; Kansas remains due
October 19 at 19:40 ET.


## October 16, 01:57 ET — Native request-failure retention verified

The private Android probe ran both production Kansas loaders against real
preexisting SharedPreferences caches while HttpOverrides forced exactly two
SocketExceptions. Returned objects equaled the decoded caches and both stored
JSON strings stayed byte-identical. Logcat recorded KS_NATIVE_RETENTION_PASS:
24 reports at retrieval 2026-10-15T21:25:47.612140+00:00 and 46 Scratch games at
2026-10-16T04:41:40.465046+00:00, sourceDate null. Evidence is private
work/kansas_native/retention-logcat.txt. This closes the production-loader
request-failure retention gate, not OS-offline, tiles or UI-outage acceptance.

Probe build passed (8.9s); ordinary lib/main.dart rebuild passed (6.2s), was
reinstalled and cold-launched successfully. Native Kansas Scratch reopened with
46 games and source limits. No tracked probe code remains, no second emulator
was started and normal text settings were retained. Ordinary source is eeae509
plus later documentation/feed commits; no probe entry point is installed.
Remaining report-family interactions and wide layouts are still open; no new
remote-adoption claim from restoration. Kansas deadline unchanged. No Gmail,
fees or user action.


## October 16, 02:57 ET — Native Scratch landscape completed

On the restored ordinary Android build, rotated the existing emulator to
landscape and verified side-by-side search/price controls, count/reset and game
selection. The readable tier viewport scrolls through all game-257 tiers,
FREE TICKET, unpublished source time, retrieval, coverage and both official-source
buttons. Screenshot work/kansas_native/scratch-landscape.png and bounded scroll
captures scratch-wide-*.txt retain evidence. No overflow observed in these
checked views; this does not certify all text scales or devices.

Restored both original Android rotation settings. Scratch wide-layout gate is
closed; report-wide and eight remaining report-family interactions remain open.
No build, repeated retention/adoption check, Gmail, fees or second emulator.
Kansas remains unaccepted with October 19 at 19:40 ET deadline unchanged.


## October 16, 03:58 ET — Native Mega Millions checkpoint

Ordinary Android collection reopened successfully after the earlier probe
restoration, now showing retrieval 2026-10-16T04:35:25.509106+00:00. Mega Millions
October 13 and October 9 selections show distinct numbers/Mega Ball and separate
local/UTC dates; selection change resets scroll. October 16 advertised annuity
$403,000,000 and cash $162,100,000 remain separately dated source values.
Traversed nine literal prize rows, five multiplier rows plus the average row,
doubled-dollar warning, jackpot installment/shared-prize qualification, rules,
per-play multiplier assignment and source-limit footer. No actual Kansas winner
counts or paid-prize inference.

Correct official megamillions URL rendered the game page in the external WebView
Browser Tester; Android Back retained selection and footer position. Private XML
is work/kansas_native/mm-*.xml. Left portrait on October 9 summary. Seven remaining
families/other groups and report-wide checks remain; no build, repeat retention
probe, Gmail, fees or deadline change. Kansas remains unaccepted, due October 19
at 19:40 ET.


## October 16, 04:57 ET — Native Millionaire for Life checkpoint

On the ordinary Android build, selected October 15 and October 14 results;
distinct numbers and preserved UTC timestamps/local dates are visible, and
changing selection resets scroll. Traversed all nine literal schedule rows,
annual-for-life prizes, pari-mutuel qualification, overall odds and explicitly
published cash-option amounts ($18,000,000/$2,200,000). These are source schedule
values, not calculated conversions or actual paid awards. Doubled-dollar source
warning, rules, purchase cutoff and full result/schedule limits remain visible.

The official millionaire-for-life URL opened and rendered the correct game page
in WebView Browser Tester. Android Back retained October 15 and footer position.
Private evidence is work/kansas_native/mfl-*.xml. Left portrait on October 14
summary. Six report families (including Pick 3 sessions and Powerball variants)
and report-wide checks remain open. No build, repeat cache-retention probe,
Gmail, fees or deadline change. Kansas is not accepted; October 19 at 19:40 ET
remains the supported-release deadline.


## October 16, 05:57 ET — Native Pick 3 checkpoint

Ordinary Android build: both Evening and Midday October 15/14 selections passed,
including leading zero 0-6-4 and repeated digits 2-7-7. Local dates and raw UTC
timestamps remain separate; Evening date rollover warning appears and selection
changes reset scroll. Traversed all three literal schedule rows with examples,
permutations, odds and $1-wager amounts, then rules, draw-session costs, liability,
purchase cutoffs and complete source-limit footer. The Any Order table/prose
inconsistency is explicitly warned and both source versions remain visible;
no inferred winner counts or actual payouts.

Correct official pick-3 URL rendered the game page and daily session information
in WebView Browser Tester. Android Back retained Evening October 15 and footer
position. Private evidence: work/kansas_native/p3-*.xml. Left portrait on Midday
October 14 summary. Five families (including Powerball base/Double Play) and
report-wide checks remain open. No build, repeated retention test, Gmail, fees
or deadline change. Kansas remains unaccepted, due October 19 at 19:40 ET.


## October 16, 07:01 ET — Powerball native checks and advertisement correction

Selected base October 14/12 and Double Play October 14/12 on Android, with
separate numbers, raw timestamps and local dates. Traversed all nine shared
schedule rows with separately labeled base/Double Play amounts, pari-mutuel and
shared-jackpot qualifications, Power Play exclusions/10X threshold, option costs,
rules, cutoffs and limits. Official powerball page rendered in WebView Browser
Tester; Back retained base October 14 and footer position. Evidence is private
work/kansas_native/pb-*.xml.

Native review exposed a real scope defect: matching advertisements by shared
scheduleKey displayed the base Powerball $600M annuity/$246M cash advertisement
on Double Play selections. Restricted advertisements to exclude Double Play;
its literal $10M schedule remains. A regression test verifies base advertisement
presence and Double Play absence. Four widget tests pass (including all 24
selections compact/wide), two-file analysis clean. Ordinary Android debug build
passed 14.1s, installed and launched. Fresh native dumps confirm both Double Play
dates now proceed directly from numbers to schedules, while base October 14
retains its separately dated October 17 advertisement. This named defect is
closed; no feed values or validation weakened.

Installed ordinary build supersedes eeae509 for the report widget. Left portrait
on base October 14 summary. Four remaining families (Super Kansas Cash, Xs & Os,
Keno and Racetrax), report-wide and final consolidation remain. Kansas not yet
accepted; October 19 at 19:40 ET deadline unchanged. No Gmail, fees or additional
emulator.


## October 16, 07:58 ET — Native Super Kansas Cash and Xs & Os

On installed ordinary Android build 5d22fca, Super Kansas Cash October 14/12
selections show distinct numbers/Cash Ball, preserved UTC timestamps and derived
local dates. Traversed all eight literal tiers, overall odds, shared-jackpot and
pari-mutuel qualifications, rules, cutoff and source-limit footer. October 17
advertised cash $1,405,000 is separately dated; official page formats its headline
as $1.4 Million. No conversion or actual paid-prize claim.

Powerball Xs & Os October 11/4 selections show distinct eight-team results and
UTC/local dates. Traversed all five literal tiers, odds, random-draw-not-NFL-outcome
qualification, shared-jackpot/lower-tier liability limits, rules and footer.
Both families opened the correct official game URL and rendered their game pages
in WebView Browser Tester; Back retained each selected report and footer position.
Selection changes reset scroll. Evidence is private work/kansas_native/skc-*.xml
and xo-*.xml. Left portrait on Xs & Os October 4 summary.

Keno and Racetrax native traversal, report-wide checks and final consolidation
remain open. No rebuild, repeat retention/adoption checks, Gmail or fees. Kansas
remains unaccepted; October 19 at 19:40 ET deadline unchanged.


## October 16, 09:00 ET — Native Racetrax checkpoint

Ordinary Android build 5d22fca: both retained Racetrax snapshots selected with
distinct ordered horses, timestamps and multipliers (1x/3x); selection resets
scroll. Explicit two-snapshot/not-live notice remains visible. Traversed all
12 horse Win/Show schedule rows, four prize-range cards and PDF link controls,
five bonus-probability rows, qualifications, liability limits, complete play
rules and source-limit footer. Full PDF matrices remain expressly unembedded;
no PDF opening or complete-matrix acceptance is claimed by this checkpoint.

Correct official racetrax URL rendered its game page in WebView Browser Tester;
Back retained the first snapshot and footer position. Private evidence is
work/kansas_native/racetrax-*.xml. Left portrait on the second retained snapshot.
Keno native traversal, report-wide checks and final consolidation remain open.
No build, repeat retention/adoption checks, Gmail or fees. Kansas remains
unaccepted; October 19 at 19:40 ET deadline unchanged.


## October 16, 10:00 ET — Native Keno checkpoint

Ordinary Android build 5d22fca: both retained Keno snapshots selected, with distinct
numbers, Bull's-eye, preserved source order and UTC/local timestamps. Two-snapshot,
not-live notice is visible. Traversed every 10- through 1-spot schedule and its
base/Bull's-eye fields, including the 6-spot match-one blank rendered explicitly
as blank in source rather than zero. Progressive amounts unavailable warning,
progressive qualifications, prize caps, pari-mutuel limits, play rules, cutoff
and full footer were reached. Selection change resets scroll.

Correct official keno URL rendered the game page in WebView Browser Tester;
Back retained the first snapshot and footer position. Private evidence is
work/kansas_native/keno-*.xml. Left portrait on the second snapshot. All ten
families/twelve groups now have native selection coverage and each family has
an official-page return; report-wide verification and final consolidation remain.
No build, repeated retention/adoption checks, Gmail or fees. Kansas is not yet
accepted; October 19 at 19:40 ET deadline unchanged.
