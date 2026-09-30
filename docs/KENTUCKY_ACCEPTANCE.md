# Kentucky release evidence

Status: **final extension expired; native access restored; native crash under investigation; not accepted as complete**.
Original September 28, 2026, 18:00 deadline missed. The single extension expired
September 29, 2026, 18:00 America/New_York. No further extension is permitted.
Implementation: a0aa40a. Latest verified scheduled data: bd8f181.
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
| Live deployment | Eight public JSON files byte-match bd8f181; publisher 36613049951 succeeded | Recheck only after relevant publication changes |

The two integrated widget sizes are 800×632 and 1280×900. They verify behavior and
layout exceptions, not native visual appearance. Desktop control was restored
September 29 in the evening; see the crash investigation below. Do not repeatedly add test-only work as a substitute
for this final gate, and do not advance to South Carolina before Kentucky acceptance; Virginia follows South Carolina.

For the final native pass using current live data, use September 28, 2026 and
Graves County's $10,000 24K Gold notice at KY CHEK MART II in Mayfield. The
August 31 AM EXPRESS 9 notice used by the earlier integrated evidence has rolled
out of the current source; use it only with the documented older bundled snapshot. Repeat the game/prize/reset sequence above, inspect source
and date disclosures, open the statewide table selector, and inspect the compact
and larger layouts. Preserve existing Favorites. Record actual observations and
any defects; close the checklist only after those checks pass.

Latest targeted refresh validation: nine Kentucky loader/report widget tests pass;
changed-test analysis is clean. The prior full implementation run passed 99 Flutter
tests and the macOS debug build, with 12 existing analysis infos. A scheduled draw
refresh changed Mega Millions totals; its UI regression now compares every displayed
total cell and draw date to the selected validated report, avoiding stale literals.
Importer/source reconciliation rules are unchanged.

## Native crash investigation — September 29, evening

Computer Use can now capture and operate the native app. Rebuilding the current
checkout replaced the older local bundle. Two macOS crash reports at 21:07 and
21:08 ET record EXC_BAD_ACCESS / SIGSEGV in Flutter's
AccessibilityBridge::CreateRemoveReparentedNodesUpdate(), followed by
CommitUpdates() and FlutterViewController updateSemantics. The crash reports
remain local/private. This is a real engine crash, separate from deliberate
quit/relaunch during rebuilding; the precise triggering interaction is unproven.

A local, unaccepted startup candidate keeps macOS semantics enabled from the
first frame. Its debug build succeeds. At 800×632, native state search, Kentucky
entry, September 28 date selection, opening/changing/dismissing the game filter,
and opening the statewide table selector then switching Mega Millions to
Powerball succeeded without a new crash report during this short observation.
This does not establish crash resolution, filter application/reset acceptance,
or completion at either required size. Native accessibility still exposes only
the window/menu tree to the desktop tool, so these observations used screenshots
and pointer actions. Continue investigating stability and finish the existing
checklist before accepting Kentucky. No replacement deadline or queue activation.

## Native report scroll correction — September 29, 22:05 ET

At 800×632, wheel scrolling in the native statewide report did nothing while
dragging its scrollbar moved the rows. Leaving the drawings MouseRegion could
reenable the native map scroll interceptor after a modal had covered the map.
Map enable requests now respect whether its hosting route is current. A real-app
mouse regression fails on the original code (map active behind report) and passes
with the correction. The debug build succeeds. Native wheel scrolling now moves
through Mega Millions rows to its total of 2,362, with the header/selector fixed.
This advances the compact table-scroll check only; remaining source/footer,
larger-layout and other acceptance checks stay open. No new crash report appeared;
the earlier semantics startup candidate remains local and unaccepted separately.
The startup mailbox search found only already-handled messages; latest publisher
36651309931 succeeded at 6f04150. No agency reply or data-layer change was needed.

## Native report footer and larger layout — September 29, 23:03 ET

The compact report's outer body scroll reaches the complete cadence/limitations
paragraph and the unobstructed official-source link below the independently
scrollable table. The window was then resized through native pointer actions to
a 2560×1800 screenshot (1280×900 logical). The report selector and close button,
Mega Millions footer/source link and Cash Ball 225 report were visually reachable.
Cash Ball's separate EZ disclosure was legible. The selector visibly includes
Powerball, Mega Millions, state draw sessions, Keno and Cash Pop. These are actual
native observations on the existing rebuilt candidate, not a full acceptance pass.
No additional crash report appeared. The local semantics candidate remains
unaccepted; date/detail, county, game/prize/reset and offline checks remain open.
The one mailbox check returned only previously handled Illinois/Wyoming messages.
Publisher 36651309931 remains successful; current live Kentucky draw tiers and
refresh status were checked separately against the checkout after a2b785a.

## Native game/date and notice check — September 30, 00:04 ET

At 1280×900 logical, pointer selection of Monday set September 28 and retained
the published-date/time-unavailable disclosure. Applying Mega Millions produced
the scoped empty-state notice. Reopening the picker, selecting All Games and
pressing Apply restored five heat points. Clicking the western point selected
Graves County and displayed one qualifying $10,000 record; opening that record
showed Mayfield, 24K Gold, NOTICE DATE Mon, Sep 28, and KY CHEK MART II at
300 Wyatt Drive. Native wheel scrolling exposed the official Kentucky Lottery
Have You Heard source/date and unobstructed external link. Favorites were not
changed. These close the larger-size game category reset and date/detail visual
checks only; prize slider, county back/empty/reset, compact equivalents and native
offline checks remain outstanding. No additional crash report was present at
session start. Mail and publisher checks were unchanged. No new tests, release
claim, extension or queued-state activation.

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

## Scheduled draw acceptance — September 28, 03:51 ET session

Publisher 36387439013 succeeded at 1e7549f. Eight public files independently
byte-match the checkout; nine report/loader tests pass. Powerball Xs & Os,
Millionaire For Life, Cash Ball 225 and Pick 3/4 EVENING now carry September 27
draws. The supported scope is unchanged. Native review remains open and due today
at 18:00 ET; South Carolina is next only after acceptance. Indiana's retention and
09:39 ET maintenance checkpoint remain open. No new agency response required action.

## Scheduled source acceptance — September 28, 08:55 ET session

Publisher 36422961467 succeeded at 49a8838. All eight public JSON files
independently byte-match the checkout. Fourteen Kentucky catalog/directory,
offline/reconnect and report/loader widget tests pass. The 81-game Scratch
catalog advances to September 27 inventory with four reduced top-prize counts.
Keno/Cash Pop individual-draw snapshots advance to September 28; ten tier reports,
directory and supported map scope remain unchanged. Native review remains open
and due today at 18:00 ET. The local native candidate has not been rebuilt.

Indiana's importer recovered with status updated; close its September 28, 09:39 ET
maintenance checkpoint. New Hampshire is the only retained state failure in this
publication. Recovery does not imply a complete Indiana claims map.

## Scheduled report acceptance — September 28, 15:00 ET session

Publisher 36466064335 succeeded at 77fabaf. Eight public JSON files independently
byte-match the checkout; nine Kentucky report/loader widget tests pass. Pick 3/4
MIDDAY reports now cover September 28 and individual-draw aggregate snapshots
refreshed. Catalog, directory and map scope are unchanged. Native review remains
open, with today's 18:00 ET release decision unchanged.

Texas reports a new retained_after_failure; all five transaction files match the
preceding validated commit byte-for-byte, including dates. This isolated refresh
failure does not alter Kentucky acceptance or reopen Texas's supported release.

## Deadline decision — September 28, 18:00 ET

Not accepted: the final native checks above remain unobserved because desktop
interaction capability is unavailable and no new user observations have arrived.
No new product defect is asserted. One 24-hour extension ends September 29 at
18:00 ET; no repeat extension. Ready for native testing using the existing local
macOS debug candidate described above. Restore interaction capability or provide
actual results from the checklist; automated evidence alone does not close it.
South Carolina remains queued until acceptance, with Virginia following.

## Refresh retention verified — September 28, 21:00 ET session

Publisher 36503918862 succeeded at f531338, but Kentucky's state transaction
reports retained_after_failure. All four Kentucky generated files are byte-for-byte
identical to the validated preceding checkout, including source dates. Eight
public JSON files independently match the publication. No repeat tests were run
for unchanged Kentucky data. The status gives retrieval/validation failure,
without a confirmed narrower cause. Previously supported coverage remains intact.

Check the next scheduled result; investigate if failure persists by September 29
at 15:00 ET, before the single native-review extension ends at 18:00 ET. This
maintenance checkpoint does not reset or extend acceptance. Texas's five files
also remain byte-for-byte retained; its existing 15:00 ET checkpoint is unchanged.

## Refresh recovery — September 29, 03:00 ET session

Kentucky and Texas both report updated at f27bc08, successful publisher
36531895999. All nine checked live files (eight Kentucky/shared plus Texas tiers)
independently byte-match. Fourteen focused Kentucky generated-data, report/loader
and widget tests pass. Close both September 29, 15:00 ET recovery checkpoints.
No validation was weakened; exact prior failure causes remain unconfirmed.

Kentucky's native-review gate remains open, with the single extension ending
today at 18:00 ET. The local native candidate has not been rebuilt for this
scheduled data change. South Carolina and Virginia remain queued.

## Scheduled source acceptance — September 29, 09:00 ET session

Publication 7f9c048, successful publisher 36569315894, passes fourteen focused
Kentucky generated-data/report/loader widget tests. Eight public JSON files
independently byte-match. The 81-game catalog has September 28 inventory; the
retailer directory now has 3,381 mapped entries from 3,475 source retailers, with
94 unresolved exclusions. Four entries were added and two removed by the validated
refresh. Directory entries do not create winning-ticket activity. Aggregate draw
snapshots also refreshed. No validation or supported-coverage rules changed.

Native review remains open; no new native observations or desktop interaction
capability are available. The single extension ends today at 18:00 ET. No new
matching agency messages or importer failures require notification this session.


## September 29, 15:00 ET — refreshed notice acceptance

Publication bd8f181 / publisher 36613049951 independently matches all eight
live JSON files. Fourteen focused Kentucky tests pass. The rolling source now
contains 37 matched notices and no unmatched published notices; this is not
complete statewide claims coverage. Five September 28 notices include Powerball
at CASEY'S #4665 and four Scratch notices. August 31 entries rolled out. The
native checklist above now identifies an available September 28 Graves County
notice; historical integrated evidence remains labeled with its original fixture.
Catalog/directory scope is unchanged. Native checks remain unobserved; today's
18:00 ET final extension and queued-state restrictions remain unchanged.


## September 29, 18:00 ET — final acceptance blocked after extension

No native observations or desktop interaction capability became available before
the extended deadline. Required intervention is restored desktop interaction or
actual observations of the remaining native checks above at both documented
window sizes. The app remains ready for those checks; it is not accepted complete.
No new release deadline is assigned and no queued state is activated. Preserve
existing test/live evidence and continue only independent checklist work, actual
defect handling and verified new-data preparation while this gate remains open.

## Native prize range and county back — September 30, 01:00 ET session

At 1280×900 logical on the existing native candidate, dragged the minimum-prize
handle from $1 to the displayed $10.8M and pressed Apply. The Graves heat point
disappeared and the scoped no-matching-activity explanation appeared. Reopened
the picker, dragged the handle to its minimum and applied; the Graves point
returned. The county Back control then restored the Kentucky county-ranking
heading while preserving September 28. This verifies the larger native prize
filter/reset and county-back interaction; it does not close compact equivalents,
county empty-state review, offline review or stability acceptance. The two
September 29 crash reports remain the newest; no new crash was recorded during
this flow. The semantics candidate remains local and unaccepted. Mail and the
latest publisher were unchanged. No release decision or queue advancement.

## Recurring accessibility crash and ranking scroll — September 30, 02:05 ET

At 1280×900, selecting Adair showed the county heading with no mapped notice.
Wheel scrolling over the ranking header instead zoomed the map, leaving the
explanation below the viewport. A local HomeScreen MouseRegion candidate releases
the native wheel interceptor when the pointer leaves the map and reenables it
on route-current reentry. The new home-scroll regression and existing report-modal
regression both pass in separate test files; changed-file analysis is clean and
the macOS debug build succeeds. Native confirmation remains pending.

After deliberately quitting and reopening this rebuilt candidate (which also
contains the existing ensureSemantics startup candidate), the app crashed during
a resize/scroll sequence at 02:05:32 ET. The new private report
lottery_atlas-2026-09-30-020532.ips again records EXC_BAD_ACCESS at 0x48 in
AccessibilityBridge::CreateRemoveReparentedNodesUpdate. Exact triggering action
within that sequence is not yet isolated. The startup workaround is therefore
insufficient; the earlier crash-free observations do not establish resolution.
Preserve both local candidates and the new regression file for investigation.
Kentucky remains unaccepted, with no replacement deadline or queued-state start.
No new agency email was found and publisher 36651309931 remains successful.

## Resize trigger isolation and refreshed data — September 30, 03:02 ET

On the existing local rebuilt candidate, launching succeeded at 800×632. A
single bottom-right resize drag followed by state capture reproduced the same
EXC_BAD_ACCESS before any wheel event was sent. Private report
lottery_atlas-2026-09-30-030152.ips again identifies
AccessibilityBridge::CreateRemoveReparentedNodesUpdate. Resizing is now an
observed reproduction sequence; the underlying semantics-tree cause remains
unproven. Keep the startup and home-scroll candidates unaccepted and preserve
them. The app's default South Carolina startup view was used only to isolate
this shared crash, not to activate or accept queued South Carolina work.

The related upstream [null-parent guard proposal](https://github.com/flutter/flutter/pull/190903)
is still open, not an available verified fix. No SDK or accessibility-disable
change was made. Native county/compact/offline checks remain open.

Publisher 36679096623 succeeded with publication 9bedd78. Fourteen Kentucky
generated-data/report-loader/widget tests pass and nine public files independently
byte-match (the eight Kentucky/shared files plus Texas tiers). Texas reports
updated for its full transaction: close the September 30, 15:00 ET importer
recovery checkpoint. This does not resolve the separate native crash or advance
Kentucky acceptance. The mailbox check returned no new agency message.
