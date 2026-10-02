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
