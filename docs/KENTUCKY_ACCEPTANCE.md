# Kentucky release evidence

Status: **ready for native acceptance, not released as complete**.
Release decision due September 28, 2026, 18:00 America/New_York.
Implementation: a0aa40a. Latest verified scheduled data: 98a107f.
The scope/per-game inventory was completed September 25, before its deadline.

## Supported scope

The map contains selected official winner notices with verified retailer matches
from January 1, 2026 onward. Eight archived 2024–2025 notices are excluded by the
existing launch window. A directory listing never establishes a win. Notice dates
do not establish sale/claim times. No complete statewide claims count is promised.

Separate statewide reports cover Mega Millions, Powerball, Powerball Double Play,
Powerball Xs & Os, Millionaire For Life, Cash Ball 225, and both Pick 3/4 sessions.
Keno and Cash Pop have individual-draw aggregate snapshots, not prize tiers or
retailer points. Cash Ball EZ totals remain separate. Missing location evidence,
Fast Play/online gaps and source limitations are recorded in KENTUCKY_SOURCE_SCREEN.

## Evidence and remaining gate

| Flow | Evidence already obtained | Remaining native check |
| --- | --- | --- |
| Scratch selection/reset | Native 800×632 catalog pass; remaining prizes versus stock explained | Repeat only if latest layout affects access |
| Directory/Favorites | Native Adairville retailer/address/save/open/remove pass | Confirm compact shortcuts after latest layout |
| Statewide reports | Native ten-table and aggregate-game passes; current loader/widget checks | Inspect scrolling after compact sheet correction |
| Date/detail/source | Integrated real-app offline selection of Aug 31, Warren County notice; NOTICE DATE and source link reachable | Visually inspect date label and source in actual app |
| County scope/reset | Warren → one Bowling Green record; Adair → scoped empty ranking; back restores state | Pointer county selection and back controls |
| Game/prize/reset | Mega Millions scoped empty → All Games restores notice; slider excludes/reincludes $10,000 record at both sizes | Actual app filter/slider and unobstructed reset |
| Offline/reconnect | Bundled real-app flows; cached failure and unchanged-date reconnect tests | Native offline display; street tiles are not promised offline |
| Source/cadence/limitations | Source-screen reachability at both sizes; updated launch-window disclosure | Native navigation and visual legibility |
| Live deployment | Eight public JSON files byte-match 98a107f; publisher 36224080527 succeeded | Recheck only after relevant publication changes |

The two integrated widget sizes are 800×632 and 1280×900. They verify behavior and
layout exceptions, not native visual appearance. Desktop-control tools remain
unavailable in this session. Do not repeatedly add test-only work as a substitute
for this final gate, and do not advance to Virginia without the release decision.

For the final native pass, use August 31, 2026 and Warren County's $10,000 24K Gold
notice at AM EXPRESS 9. Repeat the game/prize/reset sequence above, inspect source
and date disclosures, open the statewide table selector, and inspect the compact
and larger layouts. Preserve existing Favorites. Record actual observations and
any defects; close the checklist only after those checks pass.

Latest targeted refresh validation: nine Kentucky loader/report widget tests pass;
changed-test analysis is clean. The prior full implementation run passed 99 Flutter
tests and the macOS debug build, with 12 existing analysis infos. A scheduled draw
refresh changed Mega Millions totals; its UI regression now compares every displayed
total cell and draw date to the selected validated report, avoiding stale literals.
Importer/source reconciliation rules are unchanged.
