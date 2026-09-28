# Kentucky release evidence

Status: **ready for native acceptance, not released as complete**.
Release decision due September 28, 2026, 18:00 America/New_York.
Implementation: a0aa40a. Latest verified scheduled data: 9c9fbec.
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
| Live deployment | Eight public JSON files byte-match 9c9fbec; publisher 36362927118 succeeded | Recheck only after relevant publication changes |

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

## Native review candidate — September 26, 04:07 ET session

Rebuilt the macOS debug app successfully from 60b6134, including scheduled data
98a107f. Local artifact: `build/macos/Build/Products/Debug/lottery_atlas.app`.
This replaces the previous local build's older bundled draw reports. Current live
Kentucky report bytes still match; publisher 36224080527 remains successful.

The release is now waiting for native review. Desktop-control capability is absent
from the available tool set; no native interaction or screenshots were obtained.
The user has been asked to perform the final native checklist above and report
any problems. Preserve the September 28 deadline and keep Virginia queued. Do not
add routine tests or enhancements to fill the waiting period; resume native review
when available and handle actual defects or meaningful new agency data meanwhile.

## Scheduled data acceptance — September 26, 09:14 ET session

Validated publication cc053d8 after publisher 36242210487 succeeded. All eight
public JSON files independently byte-match the checkout. Fourteen Kentucky
catalog/directory, offline/cache/reconnect and statewide-report widget tests pass.
The 81-game Scratch catalog now carries September 25 inventory; the official
retailer refresh removes THE PIT STOP, leaving 3,379 verified mapped locations
from 3,473 unique source entries, with 94 unresolved. Keno and Cash Pop snapshots
remain individual-draw aggregates, separate from mapped winner notices and tiers.
No coverage or validation rules changed.

The local native candidate above still bundles 98a107f; it was not rebuilt for this
scheduled data refresh. Final native review remains open, with no new observations
or desktop-control capability. The release deadline and Virginia queue are unchanged.

## Scheduled report acceptance — September 26, 15:17 ET session

Publisher 36262793374 succeeded at data commit 44252c3. All eight public JSON
files independently byte-match the checkout. Nine Kentucky loader/report widget
tests pass. Pick 3/4 MIDDAY reports now identify September 26 draws; Keno/Cash Pop
snapshots advanced independently. Catalog, directory and supported map scope are
unchanged. Native candidate and final-review blocker remain as documented above.

The same publication reports Texas retained_after_failure; its listed state files
were verified byte-for-byte unchanged from the preceding publication. This does
not invalidate Kentucky's report acceptance or establish a new Texas source date.

## Scheduled aggregate acceptance — September 26, 21:26 ET session

Publication 7555c1e (successful publisher 36283014017) advances Kentucky's
individual-draw aggregate snapshots without changing the ten tier reports,
catalog, directory or map scope. Nine report/loader tests pass; eight public
JSON files independently match the checkout. Native acceptance remains open.

Texas retention recurred in this publication. Public job annotations confirm
retention but provide no narrower cause. An isolated local Scratch catalog fetch
successfully parsed 75 games into a temporary diagnostic file; this does not
establish recovery of the full Texas transaction or replace any public/bundled
file. The existing September 27, 15:17 ET recovery follow-up remains open.

## Scheduled draw acceptance — September 27, 03:34 ET session

Publisher 36300455228 succeeded with data commit 305a618. Kentucky Powerball,
Double Play, Millionaire For Life, Cash Ball 225 and Pick 3/4 EVENING now carry
September 26 draws. Nine report/loader tests pass. All eight relevant public JSON
files independently byte-match this commit. Native review remains open; the local
native candidate has not been rebuilt for scheduled data changes.

Texas's full scheduled transaction recovered with status updated. The live Texas
tier report also byte-matches 305a618. Close the September 27, 15:17 ET recovery
follow-up; no validation changes or accepted product-scope changes were needed.
The exact cause of the preceding failures remains unconfirmed.

## Scheduled source acceptance — September 27, 09:39 ET session

Successful publisher 36319348936 produced 5dd6add. Eight public JSON files
independently byte-match the checkout. Kentucky's ten tier reports are unchanged;
individual-draw aggregates refreshed. The 81-game Scratch catalog now carries
September 26 inventory with six decreased remaining-top-prize counts. Nine
report/loader tests pass. Native review and its deadline remain unchanged.

Indiana's catalog refresh failed; its prior file is byte-for-byte preserved.
Texas updated successfully again. New Hampshire retention is unchanged.

## Refresh failure retention acceptance — September 27, 15:42 ET session

Publisher 36340903590 succeeded overall at 53e75a1 but isolated a Kentucky
importer failure. All four Kentucky transaction files (catalog, directory,
current notices and draw reports) remain byte-for-byte identical to 90dbd23's
validated baseline, preserving source dates. Eight public JSON files independently
match the published checkout, including retained Kentucky data and the disclosed
refresh status. No new tests were needed for unchanged Kentucky bytes.

The public status and job annotation identify retrieval/validation failure without
a narrower cause. Check the next scheduled result and investigate persistent failure
by September 28 at 15:42 ET, before the existing 18:00 release decision. This does
not relax validation, change supported scope, or close the native-review gate.

## Refresh recovery — September 27, 21:48 ET session

Kentucky's full scheduled transaction recovered with status updated in 9c9fbec,
publisher 36362927118. Eight public JSON files independently byte-match the
checkout, and nine report/loader tests pass. Close the September 28, 15:42 ET
recovery checkpoint. No validation changes were required; the preceding failure's
exact cause remains unconfirmed. Native review remains open and the September 28,
18:00 ET release decision is unchanged. Indiana/New Hampshire retention persists.
