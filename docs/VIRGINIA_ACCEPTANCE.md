# Virginia supported-coverage acceptance

Activated October 1, 2026 at 19:02 ET. Release decision due October 4 at 19:02 ET;
full per-game reconciliation due October 2 at 19:02 ET. Not accepted. Agency
request declined September 23; no new request, eligibility assertion or fee is
required for public-source completion.

## October 1 opening inventory (20:00 ET)

The [official home page](https://www.valottery.com/) currently lists Powerball,
Mega Millions, Millionaire for Life, Bank a Million, Cash 5, Pick 3/4/5, Cash Pop,
Keno and the seasonal New Year's Raffle. Existing app schedules cover the recurring
state games, with day/night Pick sessions and five Cash Pop sessions; national
Powerball/Mega Millions are also in scope. Cash4Life remains a historical release
category, not a current recurring schedule. Scratchers, Print 'n Play and online
products are separate categories and must not be silently classified together.

| Game/category | Existing implementation | Named verification/gap |
| --- | --- | --- |
| Powerball / Power Play | National filter plus selected VA winner releases | Official results/prize odds page inspected; per-draw VA tier counts not established by that page's extracted text. Inspect past-results data before declaring unavailable. |
| Mega Millions | National filter plus selected VA releases | Same bounded past-results inspection; prize odds are not actual winners. |
| Millionaire for Life | Current schedule and importer classification | Official current page verified; inspect available result/count detail. |
| Bank a Million | Schedule, classification and selected releases | Reconcile official game results and any available statewide count report. |
| Cash 5 with EZ Match | Schedule, classification and selected releases | Distinguish draw results from EZ Match and any winner counts. |
| Pick 3, Pick 4, Pick 5 | Day/night schedules and classification | Reconcile FIREBALL/session/source-date semantics and any available count reports. |
| Cash Pop | Five session schedules and classification | Keep each session separate; no counts inferred from odds. |
| Keno | Four-minute schedule and classification | Establish available report scope/cadence without promising a live four-minute feed. |
| New Year's Millionaire Raffle | Selected releases classified as state draw | Seasonal official page exists; verify seasonal source link/coverage rather than invent recurring schedule. |
| Cash4Life | Historical release classification | Preserve historical identity without treating as current game. |
| Scratchers | Maintained official retail catalog/top-prize inventory | Native catalog/filter/unknown semantics and freshness checks. |
| Print 'n Play / online products | Outside the current retail Scratcher catalog | Audit winner fallback classification so unmatched releases are not silently treated as Scratch. |

This is the opening inventory, not completed full per-game reconciliation. The
remaining source inspections above are bounded to determining existing available
report coverage; do not wait for the declined agency request.

[Powerball](https://www.valottery.com/data/draw-games/powerball),
[Mega Millions](https://www.valottery.com/data/draw-games/megamillions),
[Millionaire for Life](https://www.valottery.com/data/draw-games/millionaireforlife)
and [Raffle](https://www.valottery.com/data/draw-games/raffle) were inspected.
Search/cache dates differed between requests; do not infer retrieval or source
freshness from a stale page excerpt.

## Current committed baseline

October 1 generated catalog contains 96 retail Scratchers. Directory coverage
reports 5,425 unique official retailers, 5,360 verified coordinates and 65
unresolved addresses excluded from map positioning. Winner feed contains 110
retailer-matched releases across 2024–2026, including 67 in the 2026 launch window,
with source publication through September 23. These supersede the September 15
source-screen counts, not their limitations. Current-directory address joins are
not proof of historical directory completeness.

The 2026 releases include Powerball (9), Mega Millions (3), Raffle (7), Cash 5 (5),
Bank a Million (4), Pick 5 (3), Pick 4 (2) and Cash4Life (1), plus entries currently
classified as Scratch. Absence of mapped releases for another game is not zero
statewide winners. These are releases, not complete all-tier claims.

Observed date-label defect: live_lottery_map.dart falls through to DRAW DATE for
VA releases, although the importer stores publication timestamps in drawDate.
Correct to publication/notice date, explain unavailable actual draw/claim time,
and audit timeline precision before native acceptance. Also audit the importer's
unmatched-game fallback to Scratch. These are accuracy gaps, not enhancements.

## Release checklist

- [x] Finish national/state/seasonal game scope and available-report reconciliation (October 2, 03:00 ET; implementation/acceptance still pending).
- [x] Correct publication-date presentation and audit unmatched classification (native detail verified October 2, 12:00 ET).
- [ ] Verify catalog, retailer/source limitations and available draw routes.
- [ ] Native state/county/game/prize/date filters, reset, scoped empty/detail/source.
- [ ] Compact and larger integrated layouts, offline/cache and reconnect behavior.
- [ ] Relevant automated/build checks and independent live validation.
- [ ] Record supported-coverage decision before deadline.

Opening repository clean; publisher 36908045746 successful; no new agency reply
beyond already-recorded New Mexico/Michigan messages. No accepted state reopened.

## October 1 publication-date correction (21:00 ET)

VA winner-release details now say PUBLICATION DATE and explicitly distinguish
that timestamp from unknown draw/claim dates. Virginia timeline uses the existing
whole-day mode with Published dates labeling; publication hour is not represented
as the time a ticket won. Stored source timestamps and all activity counts remain
unchanged. Ten existing Virginia data/offline and calendar tests passed, changed
map file analysis is clean, and macOS debug build passed. Native verification of
the rebuilt correction remains pending. Unmatched-game audit and full per-game
report reconciliation remain open; deadline unchanged.

Opening publisher36946945721 succeeded; bot73a9d76 integrated. Virginia outputs
unchanged. Live refresh-status bytes match. Nebraska newly retained after failure;
TX remains retained after failure, NH/Colorado likewise. All their listed prior
state files byte-match the preceding local957f972 baseline. No lost validated
data or changed retained source dates. No new agency reply.

## October 1 official report API audit (22:00 ET)

The official game pages' own `app.bundle.js` uses form POST
`https://www.valottery.com/api/v1/drawnumbers` (`gameId`, `page`, `pageSize`)
and `/api/v1/prizesandodds` (`gameId`, `drawingDate`). Read-only requests returned
actual dated results and report detail. Private raw responses and source HTML/JS
are retained in `work/virginia_scope`; no ticket identifiers or new activity were
published. This supersedes any assumption that only winning numbers/odds exist.

| Game / API ID | Observed available report | Required interpretation / implementation |
| --- | --- | --- |
| Powerball / 20 | September 30 match tiers, winner counts and prize strings | The report explicitly identifies a Match 5 winner in Texas. These counts cannot be labeled Virginia totals. Preserve jurisdiction uncertainty and prize wording; audit any separate Power Play availability. |
| Mega Millions / 15 | September 29 match tiers, counts and prize ranges | VA-specific jurisdiction is not established; do not allocate the website's counts to VA. Preserve ranges rather than inferred payout. |
| Millionaire for Life / 1075 | September 30 nine match tiers | Source explicitly says the table shows Virginia wins and excludes outside-VA jackpots. Preserve annual-payment descriptions. |
| Bank a Million / 1070 | September 30 eight match tiers/counts/prizes | Preserve after-tax jackpot wording and source wager basis. |
| Cash 5 / 1030 | September 30 plays matching each tier plus separate base and EZ Match prize totals | Base total $8,519 equals 8×$200 + 374×$5 + 5,049×$1. EZ Match is $8,070. Totals are dollars, not counts; official template says online and retail wins are included. |
| Pick 3 / 1050, Pick 4 / 1040, Pick 5 / 1035 | Day/night dated results, separate base and FIREBALL totals | Official rendering explicitly prefixes totals with dollars and includes online and retail wins. No tier-count breakdown in sampled responses; do not manufacture one. |
| Cash Pop / 40 | Five session results and prize totals | Template labels totals as dollars. Publication flags distinguish available sessions from not-yet-published sessions: October 1 After Hours zero with false flag is not an observed zero payout. |
| Keno / 30 | Dated four-minute results, spot-game match tables and payouts | Count heading is `#OfShares`, not distinct tickets. Keep spot games separate; a scheduled snapshot is not a live four-minute feed or complete historical coverage. |
| New Year's Millionaire Raffle | Seasonal page announces 1,012 winners and links January 1, 2026 complete winning-number PDF, plus earlier years | No recurring draw API ID on this page. Preserve seasonal date and link to official report; do not publish ticket-number rows as map activity. |

Sources are the official game routes under
[Virginia draw games](https://www.valottery.com/alldrawgames), the pages linked
above, and [Raffle](https://www.valottery.com/data/draw-games/raffle). The official
JS template resolved dollar-versus-count ambiguity for Pick, Cash 5 and Cash Pop;
API field names alone would have produced false winner counts.

These are source-availability findings, not yet an app report or acceptance.
Next: finish bounded Power Play/jurisdiction and unmatched Print 'n Play/online
classification reconciliation, then implement validated reports with source dates,
sessions, units and limitations. Keep historical Cash4Life distinct and retain
Scratch catalog/inventory semantics. Full reconciliation deadline remains October
2 at 19:02 ET; release deadline remains October 4 at 19:02 ET. No native flows
repeated. Publisher and agency inbox unchanged at the single opening check.

## October 1 winner classification correction (23:00 ET)

Audited all three official winner archives (94 releases in 2024, 34 in 2025,
158 in 2026). One retained August 15, 2024 release explicitly describes Print
'n Play Bingo Multiplier, but the importer matched the same-named Scratcher.
The classifier now excludes this unsupported product instead of silently assigning
it to Scratch, and rejects unknown releases without explicit supported-game
evidence. Historical explicitly described Scratchers remain supported.

Re-import produced 109 retained releases. Every remaining row is byte-equivalent
at the parsed-record level, including dates, counts and coordinates; source date
is unchanged. The excluded release predates the public feed's 2026 window, so the
67 current-year records and published map scope are unchanged. Four classifier
regressions and all six Virginia data/offline tests passed. This closes the named
unmatched-to-Scratch accuracy defect; native publication-date checks and draw
report integration remain pending. Single opening mail/deployment check unchanged.

## October 2 staged state-game reports (00:00 ET)

Implemented a strict table parser/importer for Millionaire for Life and Bank a
Million. Nine actual reports are staged across these games, with latest published
prize tables September 30: 2,254 and 8,423 source-reported prize winners respectively.
Annual-payment and after-tax wording remains literal; total payout is unknown.
October 1 Millionaire for Life has an empty prize array and is unavailable, not a
zero-winner report. Per-game dates cannot regress and failed parsing leaves the
prior output untouched. Four parser regressions pass, including unavailable data,
malformed counts, missing jurisdiction, duplicate dates and date regression.

This is staged source data, not yet an app report or published feed. Remaining
national jurisdiction/Power Play reconciliation, other state report formats and UI,
cache/transaction/publication integration remain required. No deadline change.
Previous publisher 36958421776 succeeded; no new agency message at opening check.

## October 2 Pick session report implementation (01:00 ET)

Added Pick 3/4/5 parsers and imports, preserving Day and Night separately and
reporting base/FIREBALL prize dollars rather than invented winner counts. Null
unpublished totals are omitted; partial or malformed amounts fail the import.
Date non-regression now applies per game and session, so a newer Day report
cannot hide disappearance or regression of Night data. Seven parser tests pass.

The staged set now contains 40 reports across five state games. No retail map
records, coordinates, or accepted-state UI changed. These reports still need
remaining game formats, app loading/display and transactional publication before
native acceptance. Publisher 36962831994 succeeded; opening mail check empty.
Full scope reconciliation and release deadlines are unchanged.

## October 2 Cash 5 and Cash Pop implementation (02:00 ET)

Added Cash 5 base-tier winning plays with exact reconciliation against official
base prize dollars, plus separate EZ Match prize dollars with unknown winner
count. September 30 fixture reconciles 5,431 base winning plays and $8,519 base
payout, separately $8,070 EZ Match. The count explicitly excludes EZ Match.

Added all five Cash Pop session totals with source publication flags: false means
unavailable even when the raw field is zero. Published zero remains zero. Counts
and tier breakdowns stay unknown; no retailer allocation is inferred. Eleven
parser regressions pass, including payout mismatch, partial amounts, malformed
availability and duplicate sessions. Live import now stages 70 reports across
seven games; report UI/publication remains pending. No source date or count is
fabricated. Keno and national/seasonal reconciliation are the next bounded gaps.

Opening publisher 36967119195 succeeded, with no new agency mail. Deadlines
unchanged; accepted-state UI and private record deliveries remain untouched.

## October 2 Keno staged implementation

Keno parser now preserves local draw time and ten separate spot tables, with
share counts and reconciled payouts. The API repeats its one-spot table in
DrawData; it is checked for consistency but never counted twice. Same-day draw
time regression is guarded. Thirteen parser tests pass and live import stages
75 reports across eight state games. Keno is a recent snapshot, not a complete
four-minute history. National/seasonal reconciliation and app integration remain
pending; no release acceptance is implied.

## October 2 full scope reconciliation (03:00 ET)

Full per-game scope/gap reconciliation is complete before the October 2 19:02 ET
checkpoint. Supported scope includes Powerball/Power Play, Mega Millions, all
eight recurring state games, seasonal Raffle, historical Cash4Life releases,
Scratch inventory, selected retailer winner releases and the current directory.

Powerball's official dated table includes an outside-Virginia winner; label it
multi-jurisdiction with Virginia share unavailable. Mega Millions' table does
not establish a Virginia share; label source jurisdiction unverified and never
present it as a Virginia total. Both tables are now staged with literal prize
strings. Powerball multiplier is retained separately, without invented Power
Play counts or multiplied payouts. The inspected drawnumbers/prizesandodds routes
supply no separate Power Play winner table. The official game page remains the
source route for rules/odds and any subsequently available detail. No third-party
winner counts are substituted. These explicit gaps do not delay public-source
completion or trigger a new agency request.

The seasonal Raffle route links official dated winning-number reports; provide
that route without publishing ticket rows or implying claimed prizes. Cash4Life
remains historical release coverage. Scratch remains remaining-prize inventory,
not daily claims. Print 'n Play and online-only releases are excluded from the
retail Scratcher map, with the observed misclassification corrected earlier.
State report online/retail combined totals remain explicitly labeled.

The staged set now contains 85 reports across ten recurring national/state games.
Fourteen parser regressions pass. Next deliverables are report UI and bundled/
cached loading, state refresh transaction/publication, then integrated native and
independent live acceptance. This checkbox closes scope definition, not release.
Opening publisher 36974377147 succeeded; no new agency mail. No deadline change.

## October 2 bundled/cache loading (04:00 ET)

Added Virginia report asset registration and a validated remote/cache/bundle loader.
It requires all ten recurring games, official source URLs, provenance and valid
units, rejects a Virginia allocation of national report counts, and preserves
unknown winner counts for payout-only reports and Keno shares. Valid responses
remain usable when cache writes fail; unavailable/invalid remote data falls back
to saved or bundled reports without rewriting source dates. Four focused loader
regressions pass; changed-file analysis is clean. UI/transaction/publication and
native verification remain pending; the loader is not yet a navigable feature.

Opening publisher 36976620873 succeeded. Bot66ddfb2 status independently matches
the live status bytes: Texas updated, Nebraska retained after failure. The October
2 maintenance checkpoint still needs per-feed TX verification and NE investigation;
prior accepted-state UI stays closed. No new agency mail. Deadlines unchanged.

## October 2 report UI and publication integration (05:00 ET)

Virginia's official-source screen now opens a report sheet covering all ten
recurring national/state games and seasonal/historical source routes. Jurisdiction,
draw date/session/local Keno time, unknown publication date, retrieved time,
cadence and limitations remain visible. Shares, base-only plays, source winner
counts and payout-only reports retain separate labels. National counts are never
presented as Virginia totals. Tables scroll horizontally; report content scrolls
vertically, with official-source links and a retained report selection.

Added the report output/importer to Virginia's existing refresh transaction and
public Pages staging. Four loader tests plus compact/wide layout checks for all
85 reports passed (six Flutter tests); changed UI analysis clean; ordinary macOS
debug build passed. Four refresh isolation/rollback regressions passed. Native
and independent new-endpoint verification remain pending. The report feature is
ready for native testing, but Virginia is not accepted. Deadline unchanged.
Opening publisher36976620873 remained successful; no new mail.

## October 2 first native reports and independent publication (06:00 ET)

Publisher36987644575 succeeded; fetched public virginia_draw_reports.json bytes
exactly match the committed 85-report file. Relaunched the ordinary debug app at
800×632 logical size. Find a State → Virginia → VA Lottery → Draw reports opened
successfully. Map timeline visibly uses Published dates, with October 2 scoped
empty (not a statewide zero). Mega Millions September 29 displayed 214,458 source
winners, unverified jurisdiction/not a Virginia total, literal ranges and unknown
payout. Vertical scrolling exposed limitations and retrieval07:02:56.082UTC.
Official-source button opened Chrome at the matching Virginia Mega Millions URL;
return retained the selected report. Switching to Powerball September 30 showed
589,245 source winners, outside-VA scope, Texas match-five note and 4X multiplier
without invented Power Play counts/payout. No crash observed. Private screenshot
and AX evidence retained in work/virginia_native.

These completed initial compact/national/source/return flows need not be repeated.
Continue state-game report selection, larger native layout and integrated
catalog/retailer/filter/detail/offline checks. Publication and first report routes
are verified; Virginia remains unaccepted. No new agency mail; deadline unchanged.

## October 2 compact state-game report checks (07:00 ET)

Native ordinary build at 800×632 selected Keno October 2 02:50, showing source
local time, unavailable winner count, one prize-winning share and $1 reported
prize dollars (7 Spot), with table columns explicitly labeled Shares. Cash Pop
October 1 After Hours selected successfully and exposed $9,899, unavailable
winner count and the no-tier/no-retailer-allocation limitation. Cash 5 October 1
showed 6,717 base-only winning plays, $11,960 base plus $14,836 EZ Match = $26,796;
online/retail scope and EZ Match's unknown count remain explicit. Dropdown
scrolling reached these choices. Private screenshots/AX retained under
work/virginia_native. No crash observed. Initial AX was empty until mouse
interaction restored the tree; this is not full accessibility certification.

Publisher36987644575 still successful; no new agency mail. No implementation
change or redundant build/test run. Continue Pick3/4/5, Bank and Millionaire for
Life native choices, larger layout and integrated catalog/retailer/filter/detail/
offline checks. Virginia remains unaccepted; release deadline unchanged.

## October 2 remaining compact report selections (08:00 ET)

Native 800×632 ordinary build selected October 1 Night reports for Pick 5
($12,400 base + $3,000 FIREBALL = $15,400), Pick 4 ($361,400 + $16,930 =
$378,330), and Pick 3 ($195,005 + $11,591 = $206,596). Each exposes unavailable
winner count, online/retail scope and payout-only/no-retailer-allocation limits.
Bank a Million September 30 displayed 8,423 source winners, unknown total payout
and literal "$1,000,000 after taxes" wording. Millionaire for Life October 1
showed 2,377, explicit Virginia scope, unknown payout and annual-for-life prize
wording. Private screenshots/AX retained in work/virginia_native. All ten recurring
games now have a compact native selection observed; no crash observed.

Publisher36987644575 remains successful; no new agency mail. No code changes or
redundant tests/build. Continue larger layout and integrated catalog, retailer,
map filter/detail and request-failure/reconnection checks. Virginia remains
unaccepted with the same October 4 19:02 ET deadline.

## October 2 enlarged native report and refresh verification (09:00 ET)

Zoomed the ordinary native window to the desktop's enlarged size (5120×2820
physical screenshot). Millionaire for Life retained its selection and displayed
all nine table rows, complete annual prize wording, limitations, retrieval,
cadence, source action and both seasonal/historical routes without clipping.
Closing the sheet and returning to the Virginia map succeeded; the published-date
October 2 scoped-empty view remained intact. Private wide screenshot/AX saved in
work/virginia_native/mfl-wide.*. No crash observed.

Publisher37007748065 succeeded. Fast-forwarded bot4dff301; independently fetched
Virginia reports and refresh-status public bytes both match that commit. Nebraska
remains retained after failure; its existing October 2 15:00 ET investigation and
Texas per-feed verification checkpoint remain open. No new agency mail. Continue
integrated catalog/retailer/filter/detail and failure/reconnection checks; no
repeat of completed report-choice/large-layout checks. State not accepted and
release deadline unchanged.

## October 2 native Scratch shortcut wording correction (10:00 ET)

Returning to compact size and opening Virginia Scratch-Offs exposed a scope defect:
the shared shortcut described selected winner releases as "every published
Scratch-Off claim" and "published claim activity." Virginia's shortcut now says
selected winner releases, explicitly distinguishes complete statewide claims,
and identifies publication dates. Other states' wording is unchanged. Remaining
prize counts still explicitly do not represent store stock. This is an observed
scope correction, not a new release prerequisite.

Changed-file analysis is clean and ordinary macOS debug build passed. The running
app still shows the prior build; relaunch and native verification of this correction
are next, followed by catalog/retailer/filter/detail/offline checks. No state
acceptance. Publisher37007748065 remains successful, no new agency mail, and the
release deadline is unchanged. Private before evidence retained under
work/virginia_native/scratch-shortcut-before.*.

## October 2 rebuilt shortcut and retailer navigation (11:00 ET)

Relaunched the ordinary build and returned to Virginia. The Scratch shortcut now
visibly exposes selected winner releases, publication dates and incomplete
statewide claims; the observed wording correction in 93ca193 is verified natively.
Opened the 5,360-location Virginia retailer list and searched LOVE FOOD MART 12:
one result at 298 W Bay Ave, Norfolk. Selecting it opened the retailer detail with
full address and the explicit warning that a directory listing alone does not
create a heat-map win. Official-directory and directions actions are present;
no directions or external location transmission was requested. Private corrected
shortcut and retailer-detail evidence retained in work/virginia_native.

No crash or new agency mail; publisher37007748065 remains successful. Continue
catalog and map game/prize/date/detail checks plus native request-failure/recovery.
This closes the shortcut correction and observed directory search/detail route,
not integrated state acceptance. Deadline unchanged.

## October 2 native date and winner detail (12:00 ET)

Changed the compact map calendar from October 2 to September 23. Published-date
whole-day timeline retained the selected date. Backing out of the selected
directory retailer to Norfolk exposed the reported Platinum 7s release: one
reported winning ticket, $2M, LOVE FOOD MART 12. Opening the ranked retailer row
exposed PUBLICATION DATE September 23 and the full disclaimer distinguishing
publication from draw/claim date and selected releases from complete statewide
counts. Address and official release source action are present. This closes the
publication-date/classification checklist item; private screenshot/AX retained
as work/virginia_native/winner-publication-detail.*. Directory-only retailer focus
had an empty ranking before returning to the city view; no claim was fabricated.

No crash/new mail/publisher change. Continue source action/return, game/prize reset,
catalog and native failure/reconnection. No state acceptance or deadline change.

## October 2 winner source and return (13:00 ET)

Scrolled the compact winner sheet to its source and opened the official release
in Chrome. The destination is Virginia's latestwinners item
e25c7995-2119-4950-916f-8a1507518ab0. Its September 23 Platinum 7s article identifies
the $2M advertised prize and Love Food Mart at 298 W. Bay Avenue in Norfolk,
matching the app's reported retailer. Returning to the app retained the scrolled
winner-detail source/disclaimer panel. Private browser AX and return screenshot
are retained in work/virginia_native/winner-source-*. Initial browser state was
still the previous catalog tab while navigation loaded; the subsequent loaded
release was checked, not inferred from the requested URL.

No crash/new mail/publisher change. Source/return is closed; continue game/prize
reset, catalog and native failure/reconnection. Virginia remains unaccepted;
deadline unchanged. The Nebraska/Texas maintenance checkpoint remains 15:00 ET.

## October 2 native game filter reset (14:00 ET)

At September 23's Norfolk/LOVE FOOD MART 12 view, selected Powerball in the compact
Game filter and applied it. The map reported scoped-empty activity without
changing the publication date. Reopened the filter, selected All Games and applied:
Platinum 7s, one published record/$2M returned, with September 23 retained. Sheet
AX stayed stale, so selection and apply were verified by screenshots and mouse
coordinates; map AX updated after applying. Private reset evidence retained in
work/virginia_native/game-reset.*. No crash observed.

No new agency mail or publisher change. Game selection/reset is closed; prize
range/reset, catalog and native failure/reconnection remain. Next session must
also handle the existing 15:00 ET Nebraska investigation/Texas live-feed recovery
checkpoint. Virginia remains unaccepted; release deadline unchanged.

### October 2, 15:00 ET — refreshed live report verification

Publisher 37048391602 succeeded and bot commit 39aa857 was fast-forwarded.
Independent HTTPS downloads match committed report and refresh-status bytes.
The refreshed report window now contains 79 reports across all ten recurring
games (previously 85): Cash Pop has 22 published sessions and each Pick game
nine, with latest October 2 publication; unavailable sessions are not zero
payout reports. The other six game groups retain five reports each. This is
live-feed evidence, not native acceptance of the refreshed window. Native prize
reset, catalog and request-failure/reconnection checks remain open. No new agency
mail. Release deadline remains October 4, 19:02 ET.

Native prize-range verification also passed: setting the displayed range to
$11.0M–$30.0M on September 23 yielded the scoped no-matching-activity message.
Restoring the full range restored Platinum 7s, one published record/$2M at
LOVE FOOD MART 12, with the publication date retained. Private `prize-range`,
`prize-empty` and `prize-reset` evidence is retained. Sheet AX remains stale;
mouse/screenshots verify controls and the map AX verifies the result. Catalog
and native failure/reconnection remain next; no release acceptance is asserted.

### October 2, 16:00 ET — native official catalog route

Virginia Scratch shortcut → Open full official catalog opens the loaded official
`valottery.com/scratcher-search?view=0` page. Native browser evidence exposes
priced game cards, remaining-prize counts and closing-soon zero inventory,
including $173,000,000 Extravaganza #2143 ($30, $5M*, two remaining), matching the
in-app snapshot's literal prize notation and inventory. Return to the app retains
the expanded Scratch shortcut and publication-date map context. The Games bottom
tab is the cross-state activity list, not the full Scratch catalog. Private
`catalog-source` and `catalog-return` evidence retained. This validates the catalog
route, not a new complete statewide claims dataset or exhaustive browser audit.
Native request failure/reconnection and final integrated acceptance remain open;
release deadline unchanged. No ordinary app code/build changed in this session.
