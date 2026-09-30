# Kentucky release evidence

Status: **accepted for supported available coverage September 30, 2026 at 17:03 ET; complete statewide claims remain unavailable**. Earlier missed deadlines remain recorded below.
Original September 28, 2026, 18:00 deadline missed. The single extension expired
September 29, 2026, 18:00 America/New_York. No further extension is permitted.
Implementation includes native mitigation a9de73f. Latest verified scheduled data: 18b76e4.
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
| Directory/Favorites | Native Adairville save/open/remove pass retained; compact shortcut/address/disclaimer/actions and return verified September 30 14:03 | Complete; existing Favorites preserved |
| Statewide reports | Native ten-table and aggregate-game passes; compact scrolling/footer and larger selector/source passes September 29 | Existing evidence retained; include national and state games in final reconciliation |
| Date/detail/source | Native larger Graves notice September 30 00:04 and compact Boone notice 12:04: NOTICE DATE, retailer and source/date link visually reachable | Complete for online notice display; offline remains separate |
| County scope/reset | Native compact Boone/detail/back and Clay empty/back passed September 30; integrated both-size checks retained | Complete at both documented sizes; larger Logan empty/back observed September 30 15:04 |
| Game/prize/reset | Native category/reset and prize exclusion/reset observed at both sizes; compact September 30 11:08 entry | Complete; repeat only after relevant changes |
| Offline/reconnect | Native injected network failure retained saved data; normal-build relaunch recovered September 29 report on September 30 17:03 | Complete for tested failure/relaunch recovery; offline street tiles not promised |
| Source/cadence/limitations | Native notice date/source and report/footer disclosures reached at both sizes; launch-window and partial-coverage disclaimers observed | Complete |
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

## Scroll regression baseline — September 30, 04:00 ET session

Ran the new home-scroll regression against the unmodified HEAD HomeScreen,
restoring the local candidate in a finally block. It fails at the expected
map-exit assertion (expected false, actual true), establishing that the test
detects the original wheel-capture defect; the candidate's prior passing result
remains applicable. No implementation was replaced or accepted.

A fresh compact native launch and wheel action over the timeline did not expose
the ranking; the map changed instead. This is not native confirmation of the
HomeScreen candidate and must not be counted as a county empty-state pass.
The timeline sits within the map region at this size, so this observation needs
a separate input-boundary check. No further resize crash was deliberately induced.
The known resize/accessibility blocker remains open; preserve both candidates.
Mailbox and publisher checks were unchanged. No queued-state work or release claim.

## Timeline input boundary candidate — September 30, 05:03 ET

Added a local MouseRegion candidate around the timeline dock, which is inside
the map boundary and therefore not covered by HomeScreen's map-exit handling.
The home regression now checks entry to the timeline releases native wheel input
and return to the map restores it. Both home and report-modal regressions pass;
the debug build passes. Analysis reports only the four existing Radio API
deprecation infos in map_controls_overlay.dart. This candidate remains unaccepted.

Native launch at compact size, timeline wheel input, then a click and another
wheel attempt did not yield an accepted ranking-scroll observation. A new private
report at 05:03:18 ET again has AccessibilityBridge::CreateRemoveReparentedNodesUpdate
as its top frame. No resize was attempted in this session, so resizing is one
reproduction path, not the only possible trigger. Stop treating routine pointer
flows as sufficient stability evidence; engine/semantics investigation must
precede another acceptance attempt. Preserve all three local source candidates
and the expanded home regression. No SDK change or release was made.
Mailbox and publisher checks were unchanged.

## Idle control for accessibility investigation — September 30, 06:03 ET

Compared private launch/capture timestamps: the four recent fresh-launch crashes
occurred approximately 20–23 seconds after launch, whereas the first September
29 report belonged to an app launched September 25. Timing alone therefore
cannot establish resizing as the unique cause. A controlled restart using the
existing candidate followed by no resize, click or wheel actions survived at
least 57 seconds (same PID 60512); no new crash report appeared. The process
found before that deliberate restart had also remained alive for about 59
minutes after the previous tool-assisted relaunch. Idle startup is not currently
a deterministic reproduction. These controls do not establish stability.

Inspected the installed engine's common bridge: it asserts child->parent() then
dereferences that parent while processing reparented semantics. The macOS
controller feeds updates into that same bridge. A null-parent state is consistent
with the reports, but the originating framework update remains unidentified.
No engine patch, SDK replacement, source-candidate change or repeat acceptance
test was made. Continue with semantics-update diagnostics, preserving all local
candidates; do not use more ordinary pointer checks as evidence of resolution.
Mailbox and latest publisher remain unchanged.

## Null-parent state captured before fault — September 30, 07:07 ET

Attached LLDB to the existing idle process, with a conditional breakpoint at
AccessibilityBridge::CreateRemoveReparentedNodesUpdate +168 when x8 is zero.
One native bottom-right resize reached that breakpoint before the invalid memory
read. The child exists and has ID 50, but its parent pointer is null; pending
parent update ID 5 includes child 50. Disassembly confirms the faulting instruction
reads the parent's ID at null +0x48. The latest private crash report has the same
offset, null register and child ID. This confirms the immediate failure mechanism,
not just a stack-based inference.

The pending parent contains timeline/heat-index and state empty-view semantics.
Its tooltip includes Return timeline to now; that does not establish a tooltip
as the cause. The originating malformed update or earlier AXTree failure is still
unidentified. Next diagnostic target is the earliest tree-update error and the
framework semantics that produced it, not another uninstrumented acceptance run.
Private disassembly and small memory captures are retained under ignored
work/native_crash_diagnostics/sep30-null-parent. No engine, register or source
patch was made. The stopped debug process was deliberately terminated and the
app relaunched; no debugger remains attached. All three candidates remain local
and unaccepted. Mailbox and latest successful publisher are unchanged. Kentucky
remains unaccepted and the state queue does not advance.

## First native tree update isolated — September 30, 08:06 ET

The next instrumented session found the existing AXTree root pointer equals the
failing child-50 pointer, with an empty tree error string. This is an incorrectly
rooted tree, rather than evidence of an earlier reported Unserialize failure.
Disassembly of GetRootAsAXNode confirms the root-pointer field used for inspection.

Launched the current candidate under LLDB with CommitUpdates breakpoint enabled
from startup. The first observed bridge commit contained only one pending node,
ID 50. Unserialize returned true; the resulting native tree root was ID 50 and
the error string remained empty. Subsequent parent updates explain the observed
attempt to reparent that root. Why the bridge first receives a partial update
remains unresolved. The startup ensureSemantics candidate must be compared with
the baseline while tracing native semantics enablement and the first complete
framework tree; do not interpret it as an accepted mitigation.

Private logs, disassembly and small memory captures are saved under ignored
work/native_crash_diagnostics/sep30-first-update. No SDK/register/source change
was made. Stopped diagnostic processes were terminated deliberately; the app
was relaunched without the debugger. All candidates remain preserved. No repeat
widget tests were needed for this diagnostic-only session. Mailbox and publisher
were unchanged. Kentucky remains unaccepted; queued states remain inactive.

## Baseline failure traced to slider portal — September 30, 09:12 ET

Preserved the rejected startup ensureSemantics candidate privately at
work/native_crash_diagnostics/sep30-baseline/main_startup_candidate.dart, then
restored main.dart to committed baseline for comparison. The first native commit
now contained 38 nodes, but Unserialize returned false with the exact error
“37 will not be in the tree and is not the new root”. A second instrumented
launch captured the initial node graph; node 37 had no parent edge. The framework
semantics dump omitted node 37, while the render-tree dump identified its owner
as _RenderDeferredLayoutBox beneath OverlayPortal, whose child is the timeline
Slider's _RenderValueIndicator. This provides a specific widget source for the
initial failure. The startup workaround masks this initial failure and is no
longer active; its source is preserved privately.

Setting showValueIndicator to never still emitted the disconnected portal node,
so that experiment was removed. A new local macOS-only timeline candidate uses
CupertinoSlider, retaining the visible selected-time label and semantics. Other
platforms retain Material Slider. With baseline main.dart and this candidate,
the actual native accessibility tree exposes the full app controls for the first
time in these diagnostics. One native resize from 800x632 to approximately
825x900 logical and a subsequent slider drag attempt preserved PID 74640 without
a crash. The drag did not produce an observed selection change, so slider
interaction is still pending; neither this short flow nor these dimensions
constitute full acceptance at the documented sizes.

The two existing home/modal regression tests pass and debug build passes; analysis
reports only four existing Radio API infos. Test output includes map-tile HTTP400
messages; no native live-source failure was established by these test messages.
Keep the HomeScreen/timeline wheel candidates, new slider candidate and test
local until interaction, accessibility and Kentucky acceptance checks pass.
No engine or SDK patch was made. Debuggers are detached and the candidate app
is running. Mailbox was unchanged; publisher 36716247461 was in progress at the
single deployment check and has not been declared successful.

## Native slider and wheel verification — September 30, 10:10 ET

The running candidate retained PID 74640 from the previous session. After
activating the window, Month selection and a thumb drag changed September 30
to September 15 and refreshed results. Repositioning the window allowed an
actual 2560x1800 physical (1280x900 logical) resize. In Kentucky, a month-slider
drag changed September 15 to September 28, restoring published-record rankings
including Powerball in Fayette and Scratch records in Boone, Hardin and Graves.
The app then resized to 1600x1264 physical (800x632 logical). A compact thumb
drag returned to September 15 and displayed the scoped empty explanation.
All of these actions retained the same PID with no observed crash. This verifies
the slider interaction and both resize dimensions missing from the prior session;
it does not complete the remaining Kentucky integrated checklist.

At compact size, native wheel input over the timeline scrolled the page down to
the complete county-ranking disclaimer and scoped empty message, addressing
the previously inaccessible below-map content. The HomeScreen/timeline wheel
changes and macOS CupertinoSlider mitigation are now retained as tested fixes.
The rejected startup ensureSemantics version remains private for diagnosis.
No engine or SDK patch is required by this mitigation. National and state draw
game acceptance, remaining county/filter/source/offline flows and final integrated
verification still govern Kentucky release; South Carolina is not activated.

Publisher 36716247461 succeeded. Seven live files (activity, Kentucky draw tiers,
retailer directory, Scratch catalog, combined directories/catalogs, refresh status)
matched local c4f3475-era files byte for byte. Fourteen Kentucky data/table tests
passed against that refresh. Existing home/modal regressions and candidate build
were already validated in the preceding session and were not repeated unchanged.
No new agency messages were found.

## Compact filter acceptance — September 30, 11:08 ET

At 800x632 logical, the native app retained PID 74640 from the earlier slider
verification. With Kentucky Month view at September 28, selecting Mega Millions
and applying the filter displayed the scoped no-activity and empty-ranking
explanations. Resetting to All Games restored the published Boone, Fayette
(Powerball), and Hardin records. The compact modal scrolled to its Apply button.

The prize-range check then raised the minimum to $11.0M with a $60M maximum.
Applying it cleared the map activity and rankings with the appropriate wider-range
suggestion. Restoring the $1–$60M range returned the same published records.
An initial drag changed the upper bound instead; that attempt was corrected and
was not counted as the exclusion check. No crash was observed during these flows.

These observations close the compact game-filter/reset and prize-filter/reset
checks. They do not establish full Kentucky acceptance: remaining integrated
county, source, offline/reconnect and national/state draw-game observations must
still be reconciled with the existing checklist. No unchanged tests or builds
were repeated. Publisher 36716247461 remained successful at the single check.
South Carolina and Virginia remain queued.

## Compact county notice and return — September 30, 12:04 ET

At 800x632 logical, selecting Boone's heat point opened its county summary
with one qualifying $50K record. Native wheel scrolling reached the record,
and selecting it opened Walton's Millionaire Club Scratch-off notice. The
NOTICE DATE (Mon, Sep 28), PILOT TRAVEL CENTER #278 and 118 Richwood Rd
address were exposed. Scrolling reached a visually legible source/date panel,
September 30 9:03 AM refresh timestamp, official Have You Heard? source link,
and unobstructed action buttons. This verifies source-link reachability, not
an external-browser load. Dismissing the notice and using the map back control
restored Kentucky and the Boone/Fayette/Hardin rankings for September 28.

A subsequent pointer attempt at Adair instead hit Hardin's overlapping heat
point; it is not evidence for an empty-county check. That summary was dismissed
and the state view restored. PID 74640 remained unchanged with no observed
crash. Empty-county native verification and offline/reconnect remain open;
remaining national/state draw-game scope must be reconciled before acceptance.
The publisher check still showed 36716247461 successful, and the mailbox held
only the already-answered Texas clarification. No unchanged tests were repeated.

## Compact empty-county scope — September 30, 13:03 ET

Native pointer selection of Clay County at 800x632 logical opened the county
map. Wheel scrolling over the timeline revealed the entire TOP CITIES BY
PUBLISHED RECORDS · Clay card, September 28 date, selected-record coverage
disclaimer and “No verified activity matches the current map and timeline
filters.” This is a scoped absence of verified records, not a zero-wins claim.
The visible Back control restored Kentucky and all five published records
(Boone, Fayette/Powerball, Hardin, Graves and Pike). PID 74640 stayed unchanged
with no observed crash. This closes the previously unobserved compact empty
county/back flow; the earlier Adair mis-hit is not used as evidence.

Reconciled the summary table with previously recorded report scrolling/footer
and game/prize native passes rather than repeating them. Native offline/reconnect,
compact directory shortcut confirmation and remaining larger county/source
reconciliation still prevent acceptance. Publisher 36716247461 remains successful;
mail search found only the answered Texas clarification. No new tests or builds
were needed for this observation-only session. No queued state was activated.

## Compact directory shortcuts — September 30, 14:03 ET

At 800x632 logical, the visible 3384 official KY retailers shortcut opened
the directory list. Selecting ADAIRVILLE MARKET displayed the full address
(135 S Main St, Adairville, KY 42202), the explicit retailer-listing-does-not-
create-a-win disclaimer, Save retailer to Favorites, official Kentucky directory
link and Get directions button. All were visually readable and unobstructed
without resizing. The retailer sheet Back control dismissed it to the selected
retailer's map scope with the correctly scoped empty ranking. Existing Favorites
were not changed; earlier native save/open/remove evidence remains applicable.
External link destinations were not opened in this layout check.

PID 74640 remained unchanged, with no observed crash. This closes compact
directory shortcut confirmation. Reconciled date/detail/source against the
already recorded larger Graves and compact Boone observations. Native offline/
reconnect and larger empty-county/back verification remain outstanding. Keep
the full national/state draw-game inventory in final acceptance. Publisher
36716247461 and mailbox were unchanged; no repeated tests or build were needed.
Kentucky remains unaccepted and South Carolina remains queued.

## Larger county return and afternoon refresh — September 30, 15:04 ET

Native resizing reached exactly 2560x1800 physical (1280x900 logical). From
Adairville, Back selected Logan County. Wheel scrolling exposed the entire
TOP CITIES BY PUBLISHED RECORDS · Logan card, September 28 date, partial-
coverage disclaimer and scoped no-verified-activity explanation. The visible
Back control restored Kentucky and its five records, including Fayette Powerball.
PID 74640 remained unchanged without an observed crash. This closes larger
empty-county/back verification; native offline/reconnect is still outstanding.

Scheduled commit 18b76e4 was fast-forwarded into the clean checkout. Publisher
36759391265 succeeded. Five changed public files (activity, Kentucky draw tiers,
Kentucky Scratch catalog, combined Scratch catalogs and refresh status) independently
matched local bytes. Fourteen Kentucky data/table tests passed against this
refresh; log /tmp/ky-18b-tests.log. The running app's retained September 28
selection is not claimed as a freshly reloaded afternoon source.

Texas failed again in this refresh, while all five previous validated generated
files were byte-identical to b92b63b. New Hampshire's retained catalog was also
byte-identical. Public refresh status discloses both failures. See Texas source
screen for the bounded follow-up; Kentucky acceptance remains separate.
No new agency reply was found. No next-state activation or deadline reset.

## Native network-failure probe — September 30, 16:07 ET

A private entrypoint in ignored work/native_offline_check/main.dart delegates
to the unchanged app main after setting Dart HttpClient.findProxy to an
unavailable local proxy (127.0.0.1:9). Native launch succeeded; connection-refused
logs confirm failed network requests. This is injected network failure, not a
claim that the Mac was physically disconnected. Mac networking and caches were
not modified. Native Kentucky selection still showed 3384 retailers, September
28 published notices including Fayette Powerball, and the saved Mega Millions
September 25 table (2,362 reported winners, $47,127 tier payout). It retained
the older source draw date rather than representing it as the afternoon refresh.
National/state drawing controls remained exposed. Reconnection observation is
still pending; this does not yet close acceptance.

The first attempted harness used sandbox-exec. Two launches terminated before
app initialization with EXC_BREAKPOINT in _libsecinit_appsandbox and signature
SYSCALL_SET_USERLAND_PROFILE. This is distinct from the previous Flutter
AccessibilityBridge EXC_BAD_ACCESS. That harness was abandoned, normal launch
was verified, and a private crash report/logs were preserved in the ignored probe
directory. No security settings or SDK patches were made. The proxy test process
was intentionally quit and the ordinary lib/main.dart build restored afterward.
Publisher/mail checks were unchanged. No queued state was activated.

## Supported release accepted — September 30, 17:03 ET

The restored ordinary lib/main.dart build successfully reloaded Kentucky's
Mega Millions report after the private network-failure probe. Native display
advanced from saved September 25 (2,362 winners/$47,127) to September 29
(2,482 winners/$46,987), exactly matching the independently verified 18b76e4
live report. The draw date and unavailable-publication-date label were visually
readable. This closes tested network-failure/relaunch recovery; it is not a
claim of physical disconnection or same-process network toggling. Normal build
is restored; the private probe is not part of the released source.

Accept supported available Kentucky coverage using the accumulated native
800x632 and 1280x900 evidence, prior full suite/build, focused crash/scroll
regressions, fourteen latest-refresh tests and independent live comparisons.
Scope explicitly includes selected Powerball/Mega Millions notices where
verified, Scratch catalog and winner notices, directory/Favorites, ten statewide
reports (including Powerball variants, Mega Millions, Millionaire For Life,
Cash Ball 225 and Pick 3/4 sessions), and separate Keno/Cash Pop snapshots.
Missing games, tiers, historical claims, location joins and complete statewide
counts remain evidenced limitations in KENTUCKY_SOURCE_SCREEN, not zero wins.
Cash Ball EZ remains separate. No unsupported data layer is implied.

The macOS timeline mitigation passed bounded native resizing/navigation and
relaunch checks without recurrence of the original accessibility crash. This
is release acceptance of observed supported behavior, not unlimited stability
proof. Sandbox harness failures remain separately documented. No new release
prerequisite or deadline extension was added. Kentucky's original and extended
deadlines were missed; this is actual late acceptance. Development now closes
for this scope. South Carolina may activate; Virginia stays behind it.
