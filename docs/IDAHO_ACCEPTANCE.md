# Idaho supported coverage acceptance

Status: **ACTIVE — not accepted**. Sole active state from October 22, 2026
at 14:22 ET, after Iowa acceptance.

- Full supported scope CLOSED October 23, 00:29 ET, ahead of October 23 at 14:22 ET.
- Supported release decision due October 27 at 14:22 ET.
- Fresh 120 elapsed hours for substantial all-game collection/app integration.
- Extensions used: none. Finish early when evidence passes.

## Selection and opening evidence

Reviewed Idaho and Oklahoma source screens and existing collectors. Idaho has
an existing strict Scratch importer and a separate dated Idaho Cash API audit.
Those foundations reduce initial uncertainty but do not establish full draw
coverage or current native acceptance. The single-game audit is not a complete
working all-game import, so the substantial-implementation window applies.
No other state is activated; accepted states remain closed.

Fresh October 22 captures from the [official site](https://www.idaholottery.com)
and linked product pages are retained privately in work/idaho_scope with hashes
and retrieval timestamps. The navigation identifies eight draw families:
Powerball, Powerball Xs & Os, Mega Millions, Lotto America, Millionaire For Life,
Idaho Cash, Pick 3 and Pick 4. Scratch, InstaPlay, Tab games and the current
Raffle need separate dispositions. Two Xs & Os links returned identical bytes;
they must not become two games. These are opening observations, not closed scope.

Initial table inspection distinguishes Idaho and national winner tables. Pick 3
has Day/Night columns and leading-zero-sensitive digits. Powerball has Double
Play results and separate report columns; its Idaho table labels Powerplay and
Double Play, so a base-game count must not be invented. Mega Millions has five
per-play multiplier columns; do not assign a shared draw multiplier. Idaho Cash
free-ticket prizes remain categorical; published winner counts do not establish
distinct tickets or people. Next estimated jackpots and historical drawing
jackpots are separate fields. All match-image meanings, schedules, qualifiers,
report units, session/date joins and API routes still require validation.

The September retailer audit is not current address verification. No coordinates,
retailer-win joins, complete statewide counts or agency records are promoted.
The October14 unsigned nonresident form remains a separate correspondence item;
missing records do not block honest supported completion.

## Release gates

- [x] Reconcile every current product, variant, session, history limit and gap (scope only; implementation/acceptance gates below remain open).
- [ ] Validate actual dated source routes, count units and literal schedules.
- [ ] Strict bounded collection with atomic correction/failure retention.
- [ ] Fresh Scratch and separate instant-product dispositions.
- [ ] Remote/cache/bundle presentation with actual dates and limitations.
- [ ] Native selections, sources, full schedules, layouts and enlarged text.
- [ ] Inventory search/filter/detail returns and persistence/recovery.
- [ ] Ordinary build restoration, tests and independent live verification.
- [ ] Integrated supported acceptance and explicit unavailable features.

No public feed, app build, UI change or acceptance is claimed by activation.


## October 22, 15:31 ET — dated API and source-contract audit

Captured the site's three linked bundled JavaScript files and eight dated
API requests privately, with URL/hash/retrieval manifests in work/idaho_scope.
The date-picker script constructs `/api/v1/drawgame/{page-slug}/{date}`.
Seven requests returned dated game JSON; Millionaire For Life's October21
request returned HTTP404. Its visible HTML still contains results, schedules
and report tables, so this is an API-route limitation, not proof the game or
its reports are absent. Use verified HTML as a candidate source; do not invent
an alternate endpoint or carry a different game's data into it. The shared
check-number form defaults to Powerball on other game pages; exclude that form
from game-specific result parsing.

Observed API contracts and unresolved issues:

- Pick3 `winning_numbers`/`winners` and `_2` arrays correspond to the visible
  Day/Night columns. Source strings include trailing carriage returns; trim only
  explicitly allowed surrounding whitespace and preserve each digit, including
  Pick4 Night's leading zero. Pick3 has twelve API report entries, including
  three Sum It Up stakes, while the visible main table has nine rows.
- Pick4 API labels repeat Any Order 4 Way, Front Pair and $5 Sum It Up, with
  missing/distorted exact-any identities. These must not be repaired by position
  or converted into invented zero counts. Bound the display to unambiguous
  reviewed source rows or explicitly exclude ambiguous report coverage.
- Powerball Idaho `winners` contains nine base entries of zero plus eight Power
  Play entries. The site's own script filters only Power Play for the Idaho
  table. Do not publish the undisplayed base zeros as verified Idaho reports.
  Double Play has a separate result array and nine report entries.
- Mega Millions has41 labeled report entries: one jackpot plus eight rows for
  each of five per-play multipliers. The script inserts N/A jackpot cells in
  later multiplier columns; those inserted cells are not source zero counts.
- Lotto America separates nine base and eight All Star Bonus rows. Idaho and
  national arrays are distinct. Idaho Cash retains four categorical tiers,
  including Free Ticket; XsOs has eight numeric source team codes and five
  match-count rows. Team code-to-image mapping is still unverified.
- Powerball October21 API jackpot is635000000 while the visible past-draw row
  says638.6 million. Its API cash matches the page's next-estimate cash amount.
  Other fields also need date/provenance validation. Do not attach cash/next
  estimates to historical results or silently choose a conflicting amount.

The current Raffle page states sales began October21 and a December29 winner
announcement, with a separate daily promotion already showing a six-digit
number. The two-million-dollar-prize row's printed odds and the stated ticket
limit require explicit source-qualification review; never recalculate or correct
published odds silently. Separate final-draw status from promotional results.
InstaPlay and Tabs remain separate product scope, not Scratch aliases.

Next close all product dispositions and schedules, including image match labels,
Sum It Up, Raffle promotional/final distinction, InstaPlay/Tab inventory semantics,
and bounded history. Then implement strict parsers and atomic retention against
these reviewed contracts. No new public feed, app build, UI or acceptance; scope
and release deadlines remain October23/October27 at14:22ET, no extension.


## October 22, 16:29 ET — other products and image schedule scope

Captured all12 listed InstaPlay and11 listed Tab detail routes privately.
These are catalog observations, not remaining-prize inventories. InstaPlay tables
say Number of Prizes / Prize Amount / Odds; several progressive rows have $0
placeholders and $10 Cash Spot has all-zero prize amounts. Do not treat those
as zero-dollar prizes or remaining counts. Nine Tab pages are TouchTab wager/
top-prize/overall-odds tables; two are fixed prize schedules. Fractional wager
and prize values must survive. No remaining-count field is established for either
product type. Opening Scratch listing has32 cards; its existing strict detail
and claim-date validation must still run before a new accepted snapshot.

Visually reviewed the two official Sum It Up images and transcribed their literal
rows into tooling/idaho_sum_specs.json with exact image hashes: Pick3 has14 paired
sum rows; Pick4 has37 sum rows and explicitly labels a $1 wager. Pick3's image
itself lacks that heading, so its basis must be joined only to verified page text.
The pages prohibit this option for pair wagers (front/back for Pick3; front/mid/
back for Pick4). These are schedules, not actual winner counts. The specs are
reviewed inputs, not yet wired to a collector or app.

Planned bounded scope is now explicit: two available dated results for each of
11 groups across8 families (Powerball and Double Play separate; Pick3/Pick4 Day
and Night separate), literal main/option schedules and exact-date Idaho reports
where unambiguous. Missing/ambiguous report rows remain unavailable; specifically
exclude undisplayed Powerball base counts and unresolved Pick4 counts. Exclude
conflicting historical jackpot/cash values rather than choosing a value. Use
MFL HTML pending a proven dated route and preserve XsOs literal numeric source
codes plus official images without invented expanded team names.

Scratch remains a separate validated remaining-prize catalog with lower-tier
unknowns. InstaPlay/Tab receive separate catalog/rule/schedule presentation with
explicitly unavailable remaining counts and progressive placeholders; no false
Scratch inventory semantics. Raffle receives its source-labeled schedule and
separately dated daily promotion, with final drawing pending and printed odds
qualifications retained. History is the bounded presented window, not ten years.
Retailer lookup, claims/help, VIP and historical-game routes are source links,
not retailer joins, claims datasets or new account interactions.

The full-scope gate remains open for final rule/option and history reconciliation;
remaining work is concrete, including strict schedule contracts and product-field
validation. No feed/build/UI/acceptance or deadline change. Next implement the
bounded draw parser and hash-gated schedule contracts after final reconciliation.


## October 22, 17:32 ET — strict dated result parser

Implemented tooling/idaho_draw_results.py for the seven captured working API
families, producing ten distinct variant/session results per captured date set.
MFL remains excluded pending its HTML parser; this is not the full22-result
collection. Validation rejects wrong game/date/title/success, noncanonical or
future dates, missing/extra result arrays, invalid ball identity/order/range,
duplicate main balls, invalid multipliers and malformed Pick digit positions.
Only explicit surrounding ASCII whitespace is trimmed. Pick leading zeros and
literal two-digit XsOs source codes are retained; team names are not inferred.

The parser deliberately projects result fields only. Unreviewed winner arrays,
conflicting jackpot and cash fields cannot leak into output, and Double Play
has no inherited Power Play multiplier. Source URLs are exact dated API routes.
Seven regression tests pass against minimized public-source captures for all
seven families, covering ten groups plus mutation rejection and exclusion tests.
Fixtures contain only game/date/title/result arrays, no agency correspondence.

Next finish MFL HTML results, bounded two-date collection, reports and schedule
contracts; full-scope reconciliation remains due October23 at14:22ET. No new
feed, app build, UI, acceptance or deadline change.


## October 22, 18:28 ET — MFL HTML and Sum It Up validation

Implemented the MFL history parser against the actual dedicated history table,
excluding the shared Powerball check-number form. It validates the complete
published table before selecting two dates; wrong page/headers, bad older rows,
duplicate/unordered/future dates, invalid ball ranges and incomplete histories
fail closed. The captured October21/October20 results parse successfully. Generic
jackpot cells remain excluded from cash/annuity projections. This resolves result
access despite the dated MFL API404; no claim of API recovery.

Both reviewed Sum It Up images now have exact-byte hash gates that return the
literal transcriptions only on a match. Changed images require review; output
mutation cannot alter the retained specification. Added minimized public HTML
and image fixtures plus mutation tests. All17 Idaho Python tests pass (existing
Scratch tests included). No source refresh, public feed, app build or native
acceptance claimed. Next complete the bounded two-date collector, dated reports
and remaining schedule/product contracts, with scope reconciliation due October23
at14:22ET and release October27 at14:22ET unchanged.


## October 22, 19:31 ET — bounded result window staged

Added page-identity/history-date validation and a bounded window builder. It
selects two actual history dates for each API family; Pick pages expose only one
date, so the preceding daily date is a request candidate that must independently
return both sessions with exact game/date identity. MFL remains the dedicated
HTML source. All14 dated API responses were captured privately and validated with
the opening HTML pages, producing22 results across11 groups/8 families in
work/idaho_scope/result-window-stage.json. No winner reports, prize schedules,
jackpots or instant catalogs are included in that stage.

The first run correctly stopped on older XsOs string-valued weights. Inspection
showed canonical decimal strings in exact array order, unlike the latest integer
weights. Parser now explicitly accepts only those two equivalent encodings;
noncanonical strings, booleans, floating values and wrong order still fail.
All22 Idaho Python tests pass, including all14 request-failure positions,
wrong-date responses, missing pages and malformed older history dates. Failure
returns no partial window. This builder does not yet implement disk publication
or correction retention; those remain required before any public feed.

Next reconcile scope and finish exact dated report/schedule contracts and
coupled product collection. No public feed/build/UI/acceptance or deadline change.


## October 22, 20:31 ET — strict Idaho report projection

Added dated report parsing for the five reviewed API report families. It first
validates game/date/result identity, then exact ordered source tier labels and
nonnegative safe integer counts. Idaho arrays are used exclusively; national
arrays never substitute. Powerball exposes only its8 published Power Play rows
and9 separate Double Play rows, excluding undisplayed base zeros. Mega Millions
preserves41 multiplier-specific rows; Lotto America17 base/bonus rows; Idaho
Cash4 including categorical Free Ticket; XsOs5 match tiers. Counts remain labeled
published Idaho prize-tier winners, not distinct tickets/people or cash claims.

All14 captured dated responses validate:11 reports are available across the20
API-derived selections. The older XsOs October11 response has an empty report
array and remains unavailable, not zero. All8 Pick selections remain explicitly
excluded pending report/unit review. The two MFL HTML result reports still need
a separate exact-date report parser. No aggregates or inferred prizes are added.
All27 Idaho Python tests pass, including missing-versus-zero reports, national
isolation, malformed/duplicate tiers, unsafe counts and exact-date rejection.

This is a parser checkpoint, not published coverage. Next finalize scope and
literal schedule/rule contracts, MFL reports and product validation, then atomic
collection and app/native integration. Original deadlines unchanged.


## October 22, 21:30 ET — MFL exact-date report and integrated private stage

Implemented a strict MFL Idaho HTML report parser alongside its validated result
history. The parser requires the Idaho regional date control, exact headers,
all9 source match/prize identities and safe integer counts. The current October21
report joins only October21; October20 remains unavailable. Missing, duplicated,
wrong-region or malformed rows fail closed even when requesting an older date.
Annuity labels remain literal; no cash-option value or paid-claim inference.

The private window now joins each API report by its validated game/group/date and
MFL by its own HTML report date. Replaying retained October22 captures produces
22 results with12 supported reports and10 explicit gaps:8 Pick, older XsOs and
older MFL. This is work/idaho_scope/result-report-stage.json, not a public feed or
new source retrieval. All31 Idaho Python tests pass. Publication retention,
schedules, other products and app/native remain open. Scope/release deadlines
unchanged; next finalize the full scope and literal schedule/rule contracts.


## October 22, 22:27 ET — literal draw schedule contracts

Reviewed and gated all eight captured HTML prize matrices:70 physical rows,
with exact game titles, column headings, ordered match identities, ball-symbol
classes, literal cells and surrounding schedule text. Powerball preserves its
PowerPlay and Double Play columns separately and its conditional10x footnote;
no base schedule is invented. Pick3/4 retain the explicit $1 wager basis and
Idaho Cash retains categorical Free Ticket and quick-pick qualification.
Mega Millions' source heading literally says “Megaplier”; this legacy heading
is preserved as source text, not interpreted as a shared draw multiplier.

All eight retained full-page captures pass the contracts. All35 Idaho Python
tests pass, including removed/duplicated tiers, altered prizes/matches/symbols,
wrong titles/headers, changed qualifications and duplicate matrices. These
contracts cover the tables and their immediate qualifications only; broader
option, sharing, annuity and history rules still require reconciliation before
scope closure. No fresh retrieval, public feed, build, UI or acceptance claimed.
Next finish those rule contracts and product dispositions, then coupled atomic
collection. Original scope/release deadlines remain unchanged.


## October 22, 23:27 ET — draw rule prose contracts

All eight retained game pages now pass strict rule-prose contracts alongside
schedule validation. These retain purchase/option terms, Sum It Up exclusions,
annuity/cash alternatives and sharing/liability qualifications. No new source
retrieval is claimed. All39 Idaho Python tests pass, including changed/removed
prose and wrong-game rejection; presentation styles are excluded from rule text.

Explicit source discrepancies must accompany presentation: Powerball prose says
10x at $150 million or less while its footnote says under $150 million. Pick3
introductory 4-way wording conflicts with its 3-way schedule, and its repeated-
digit examples are inconsistent; never compute matching outcomes from those
examples. Both Pick pages have ambiguous drawing-time wording, so no corrected
cutoff is inferred. XsOs general split-prize language is qualified by the later
lower-tier liability-limit rule. MM's legacy table heading remains subordinate
to its explicit per-ticket multiplier description. These are source limitations,
not permission to silently repair official text or broaden counts.

Scope closure still requires final product/history dispositions and subsequent
strict product collection. No public feed/build/UI or acceptance; scope due
October23 14:22ET and release due October27 14:22ET remain unchanged.


## October 23, 00:29 ET — full supported scope closed

The following matrix closes the 24-hour scope definition gate. It defines the
required release implementation; it does not claim those features are already
published or accepted. Evidence is the retained October22 official captures,
reviewed contracts and earlier product audit. Release remains October27 14:22ET,
with no extension and Idaho the sole active state.

| Product | Required supported release surface | Explicit boundary |
| --- | --- | --- |
| Powerball / Double Play | Two dated selections each; separate results and Idaho reports; shared source page with correctly labeled PowerPlay/Double Play schedules and full qualifications | No undisplayed base winner counts; no conflicting historical jackpot/cash projection; conditional10x source discrepancy disclosed |
| Mega Millions | Two dated results, exact-date Idaho multiplier-tier reports, literal schedule and rules | Per-ticket included multiplier, never a common draw multiplier; legacy Megaplier heading disclosed |
| Lotto America | Two dated results, exact-date Idaho base/All Star Bonus reports, schedule and rules | National counts never substituted; jackpot sharing preserved |
| Idaho Cash | Two dated results and Idaho reports; schedule and rules | Free Ticket categorical, quick-pick qualification; no invented dollar value or distinct-person count |
| Millionaire For Life | Two HTML-derived dated results; report only for its own regional date; schedule and annuity/cash rule text | No invented API route or older-date report; static cash alternatives are rules, not actual paid claims |
| Pick3 / Pick4 | Two dates for each Day/Night group; literal schedules, all rule prose and hash-gated Sum It Up images | All eight report selections excluded pending count-unit/identity verification; leading zeros preserved; inconsistent Pick3 examples and ambiguous time wording disclosed, never used to calculate matches/cutoffs |
| Powerball Xs & Os | Two results with eight literal source codes and official images; exact-date Idaho report where present; schedule and full liability qualifications | No invented expanded team names; missing report unavailable; lower-tier sharing not inferred from general prose |
| Scratch | Fresh strict list/detail/claim-date collection, remaining-prize tier catalog, search/filter/detail/source returns | Opening32 cards are not a freshly validated inventory; lower-tier unknowns retained; no full stock, sales or claims assertions |
| InstaPlay | Separate typed catalog, detail rules and printed prize-count/amount/odds schedules for all listed games (opening12) | Printed counts are schedule counts, not remaining inventory; progressive and other $0 placeholders unavailable, not zero-dollar prizes |
| Tabs | Separate typed catalog and detail schedules for all listed games (opening11: nine TouchTab and two fixed schedules) | TouchTab wager/top-prize/odds and fixed prize tables stay distinct; fractional values preserved; no remaining inventory |
| 2026 Raffle | Literal seven-tier schedule/rules, final-draw status, separately dated daily promotional results with six-digit numbers | October22 capture has Oct21 promotional012426, not a final winner. Final announcement December29 12:20pm MT or within four business days after last ticket sold, whichever later. Printed top-tier odds1:225000 conflict with the stated500000-ticket limit/two prizes; preserve and label discrepancy, do not recalculate |
| History / retired games | Bounded latest-two windows per active draw group, explicit history limitation and official source navigation | No complete archive or ten-year claim. Retired games, including Lucky for Life, receive no active results or invented current schedule; historical import is unavailable in this release |
| Retailer / claims / VIP / help | Official source navigation with clear external destination | No retailer positions, coordinate joins, complete claims, account creation, submissions or attestations |

The draw target is22 selections /11 groups /8 families. Replaying the retained
captures currently yields12 exact reports and10 gaps, not a guaranteed future
report count. The current rule scope is eight HTML schedule matrices/70 physical
rows, eight prose contracts and two Sum It Up images/51 rows. No aggregate winner
count, complete statewide coverage claim or duplicate XsOs alias is permitted.

All products must carry actual retrieval/source dates, source URLs and limitations.
List/detail identity completeness and schema validation precede publication.
Coupled collection must stage all supported components, preserve prior bytes/dates
on request/parse/write failure, reject unreviewed corrections/regressions, and
publish atomically. UI/native gates must demonstrate all draw groups/both dates,
source returns, long schedules, separate product filters/detail returns, enlarged
text/layouts and remote adoption/failure retention, followed by ordinary-build
restoration and independent live verification. These gates remain open.

Next implement strict InstaPlay/Tab/Raffle parsing, refresh validated Scratch,
and assemble the coupled atomic collector; then public feed and app/native work.
Missing agency records do not block this bounded scope. No acceptance or new
public feed/build/UI is claimed by scope closure.


## October 23, 01:34 ET — strict InstaPlay detail schedules

Added reviewed contracts for all12 retained InstaPlay detail pages and110 literal
schedule rows. Exact title, rule text, odds-section qualifications, headers,
ordered counts/prizes/odds and count attributes must match before projection.
Changed details fail closed for review. Printed counts become schedulePrizeCount,
never remaining inventory. All source $0 amounts become unavailable with their
literal source label retained, including all seven $10 Cash Spot rows. No current
progressive jackpot is inferred. Published odds remain literal even where they
appear inconsistent; no recalculation is substituted.

All12 full captured pages validate; all43 Idaho Python tests pass, including
changed/missing rows, altered rules, wrong identity and placeholder semantics.
No new retrieval or public publication. Listing-to-detail completeness, Tab and
Raffle parsing, fresh Scratch and coupled atomic collection remain next; then
app/native integration. Scope remains closed and release October27 14:22ET is
unchanged. This detail-parser checkpoint is not acceptance or a new build.


## October 23, 02:36 ET — strict typed Tab detail schedules

Added exact reviewed contracts for all11 retained Tab detail pages/46 rows.
Nine TouchTab schedules project wager/top-prize amounts in integer cents with
literal overall odds; two fixed schedules project printed prize counts and
amounts separately. Fractional values such as $0.25 wagers and $50.75/$101.75
prizes survive exactly. Neither schedule type creates remaining-prize counts.
Rules and location/day-of-play redemption qualifications remain source text.
Changed headers, rows, identities or rules fail closed for review.

All11 full captured pages validate and all47 Idaho Python tests pass, including
wrong fixed/TouchTab variant, fractional money and malformed schedules. No new
retrieval, public feed or build. Next listing/detail completeness and Raffle,
then fresh strict Scratch and coupled atomic publication, followed by app/native.
Scope closed; release October27 14:22ET unchanged; no acceptance claimed.


## October 23, 03:33 ET — instant catalog completeness joins

Added strict list-to-detail collection for all12 InstaPlay and11 Tab games.
Reviewed listing identities, names, types and prices must match, and grid/detail
links cannot introduce unreviewed games. Each listed detail must validate with
its own typed parser before a complete result returns. Blank official game IDs
remain null; route slugs identify those games without inventing numeric IDs.
Catalog prices are separately labeled from TouchTab's multiple wager options.

Both full retained listings and all23 details pass. All51 Idaho Python tests
pass, including failure at each of23 detail positions, changed listings and
wrong-detail identity. This is an in-memory complete join, not disk publication
or a fresh retrieval. Next Raffle parser, fresh strict Scratch and coupled atomic
retention/publication, then app/native. Scope and October27 14:22ET deadline
unchanged; no new public feed/build/UI or acceptance.


## October 23, 04:38 ET — Raffle schedule and daily promotion parser

Added strict2026 Raffle identity, seven-tier schedule and full two-section rule
contracts. Daily promotion paragraphs are parsed separately: valid source-window
dates, six-digit tickets000001–500000, unique dates and agreement between both
published copies are required. Additional dated promotions can advance without
changing static rules; missing/malformed copies fail closed. Final results remain
unavailable and parsing stops for new review at the December29 announcement
period rather than silently retaining a pending status after it.

Retained October22 page validates with Oct21 promotional012426. Printed top-tier
odds1:225000 and the500000-ticket/two-prize discrepancy remain explicit; final
announcement qualifications and all claim/rule prose are preserved. All55 Idaho
Python tests pass, including promotion progression, leading zeros, copy mismatch,
invalid dates/numbers and changed odds/rules. No fresh retrieval or publication.
Next fresh strict Scratch and coupled atomic collection/retention, then public
feed and app/native. Scope closed; October27 14:22ET release unchanged.


## October 23, 05:34 ET — fresh Scratch source availability change

Fresh official listing now contains33 cards. Mistletoe Mystery (public game1933)
has blank remaining counts in all seven listed $25-plus tiers; its detail shows
*not available for those same tiers and launch date October22. This is not a
future-game exclusion or zero inventory. The existing strict importer correctly
rejected the listing; no public snapshot or source-date advancement occurred.
Raw listing/detail/claim captures and hashes are private under the dated
work/idaho_scope/scratch-refresh directory.

A diagnostic-only replay explicitly removed that one card to investigate the
rest:32 other games/225 inventory tiers validate against fresh details and claim
schedule. The private result is marked nonpublishable and is not a complete
catalog. All56 Idaho Python tests pass, including regression checks that blank
or unavailable high-tier counts cannot become zeros or lower-tier unknowns.

Next add an explicitly typed unavailable-inventory disposition for this game,
with full listing/detail identity and prize-structure validation, before coupled
publication. Do not silently drop it, weaken existing numeric validation or use
stale counts. This is a source availability change, not an extension: scope stays
closed and release October27 14:22ET remains unchanged. No public feed/build/UI
or acceptance is claimed.


## October 23, 06:39 ET — typed unavailable Scratch recovery

Added a separate reviewed unavailable-inventory type for Mistletoe Mystery,
without relaxing the existing numeric importer. Exact listing identity, blank
high-tier rows, detail image identity, price/top badges, all11 prize-structure
rows, launch date and qualifications must agree with the reviewed source.
Remaining counts stay null at every tier; original quantities are structure,
not inventory. Unreviewed blanks, partially changed availability, identity or
status changes fail closed. Numerically reported games retain strict validation.

Complete replay of the fresh October23 captures now retains all33 listed games:
32 numeric inventories/225 tiers plus one explicitly unavailable inventory with
11 structure rows. Private typed-coverage-stage.json is not yet a published feed.
All60 Idaho tests pass, including mixed known-zero/unknown inventories, duplicate
identity and fetch failure. The source-availability parser blocker is resolved;
coupled atomic collection/publication and app/native remain open. No newer
retrieval, source verification date, public feed/build or acceptance claimed.
Release October27 14:22ET unchanged. Next coupled collector and retention tests.


## October 23, 07:42 ET — fresh complete coupled in-memory collection

A fresh85-request official collection passed all supported components together:
22 draw selections with12 exact Idaho reports/10 gaps, eight schedule/rule
pages, both image schedules,12 InstaPlay/11 Tab details with complete listing
joins,33 Scratch listings (32 numeric inventories and one explicitly unavailable)
and the Raffle schedule/rules plus Oct21 daily promotion. Collection started
11:41:13UTC; individual actual retrieval timestamps/hashes are private in
work/idaho_scope/coupled-20261023T114113/manifest.json. Source verification dates
remain unchanged/unknown where not published; request time is not verification.

The new collector returns only after every component validates. Full replay
matches the complete private stage, and controlled failure at each of85 request
positions aborts collection. All63 Idaho Python tests pass. This establishes
complete in-memory collection, not atomic public publication or persisted-cache
retention. Next add correction/regression continuity and atomic disk replacement,
then audited feed/workflow integration and app/native. No public feed/build/UI or
acceptance yet; release October27 14:22ET unchanged.


## October 23, 08:46 ET — continuity and atomic snapshot retention

Added single-file atomic refresh around the complete collector. Existing draw
windows cannot regress; overlapping result/report corrections or loss of known
reports fail closed. Newly available exact-date reports may fill prior gaps.
Scratch identity/status/structure changes require review and known remaining
counts cannot increase. Instant catalogs and rule contracts must remain equal;
Raffle promotion history cannot disappear or change. Unknown-to-known Scratch
status currently requires review rather than silently changing representation.

Unchanged content retains original bytes and collection date. A unique staged
file is flushed before replacement; concurrent snapshot changes abort, and failed
replacement cleans the temporary file. All67 Idaho tests pass, including count/
date corrections, request failure, disk-replace failure and unchanged-byte/date
retention. Full85-request retained-source replay initially writes successfully;
controlled failure at every request preserves the prior complete snapshot bytes.
Evidence is private atomic-replay-checks.json beside the prior coupled capture.

No fresh retrieval, public feed, native build or acceptance. Next audit/export
the coupled baseline and wire scheduled publication, then app/native integration.
Release October27 14:22ET unchanged; scope remains closed.


## October 23, 09:46 ET — audited coupled baseline and publisher wiring

Staged identical public data/idaho_coverage.generated.json and
 docs/idaho_coverage.json from the fully replay-validated October23 11:41:13UTC
collection (223591 bytes each). All85 evidence URLs are public official sources;
no private correspondence, local paths or agency identifiers enter the baseline.
The feed retains all products, unavailable inventory and explicit report gaps.

The scheduled Idaho transaction now invokes the coupled collector and preserves
that single baseline on failure. Workflow staging/commit paths include the new
feed. The old data/idaho_scratch_catalog.generated.json remains byte-for-byte
unchanged with its original date; its numeric-only legacy schema cannot represent
the new unavailable game. It is not refreshed or relabeled as this complete
snapshot. The forthcoming Idaho app integration must use the coupled feed for
current typed coverage. No legacy zero-count substitution or silent game removal.

All476 Python tests pass, including67 Idaho tests and existing transaction tests.
This checkpoint prepares publication; deployment/live-byte confirmation remains
next, followed by Dart loader/UI and native acceptance. No native build or state
acceptance; October27 14:22ET release deadline unchanged.


## October 23, 10:44 ET — coupled deployment verified

Publisher run39964023035 for fac9587 completed successfully. Independently fetched
https://apollohouser-cpu.github.io/lottery_atlas/idaho_coverage.json and compared
all223591 bytes with the audited tracked baseline: exact match, SHA256
adcb110a68d8220120b4cd91b7f2bae48eb9bd974812f1351db339f9980e6642.
This closes initial feed deployment, not mobile acceptance. No source retrieval
date was advanced by checking the hosted copy.

Next implement the Idaho Dart validator/loader with bundled fallback, strict
dated result/report and typed product validation, and cache continuity before
visible UI integration. Do not adopt only the old numeric Scratch feed or turn
unknown inventory into zeros. The remaining work is draw/product presentation,
native traversal and cache recovery/ordinary-build restoration. No new native
build or state acceptance; October27 14:22ET deadline unchanged.


## October 23, 11:46 ET — initial Dart baseline loader

Added the coupled Idaho asset, loader and audited baseline contract. Cache and
bundle fallback preserve typed unavailable inventory, including Mistletoe Mystery;
a rejected or failed remote request does not write over the retained cache.
A valid remote response remains usable if persistence fails.

This is an initial exact-content gate, NOT completed app integration: advancing
source dates/counts currently fail closed. Next replace the baseline restriction
with strict dated result/report and typed product validation plus continuity
before wiring visible screens. No UI or native build changed, and no acceptance
or deadline change. Five Flutter tests pass; the three production Dart files
and test analyze clean. Existing Python publication checks remain unchanged.


## October 23, 12:46 ET — Dart numeric Scratch continuity

The coupled loader now accepts decreasing known Scratch remaining quantities
while preserving reviewed game/tier identities, original quantities, source
metadata and explicit unknown status. Top-prize summaries must match the first
tier. Increased, fractional or negative counts, missing games/tiers, changed
structure and invented source dates fail closed. Continuity compares with the
retained cache, not only the bundled baseline. Eight Flutter tests pass,
including remote adoption and retention against a newer lower-count cache.

Draw/date/report advancement and Raffle promotion advancement still require
their strict dynamic validation before visible UI integration; their current
exact-baseline gate remains. No native build, acceptance or deadline change.


## October 23, 13:46 ET — Dart Raffle promotion validation

Raffle daily promotions now advance independently of the unavailable final
drawing. Validation requires ordered unique real dates within the reviewed
October21–November9 promotion window, no later than the Boise collection
calendar day, and literal six-digit ticket numbers 000001–500000. Existing
promotions cannot disappear or change against either baseline or retained cache.
Rules, schedules, edition, limitations and final-result status remain exact.
Collections entering the December29 final-announcement period require review.

Twelve Flutter tests pass, including synthetic promotion adoption, date/ticket
rejection, Boise midnight boundary and correction/loss cache retention; changed
Dart and test analyze clean. These synthetic tests do not assert a new source
result. Draw/date/report advancement is still exact-baseline gated and remains
next before visible UI. No source refresh, native build, acceptance or deadline
change.


## October 23, 14:41 ET — dynamic Dart draw/report validation

Replaced the exact draw baseline restriction with strict validation of all eleven
groups/two dates: ranges, unique main balls, Pick digit/session identity,
Powerball/Double Play separation, per-draw multiplier constraints, literal XsOs
codes/images, canonical dates and Boise collection-day bounds. Source routes and
report joins must match the result date; Idaho labels, tier order, count units,
free-ticket categories and all reviewed limitations remain exact. Counts must be
nonnegative safe integers; Pick reports remain excluded. A missing exact-date
report may become available; existing reports/results cannot change or disappear
for retained dates. Every group's two-date window must progress without regression,
including paired PB/DP and Pick Day/Night dates.

Seventeen Flutter tests pass, including synthetic advancement of all groups,
report availability upgrade, invalid identities/ranges/counts and cache retention
after corrections/regressions. Changed Dart/test analyze clean. These are loader
tests, not new source or native evidence. Next visible draw and typed-product
integration, then native traversal and ordinary restoration. No native build,
acceptance or deadline change.


## October 23, 15:43 ET — visible Idaho draw integration

Added Idaho results/schedules entry to the state source screen, backed by the
coupled validated loader. All22 bounded selections expose exact Idaho report
labels/tiers or explicit gaps, literal schedule rows and footnotes, reviewed rule
prose/discrepancies, and both Sum It Up image transcriptions with their source
wager-basis limitations. Powerball/Double Play columns remain separately labeled
with a shared-page warning; MM has no shared draw multiplier. XsOs remain literal
source codes. Fixed previous/next-page controls and official source actions are
available; selection changes reset the reading position.

Twenty Idaho Flutter tests pass: seventeen loader tests plus all22 selections at
2x, Double Play warning traversal, and all eight family schedules plus DP to their
final source in portrait/landscape at2x. Sheet/source screen/test analyze clean.
These are widget checks, not native acceptance. Next typed Scratch/InstaPlay/Tab/
Raffle UI, then ordinary native build and acceptance flows. No new native build,
source retrieval, acceptance or deadline change.


## October 23, 16:44 ET — typed product presentation

Added a separate Idaho product catalog entry using the coupled loader: Scratch
includes all numeric games plus the explicitly unavailable game; InstaPlay/Tab
catalogs show printed schedules and distinguish TouchTab wager/top-prize rows;
Raffle daily promotions remain separate from its unavailable final drawing.
Search, listed-price filters, reset, detail return, fixed paging and official
sources are available. Unknown inventory and progressive placeholders are labeled
unavailable, never zero. Collection time is not called an inventory verification
date; source qualifications and game dates remain visible.

Two new widget tests pass across all four product types with detail/source
traversal at2x portrait/landscape and unavailable Scratch search/detail return.
Product sheet/source screen/test analyze clean. Prior20 Idaho tests are unchanged.
Next ordinary native build and all draw/product/source-return/layout/cache
acceptance flows; no native build, source refresh, acceptance or deadline change
at this checkpoint.


## October 23, 17:42 ET run — ordinary native build and first bounded flows

Built ordinary `lib/main.dart` from b8b99a2 for iOS simulator, installed and
cold-launched on the original iPhone17e (process 52158). Android remained stopped;
no probe entrypoint was used. Native Idaho source-screen entries opened both
draw and product sheets. In normal-text landscape, the first Powerball summary
showed the October21 result and original October23 collection timestamp. This
is initial native evidence only, not all-selection acceptance.

Searched Scratch for Mistletoe, observed 1 of 33 catalog entries, and opened
Mistletoe Mystery 1933. Fixed paging traversed all eleven original-structure
prize rows to the official source control; remaining counts stayed explicitly
unavailable. The control opened Safari at idaholottery.com with the Mistletoe
Mystery page title (page content was still loading when observed). Returning to
the same running app retained the detail reading position. Closing details
retained the Mistletoe query and one-result list. No source-page-content load
claim is made.

Next: remaining draw selections/dates/family source returns, full schedules,
other product/filter flows, portrait and native2x layouts, newer remote adoption
and controlled loader-failure retention. Ordinary build is running; complete
native acceptance, cache checks and final restoration remain open. No source
refresh, acceptance, extension or deadline change.
