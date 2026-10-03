# New York supported-coverage acceptance

Activated October 2, 2026 at 19:00 ET as the sole active state after Virginia's
acceptance. Existing working imports qualify for 72 hours. Full game-scope
reconciliation is due October 3 at 19:00 ET; release decision is due October 5
at 19:00 ET. Supported available coverage accepted October 3 at 18:12 ET,
ahead of the deadline. Complete statewide claims remain separate.

## Opening inventory and bounded gaps

- 106 Scratch-Off catalog games; official catalog source retained.
- 13,161 mapped official directory entries, zero unresolved in the generated file.
- 1,601 public winner activity rows (111 Scratch-Off, 1,490 draw), source date
  October 2, 2026. This is selected published activity, not statewide all-tier claims.
- Existing state schedules include NUMBERS and Win 4 midday/evening, Take 5
  midday/evening, Quick Draw, Pick 10, LOTTO and Millionaire for Life; Powerball
  and Mega Millions are also required scope. Reconcile Money Dots, add-ons and
  historical Cash4Life against current official sources before closing scope.

## Acceptance checklist

- [x] Complete national/state draw and Scratch scope reconciliation, including
  available actual winner/tier reports, source cadence and explicit unavailable data.
- [x] Audit winner category and date semantics, distinguishing publication,
  processing and draw dates; do not infer ticket counts from ambiguous records.
- [x] Integrate supported reports and source routes with cache/bundle fallback.
- [x] Native compact/wide catalog, retailer, map, filters/reset, details/source/return.
- [x] Request failure/reconnection and preserved data semantics.
- [x] Focused automated validation, ordinary build and independent live evidence.
- [x] Consolidated release decision within deadline.

## October 2 opening defect correction

The winner importer used a loose prose capture for Scratch titles absent from the
current catalog. It produced 38 malformed titles, including sentences and personal
names. Unknown titles now display `New York Scratch-Off (game name unverified)`;
no prose span is used as a fallback title. Catalog-matched titles remain unchanged.

A fresh private official import produced 1,601 rows. An exact comparison verified
that only those 38 titles changed: every ID, category, date, count, prize, position,
retailer and source field remained identical, as did all top-level metadata.
The corrected generated activity was promoted and the combined publisher validated
23,921 records across 19 states. Private evidence is in work/new_york_acceptance.
Deployment verification remains pending; this closes only the malformed-title gap,
not the broader category/date audit or release acceptance.

## Private records remain separate

The 159,140 FOIL rows cover prizes of at least $600 from September 2025 through
August 2026. Repeated rows are preserved and are not established as distinct tickets.
The latest source-screen clarification says claim date is processing date, prize
amount is full prize amount, and agent identifiers are consistent/not reassigned
but indicate current locations. Historical selling-address correspondence is not
established. Scratch game numbers and update/correction semantics remain gaps.
No private claims layer or candidate retailer join is published by this change.

Opening mailbox check found no new agency replies. Latest successful publisher
37058132001 was a push, not proof of scheduled Nebraska/Texas recovery; that
bounded maintenance checkpoint remains open. Accepted states are not reopened.

## October 2, 20:00 ET — publication verification and date gap

Publisher 37075962240 succeeded; independent public activity JSON bytes match the
committed corrected feed. No new agency mail or scheduled recovery transaction
was found in the opening check. Nebraska/Texas scheduled recovery stays pending.

The importer audit confirms all `ny-winner-` Scratch rows use the archive
publication date, although the detail card previously called it DRAW DATE.
The card now says PUBLICATION DATE and explains that selected retailer-matched
releases do not establish draw/claim dates or complete statewide ticket counts.
Changed-file analysis passed. Native verification remains pending.

Draw press releases have different semantics: `officialDate` extracts a drawing
date when matched but silently falls back to publication date otherwise. This
needs a separate explicit date-kind audit before acceptance; the Scratch label
fix does not resolve press-row ambiguity or whole-day timeline behavior.

The [official Money Dots page](https://nylottery.ny.gov/money-dots) establishes a
separate wager/draw every four minutes, excluding 03:30–04:00, and separates it
from Quick Draw EXTRA. Add Money Dots and EXTRA explicitly to reconciliation.
The [official draw index](https://nylottery.ny.gov/draw-games/) links current game
information and the winning-number route. Direct HTML retrieval returned HTTP403;
the extracted winning-number page was a JavaScript shell. Neither proves actual
tier reports unavailable. Next bounded source inspection should use the working
official API/browser route to establish reports, jurisdiction and units for each
game, rather than treating odds tables or a cached zero as actual winner counts.

## October 2, 21:00 ET — official report API unlocked

Official HTML/JavaScript retrieval works with the existing importer user agent.
The site's app bundle calls `/nyl-api/games/all/draws`; this returns draw status,
results and upcoming entries, which must not be treated as published payouts.
The winning-number page instead calls
`/drupal-api/api/v2/winning_numbers?_format=json&nid=ID&page=0`.
Private responses and the actual rendering JavaScript are saved under
work/new_york_acceptance. Each inspected report endpoint returned 25 rows:

| Product | Official page ID | Latest report date observed |
| --- | --- | --- |
| Powerball / Power Play | 21 | September 30 |
| Mega Millions | 16 | September 29 |
| LOTTO | 26 | September 30 |
| Take 5 | 36 | October 2 |
| NUMBERS | 41 | October 2 |
| Win4 | 46 | October 2 |
| Pick 10 | 56 | October 1 |
| Quick Draw / Money Dots | 400 (Money Dots UI maps 401 to 400) | October 2 |
| Millionaire for Life | 374901 | October 1 |
| Historical Cash4Life | 31 | February 21 |

Responses separate local and national winners and multiplier fields. The official
renderer explicitly labels NY Winners, but also uses national counts and state
names in particular national-game summaries. For example, Powerball has a Texas
second-prize winner in national metadata while its local second-prize count is
zero. Do not treat the whole response as NY-only or add overlapping fields.
Power Play has a separate local_multiplier_winners array. Mega Millions exposes
additional per-tier multiplier arrays; reconcile their units and overlap next.
Quick Draw includes Money Dots secondary result/prize fields; no count inferred
from a drawn prize value. Seasonal Raffle appears in the live draw index but its
report route/period still needs reconciliation. API discovery alone does not
close scope or constitute app integration. Date-kind audit remains open.

Opening mail check was empty. Scheduled publisher 37082771578 (bot bb3b223)
succeeded. Nebraska completed unchanged and Texas updated its full five-file
transaction after the repairs. Independent public activity, catalog, directory,
Texas report and refresh-status bytes all match; that recovery checkpoint closes.
The same run newly retained South Carolina after failure: its three source files
are byte-identical to 24390d7. Investigate the named importer failure next session;
accepted UI coverage and stored data remain intact. No deadline changes.

## October 2, 22:00 ET — Powerball variants validated privately

The official rendering code selects base `local_winners`, Power Play
`power_play_local_winners`, and Double Play `dp_local_winners` separately.
The legacy `local_multiplier_winners` duplicates Power Play and must not be added.
A bounded parser now validates exact tier identities/counts (9/8/9), valid dates,
draw identity and multiplier, rejects missing/duplicate/conflicting tables, and
excludes national summary metadata and location fields. It preserves prize labels,
including the source's zero jackpot placeholder; no aggregate payout is inferred.

Three focused parser tests pass. Five captured official reports parse successfully;
September 30 totals are 37,530 base, 7,603 Power Play, and 4,432 Double Play
source-reported NY winners. These are separate variant totals, not a claim map or
verified distinct-ticket aggregate. Staged output stays private under
work/new_york_acceptance/powerball-reports.json; no report app integration yet.

Remaining semantics now explicitly include NUMBERS/Win4 winning-share wording:
the official renderer states shares use a combination of $1 and $0.50 wagers.
Do not label those source counts distinct tickets. Take 5 free plays and MFL annual
prizes require literal labels. MM multiplier arrays, Quick Draw/EXTRA/Money Dots,
seasonal Raffle and press-date provenance remain bounded reconciliation tasks.

SC maintenance diagnosis ran all three importers against copies of the retained
baseline: 10,215 mapped claim groups, 30 daily grouped titles for October 1 and
35 draw reports validated. No failure reproduced and no private output promoted;
this does not identify the scheduled failure's cause or prove deployed recovery.
Await the next scheduled transaction; if it fails again, inspect that run's failing
command before changing validation. Opening publisher/mail status was unchanged.

## October 2, 23:00 ET — Mega Millions multiplier tables

Official `da`/`gr` rendering code explicitly displays `prize_winners` as NY
Winners for each built-in multiplier; `mm_national_winners` is a separate national
summary. The parser preserves the local jackpot once and eight non-jackpot tiers
for each 2X/3X/4X/5X/10X group. It rejects missing, duplicated or unknown
multipliers and unavailable counts rather than filling zeros. Source prizes
already include their multiplier and are not multiplied again. National counts,
location metadata and inferred aggregate payout are excluded.

Five parser tests pass, including invalid-table cases. Five captured official
Mega Millions reports now stage privately alongside five Powerball reports.
September 29 non-jackpot NY counts reconcile independently across tier sums
0/0/11/38/803/620/4775/10928 to 17,175; the local jackpot count is zero.
No app/public report integration yet. Remaining state-game/seasonal scope and
press-date audit continue toward the unchanged October 3, 19:00 ET checkpoint.
Opening publisher 37088445239 succeeded (push, not scheduled SC recovery); no
new agency replies. No accepted-state maintenance checkpoint was repeated.

## October 3, 00:00 ET — LOTTO, Take 5 and MFL tier formats

Validated state-tier parsing now covers LOTTO, Take 5 and Millionaire for Life.
It requires exact unique tiers, nonnegative integer source counts, valid draw
identity/date, and recognized Take 5 Midday/Evening sessions. Free-play and annual
prize wording is preserved and guarded against silently becoming cash values.
National summary arrays and retailer details are excluded; no payout is inferred
from a zero jackpot placeholder or annual award.

Seven focused parser tests pass. Fifteen captured official state reports stage
privately, bringing the total to 25 across five games. Latest captured totals:
LOTTO September 30 10,812; Take 5 October 2 Midday 29,103 including 26,554 free
plays; MFL October 1 8,004. These remain source-reported NY winners, not verified
distinct-ticket counts or a retailer claim layer. No app/public report integration.
Next: NUMBERS/Win4 share units, Pick 10, Quick Draw/EXTRA/Money Dots, seasonal
Raffle and press-date provenance to close full scope by October 3 at 19:00 ET.
Publisher 37091883693 was successful push publication; no scheduled SC recovery
or new agency mail. Release deadline remains October 5 at 19:00 ET.

## October 3, 01:00 ET — winning shares and Pick 10

NUMBERS/Win4 parsers retain source winning shares separately from unavailable
winning-ticket counts. Identity combines wager type and tier (including both pair
rows), so repeated N/A labels cannot collapse distinct wagers. Pick 10 retains
its six reported winner tiers. The official renderer displays total_prizes as
dollars shared across prize levels; these totals are preserved, not calculated
from counts. Blank/zero tier-prize placeholders remain unavailable.

Nine focused tests pass. Fifteen additional captured reports stage privately:
40 reports across eight games in total, still outside the public/app report feed.
October 2 NUMBERS Midday has 10,918 shares and $699,600 reported total prizes;
Win4 Midday reports $197,900. Pick 10 October 1 has 5,116 reported winners and
$33,100. No inferred per-tier payouts, ticket counts or retailer allocation.
Next close Quick Draw/EXTRA/Money Dots and seasonal scope plus press-date audit,
then report integration. Publisher 37095198039 succeeded (push); no new mail or
scheduled SC recovery. Scope and release deadlines remain unchanged.

## October 3, 02:00 ET — Quick Draw / Money Dots dollars

The official winning-page Qn renderer displays the misleadingly named `jackpot`
field as Quick Draw dollars shared across prize levels, and `money_dots_prizes`
as separate Money Dots dollars. The parser now preserves these two payout totals
with unavailable winner counts, local draw time/number and the published multiplier.
It never divides Money Dots dollars by the drawn prize to invent counts or infers
separate EXTRA payout/counts. Empty arrays do not become zero winners. Explicit
zero-dollar results remain distinguishable from missing payout fields.

Eleven focused tests pass. Five captured Quick Draw reports stage privately,
bringing the total to 45 reports across nine report groups (including Money Dots
within Quick Draw). October 2 at 21:00 reports $1,305 Quick Draw and $45 Money
Dots, with winner counts unavailable. No public/app report integration yet.
Seasonal Raffle route/history and press-date audit remain; the web extractor
could not open /raffles, so use the official site navigation/API rather than
claiming absence. Scope due October 3 at 19:00 ET and release October 5 unchanged.
Opening publisher 37098535193 is successful push publication; no new agency mail
or scheduled SC recovery evidence. No accepted-state checks repeated.


## October 3, 03:00 ET — supported scope reconciled

Full per-game scope/gaps are now reconciled ahead of the October 3, 19:00 ET
checkpoint. This is scope closure, not implementation or release acceptance.

| Scope | Available source / implementation decision | Explicit gap or unit |
| --- | --- | --- |
| Powerball, Power Play, Double Play | Official tier report; parser staged | Separate NY variants; national summaries excluded; no inferred payout |
| Mega Millions | Official jackpot + five built-in multiplier tables; parser staged | NY counts separate from national counts; prizes already multiplied |
| LOTTO | Official five-tier report; parser staged | Source prize labels, no inferred jackpot valuation |
| Take 5 Midday/Evening | Official four-tier report; parser staged | Free-play tier preserved; sessions separate |
| NUMBERS / Win4 Midday/Evening | Official wager/tier shares and total dollars; parser staged | $1/$0.50 winning shares, not distinct tickets; tier payouts unavailable |
| Pick 10 | Official six-tier counts + total dollars; parser staged | Per-tier prize fields unavailable |
| Millionaire for Life | Official nine-tier report; parser staged | Annual-for-life wording retained, national summary excluded |
| Quick Draw / EXTRA / Money Dots | Official per-draw payout totals and multiplier; parser staged | No winner counts or separate EXTRA payout/count; Money Dots separate dollars |
| Historical Cash4Life | Official nid=31 historical report route | Latest captured February 21, 2026; not a current recurring schedule |
| Erie Canal Million Dollar Raffle | Official seasonal page route below | Historical 2025 event, no invented 2026 recurring schedule or mapped winners |
| Scratch-Off | Existing 106-game catalog and selected published winner releases | Inventory is not sales stock; publication dates are not draw/claim dates; incomplete claims |
| Private FOIL claim workbook | No public layer planned in supported release | Distinct tickets/historical retailer joins not established; audit held separately |

The actual site Raffles navigation resolves to
[Erie Canal Million Dollar Raffle](https://nylottery.ny.gov/erie-canal-million-dollar-raffle/).
Its JavaScript uses `/drupal-api/api/raffle_games?_format=json`. That source
explicitly says the drawing occurred October 26, 2025, correcting an October 25
misprint on tickets produced August 4–5. The live draw index's October 25 drawTime
must therefore not be blindly labeled the actual event date. Retain a historical
source route with this limitation instead of manufacturing a current report.
Private HTML/page-data/JavaScript/API evidence is saved in work/new_york_acceptance.

Next implementation gates: explicit press-row date provenance (parsed drawing vs
publication fallback), importer aggregation with duplicate/date regression guards,
report asset/cache/UI/refresh transaction, native and independent live acceptance.
No further broad scope research is needed. Existing parser tests are unchanged.
No new agency replies; publisher 37101743603 succeeded and scheduled37104043949
was still running at the single opening check. SC recovery remains unverified.

## October 3, 04:00 ET — complete report fetch transaction staged

The new importer fetches all nine current report groups, validates five recent
reports each, requires both Midday/Evening sessions for Take 5/NUMBERS/Win4,
rejects duplicate identities and per-game/session date regressions (including
Quick Draw intraday regression), then atomically replaces its output only after
all parsing succeeds. Historical Cash4Life and corrected seasonal Raffle source
routes are included. Twelve parser/continuity tests pass. A fresh official live
import validated 45 reports in private integrated-reports.json. No app/public
report asset or scheduled integration yet; next connect the loader/UI/refresh
transaction while preserving units and resolve press-date provenance.

Scheduled publisher 37104043949/ac2b8ac completed SC's full three-file transaction.
Independent activity, SC draw/daily and status public bytes match. The SC refresh
checkpoint is closed; no parser change or weakened validation was needed. No new
agency mail. New York remains active with unchanged release deadline.

## October 3, 05:00 ET — bundled report loading

Added the validated 45-report snapshot as a Flutter asset and a New York
remote/cache/bundle loader. It validates all nine game groups, variant/table
shapes, official provenance, unique report/tier identities and calendar dates.
Share counts remain separate from winners; Quick Draw/Money Dots payout dollars
retain unavailable winner counts. Literal prizes, source dates and historical
routes are preserved. Invalid responses cannot overwrite valid cache, and cache
write failure does not discard a valid response. Four focused loader tests pass;
changed-file analysis is clean. The reports are not yet navigable or published as
a standalone endpoint. Next implement the report sheet and refresh/publication
transaction, then resolve press-date provenance and complete native acceptance.
Opening publisher 37108450193 succeeded; no new agency mail. Deadline unchanged.

## October 3, 06:00 ET — report sheet integrated

The New York source screen now opens its report sheet with all 45 bundled
reports across nine groups. The selector preserves draw/session identity; each
variant has its own table. NUMBERS/Win4 display winning shares, unavailable tier
prizes remain unavailable, and Quick Draw/Money Dots display separate published
prize dollars with unavailable winner counts. Source labels, multipliers,
limitations, retrieval time, cadence and historical source routes remain visible.
All 45 selections pass compact (400×640) and wide (1280×900) widget checks;
changed-file analysis is clean. Native interaction remains unverified. Next
connect scheduled refresh/publication, resolve press-date provenance and perform
integrated native/live acceptance. Opening publisher 37112036089 succeeded; no
new agency mail. New York is not accepted; deadline unchanged.
Ordinary lib/main.dart macOS debug build also passed; running app has not been
relaunched for this change.

## October 3, 07:00 ET — report publication and refresh wiring

Added the report feed to New York's scheduled four-output transaction and staged
its public endpoint. Any failure in catalog, directory, selected releases or draw
reports restores all four previous files byte-for-byte. Five transaction tests
pass, including failure injection at each actual NY importer with real baseline
files. The publisher now copies and commits the validated report snapshot as
new_york_draw_reports.json. The initial endpoint contains the same 45 reports as
the bundled asset; deployment/live byte verification is the next opening check.
This wiring does not establish a successful scheduled refresh or native acceptance.
Opening publisher 37112036089 remained successful, and no new agency replies were
found. Next resolve selected-release date provenance and complete native/live
acceptance. Release deadline remains October 5 at 19:00 ET.

## October 3, 08:00 ET — release date provenance corrected

Publisher 37118515890 succeeded; the independent public NY report endpoint matches
all committed bytes. A fresh private winner import reproduces the current 1,600
rows exactly except source labels. All 1,489 press rows use publication fallback
under the existing explicit-drawing pattern; none establishes a draw date through
that parser. The 111 Scratch rows also use publication dates. Updated labels now
say so explicitly. Only source labels were promoted; original dates, positions,
counts, prizes and top-level metadata were preserved. No private claims promoted.

Extracted date parsing now returns explicit provenance, validates calendar dates,
and rejects future explicit draw dates. Three tests cover fallback, year rollover,
invalid dates and future dates. NY detail labels use publication date for these
rows; legacy press rows without explicit provenance use SOURCE DATE. NY timeline
now uses whole calendar days and Source dates. Changed map analysis is clean;
combined publication validation passes for 23,900 records across 19 states.
Native verification and a rebuilt ordinary app remain next, along with integrated
report/source/filter/failure acceptance. No new agency mail; deadline unchanged.

## October 3, 09:00 ET — native initial report route

Ordinary macOS debug build passed and was relaunched. Find a State → New York →
NY LOTTERY → reports works natively. Map shows whole-day Source dates and the
October 3 scoped-empty state. Mega Millions October 2 draw 2545 opens with NY
scope, unavailable publication date, distinct-ticket caveat, separate built-in
multiplier tables and literal source prizes. Scrolling exposes the no-inferred-
payout/zero-jackpot limitation, original retrieval timestamp, cadence and both
historical routes. Private evidence is in work/new_york_native. Source-open/return,
remaining game selections, wide layout and integrated map/catalog/failure checks
remain; do not repeat the completed opening route. Publisher 37121785820 succeeded
and public activity bytes match. No new agency mail or deadline change.

## October 3, 10:00 ET — source return and two more native games

Mega Millions source opens the official NY winning-numbers page with that game
selected and October 2 results visible. Returning retains the app selection and
footer scroll. Powerball September 30 draw 2006 was selected natively; scrolling
shows separate base, Power Play and Double Play tiers with NY counts and source
multiplier 04. LOTTO September 30 draw 4096 shows all five tier counts and literal
prizes plus statewide/not-retailer-claims limits. Private evidence saved in
work/new_york_native. Initial empty AX required mouse interaction; no general
accessibility certification claimed. Remaining six current report groups, wide
layout, map/catalog details and failure/reconnection remain. No new mail or
publisher change; deadline unchanged, state not accepted.

## October 3, 11:00 ET — remaining native report choices

All nine current report groups have now been selected natively. Take 5 October 2
Evening retains 45,089 free plays. NUMBERS and Win4 Evening show winning shares,
unavailable winner/ticket counts and tier prizes, with separate published dollar
totals ($366,635 and $821,850). Pick 10 October 2 shows its six reported counts,
$48,556 total and unavailable tier prizes. Quick Draw/Money Dots October 3 03:24
shows separate $366/$0 reported dollars, multiplier 01 and unavailable counts
without EXTRA inference. Millionaire For Life October 2 retains both annual-for-
life labels and nine tiers. Evidence is private under work/new_york_native.
Next wide layout and integrated map/catalog/detail/failure-reconnection; do not
repeat completed game choices. No new mail or publisher change. Not accepted;
October 5 19:00 ET deadline unchanged.

## October 3, 12:00 ET — wide layout and Scratch wording defect

Native enlarged MFL report (5120×2820 physical window) shows all nine rows,
complete footer and historical routes without clipping. Close/back returns to the
NY map; compact size restored. Scratch shortcut then exposed misleading “every
published Scratch-Off claim” wording for selected winner releases. Extended the
existing selected-release/publication-date disclaimer to New York. Native
verification of the corrected text remains after rebuilding/relaunching.

Scheduled publisher 37132443370/bot 3bc5c0b completed NY's four-output transaction;
independent report and status bytes match. This closes the scheduled integration
verification. No new agency mail; deadline unchanged and state not accepted.
Next verify the corrected shortcut, then catalog/retailer/detail/filter and native
failure-reconnection. Do not repeat completed wide report or game choices.
Changed map analysis and ordinary macOS debug build passed. Running app has not
been relaunched, so it still shows the before-fix shortcut.

## October 3, 13:00 ET — corrected Scratch and catalog return

Relaunched the ordinary macOS build and verified New York's native Scratch
shortcut now says selected winner releases, incomplete statewide claims and
publication dates. The full official catalog opens the loaded NY Scratch-Off
Games page with price filters, game numbers, remaining top prizes and claim
deadlines. Returning preserves the Scratch panel and October 3 source-date
context. Private native evidence is recorded under work/new_york_native.

Next retailer search/detail, winner publication detail/source, filter resets and
native request failure/reconnection. Completed report and catalog routes need no
repeat. No new mail or publisher change; October 5 19:00 ET release deadline
unchanged. New York is not accepted yet.

## October 3, 14:00 ET — native retailer search and detail

New York's directory opens with 13,151 official locations. Native search for
ACCORD FOOD MART returns one matching location; selecting it opens ACCORD FOOD
MART INC at 4990 Us Highway 209, Accord, NY 12404, Ulster County. The detail
explicitly says a directory listing alone does not create a heat-map win.
Official-directory, directions and favorite controls are present; no claim
activity was inferred from the listing. Private evidence is retained under
work/new_york_native.

Next winner publication detail/source, game/prize/date reset and native request
failure/reconnection, followed by final integrated acceptance. No new agency
mail or publisher change. New York remains unaccepted; release decision remains
October 5 at 19:00 ET.

## October 3, 15:00 ET — publication detail and official source return

Native date selection October 3 → October 2 restores two selected Take 5 release
records. Ulster → New Paltz → CITGO MART opens one reported ticket at 490 Main
St, with PUBLICATION DATE October 2 and the full selected-release/no verified
draw-or-claim-date disclaimer. The official source opens loaded press/381881,
matching the retailer and $15,888. That article describes the October 1 evening
drawing; the app correctly retains the October 2 publication date rather than
presenting it as the draw date. The importer has not extracted that draw date.
Return retains the same winner detail and disclaimer. Private evidence retained
in work/new_york_native.

Next game/prize reset and native request failure/reconnection, then consolidated
acceptance. No new mail or publisher change; deadline remains October 5 19:00 ET.
New York is not accepted yet.

## October 3, 16:00 ET — native game and prize resets

On the October 2 CITGO MART view, applying Powerball produces the scoped-empty
message. Applying All Games restores Take 5, one published record and $16K.
Setting the prize range to $17.5M–$60M likewise yields scoped-empty; restoring
the full range restores the same release while retaining October 2. The filter
sheet AX tree remained stale, so its choices, slider and Apply button were
verified through screenshots and mouse actions; the resulting map AX updates
confirmed both empty and restored states. This is not accessibility certification.
Private evidence is retained in work/new_york_native.

Next native request failure/reconnection and final consolidated acceptance/live
review. No new mail or publisher change; New York remains unaccepted with the
October 5 19:00 ET release-decision deadline unchanged.

## October 3, 17:00 ET — native request failure and reconnect

A private Dart HttpOverrides probe routed requests to an unavailable local proxy
while its flag existed. Native New York reports retained Mega Millions October 2
draw 2545, NY-only counts, literal prizes and the earlier retrieval timestamp
08:03:17.322 UTC. Removing the flag and reopening reports advanced the native
retrieval timestamp to 15:20:47.396 UTC, matching independently fetched live JSON
with 45 reports. Source limitations remained intact. This verifies Dart request
failure/reconnection, not OS-wide offline behavior or map-tile availability.
The private probe and live response are preserved under work/new_york_native.

Next final consolidated automated/live acceptance review and release decision.
No new mail or publisher change; October 5 19:00 ET deadline unchanged.
New York is not accepted yet.
Ordinary lib/main.dart macOS debug build passed and was relaunched; probe closed.

## October 3, 18:12 ET — supported coverage accepted

New York is ready for user testing for its supported available coverage. All
acceptance items above are closed by the dated evidence in this document.
Scope reconciliation closed October 3 at 03:00 ET; release is ahead of the
October 5 19:00 ET deadline, with no extension.

Current inventory: 106 Scratch-Off games, 13,151 mapped official retailers with
zero unresolved entries, 1,600 selected releases (111 Scratch and 1,489 draw),
and 45 rolling reports across nine groups. Powerball/Power Play/Double Play,
Mega Millions, LOTTO, Take 5, NUMBERS, Win4, Pick 10, Millionaire For Life and
Quick Draw/Money Dots are reconciled. EXTRA limitations and historical Cash4Life
and Erie Canal Raffle routes remain explicit. No private FOIL claims are public.

Final integrated verification: 39 JavaScript tests, five refresh-transaction tests
and 12 focused Flutter data/loader/compact-wide report tests pass. Ordinary
macOS build and restoration passed in the preceding session. Independent live
activity, NY report, shared catalog, shared directory and refresh-status files
all match committed bytes. Scheduled publication 37132443370 was previously
confirmed successful, including the four-output NY transaction. GitHub API status
retrieval returned transient 503/502 errors during this final pass; public feed
verification succeeded and no new publication failure is established.

Native evidence covers all nine report choices, compact/wide layouts, source and
return, Scratch catalog and corrected disclosure, retailer search/detail, winner
publication-date detail, date/game/prize filters and resets, scoped empty views,
and Dart request failure/reconnection. Native filter AX staleness is documented;
this is not full accessibility certification. Request-failure evidence does not
promise OS-wide offline behavior or offline map tiles.

Selected releases are partial, their publication dates are not inferred claim
or draw dates, source counts retain their units, and directory positions alone
create no wins. NUMBERS/Win4 shares, Quick Draw/Money Dots dollars, free plays and
annual-for-life prizes remain distinct. Full statewide claims and further private
records audits remain separate data work. No new agency replies or user action.
No successor state is activated by this decision.
