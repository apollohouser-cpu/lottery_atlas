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

- [ ] Finish national/state/seasonal game scope and available-report reconciliation.
- [ ] Correct publication-date presentation and audit unmatched classification.
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
