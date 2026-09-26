# State completion operating plan

Approved by the user September 24, 2026. This plan controls development priority;
state source-screen documents retain the detailed evidence and request history.

## Completion deadlines — approved September 25

These rules supersede open-ended development and repeated acceptance passes.
All calendar deadlines use America/New_York (Eastern time). A deadline requires
an evidenced release decision; it never permits skipping checks or inventing data.

| State | Release-decision deadline | Current gate |
| --- | --- | --- |
| Texas | Completed September 25, 2026, 06:58 AM ET (due 6:00 PM) | Full supported coverage accepted; broader records remain separate. |
| Kentucky | September 28, 2026, 6:00 PM ET | Implementation starts only after Texas's full supported release decision. |
| Virginia | October 1, 2026, 6:00 PM ET | Implementation starts only after Kentucky's supported release decision. |

Texas's release includes the supported draw-game experience, specifically verified
Powerball and Mega Millions activity. Scratch-only acceptance never satisfies it.
The current evidence already records expanded supported acceptance; the next
session must decide closure rather than invent another enhancement prerequisite.
Once that decision is recorded, advance the active state to Kentucky, then Virginia.
Missing complete statewide records remain a separately tracked data outcome.

For subsequent states, record a calendar deadline at activation: 72 hours for an
existing working import or 120 hours for substantial implementation. Define the
full supported scope and all game gaps within the first 24 hours, included in that
budget. Reserve the final substantive session for integrated acceptance and live
verification. Finish sooner whenever the checklist passes; do not fill the budget.
These are elapsed calendar windows, not a promise of uninterrupted compute time.

At the deadline, release supported coverage with evidence and explicit unavailable
features, or record a concrete release-blocking defect, the unfinished acceptance
item, and one extension: at most 24 hours for a 72-hour state, or 48 hours for a
120-hour state. Texas may receive at most one 24-hour extension. Record and notify
the reason and revised timestamp immediately. No silent or repeated extensions.
If still blocked after that extension, report the blocker and required intervention;
continue independent checklist work without declaring completion or advancing to
another state. A host outage also requires a visible schedule revision, not an
invisible reset. Reforecast dependent calendar dates explicitly if a predecessor's
extension affects them; never work on two active states to hide a missed deadline.

After acceptance, put enhancements in a backlog. Reopen only for an actual defect
or meaningful newly verified data, with a named gap and bounded deadline. Routine
refactoring, extra research and unchanged polling never reopen completed scope.
Agency requests retain their own promised response/follow-up dates and do not
extend app deadlines. No fees, privacy exceptions or weaker validation are allowed.
Notify release decisions, deadline misses/extensions, material failures and user
actions; remain quiet for unchanged status. This planning edit does not itself
constitute Texas's final acceptance session.

## Active work: Kentucky

Texas's full supported release decision was completed September 25, 2026 at
06:58 AM ET, before its deadline. Development is closed for the verified available
coverage, including Powerball and Mega Millions activity. Complete statewide
claims remain unavailable and are tracked separately. See the release decision
at the end of this document; earlier Texas-active statements are historical.

Kentucky is now active. Its release decision remains due September 28 at 6:00 PM
ET; scope and per-game gaps must be reconciled by September 26 at 06:58 AM ET.
Use the existing Kentucky checklist and source screen. Explicitly inventory
Powerball, Mega Millions and all supported Kentucky draw games as well as Scratch
before defining acceptance; do not repeat the earlier Scratch-only scope error.
Virginia remains queued until Kentucky acceptance, due October 1 at 6:00 PM ET.

Two separate outcomes remain mandatory: **accepted for available coverage** and
**complete statewide data**. Missing records do not establish zero wins. Accepted
scope must include all supported flows with evidenced unavailable features.

## Session rules

1. Check repository, deployment, current source documents and agency replies
   once. Handle urgent failures, then advance a named acceptance requirement.
2. Do not spend a healthy session polling alone. Record the acceptance work and
   evidence obtained, or the concrete blocker and independent work completed.
3. Research only when it can unlock a named feature or resolve a material
   accuracy question. Park unresolved requests separately from app completion.
4. Run tests proportional to the change. Before acceptance, verify integrated
   visual and interaction flows, offline behavior, and live deployment separately.
   Passing data/unit tests alone is not integrated acceptance.
5. Publish successful state refreshes independently. On importer failure restore
   all of that state's prior files byte-for-byte, preserve dates, and disclose the
   failure in the public refresh-status report. Shared publication validation
   remains mandatory; no baseline means publication must stop.
6. Notify meaningful progress, state testing readiness, completion, failure or
   required action. Keep unchanged monitoring quiet. No fees, invented retailer
   locations, guessed counts, or hidden coverage expansion are authorized.

## Kentucky acceptance checklist

Scope: official Scratch catalog, verified retailer directory, selected current
and retained historical winner notices, and supported draw information. No
complete statewide winner counts or retailer win ranking is implied.

- [x] Catalog browsing, selection, remaining-count semantics and reset.
- [x] Verified map points, retailer details and separate-directory explanation.
- [ ] State/county/game/prize/date filters, reset and scoped empty states.
- [ ] Notice-date precision and timeline semantics; no invented event times.
- [ ] Accessible source, period, cadence and partial-coverage explanations.
- [ ] Bundled/cached offline behavior and unchanged-date reconnection.
- [ ] Compact and larger native layout and interaction checks.
- [ ] Appropriate automated checks and independently verified live feeds.
- [ ] Evidence reconciled and Kentucky explicitly announced ready for testing.

## Texas acceptance checklist

Scope: current official Scratch catalog, mapped verified retailer directory,
selected Scratch top-prize claim activity, and supported draw-game information.
This scope does not include complete all-tier statewide winning-ticket totals.

- [x] Catalog browsing and available filters work; unknown remaining counts stay
      unknown and remaining prizes are not described as store stock.
- [x] Map loads verified points and retailer details; a directory location alone
      never becomes a winning-ticket record.
- [x] State, county, game, prize and date filters behave consistently wherever
      offered, including clearing filters and returning to the default view.
- [x] Timeline date semantics and source coverage are visible and accurate.
- [x] No-results views explain missing or filtered data without implying zero
      statewide wins; denied/unavailable features have scoped explanations.
- [x] Sources, periods, cadence and partial-coverage limitations are accessible.
- [x] Bundled/cached data loads offline and reconnecting does not inflate dates.
      Evidence: native blocked-network pass below plus loader reconnection tests;
      offline street tiles and downloaded-directory persistence are not promised.
- [x] Integrated visual/interaction checks pass at representative window sizes.
- [x] Relevant automated checks pass; live feeds are independently verified.
- [x] Evidence is recorded and Texas is explicitly announced ready for testing.

Existing automated evidence: Texas generated catalog/directory/activity, draw
menu and offline activity checks exist in `test/services/texas_generated_data_test.dart`.
The native interaction evidence below closes the corresponding items.
Kentucky and Virginia follow the same checklist adapted to their sources.

## External requests and user actions

Use the latest state source-screen documents, not stale automation snapshots.
New York, Illinois, Rhode Island and West Virginia deliveries remain limited by
their documented definitions/joins. Keep private originals private and do not
deduplicate unidentified claims. Rhode Island paid assembly remains on hold.
Monitor New Mexico's October 1 promised response and Pennsylvania's extensions.
Previously identified Arizona user attestation and Mississippi signature/mail
requirements are separate optional records tasks; do not ask again for supplied
mailing address or phone. None prevents finishing available-data app flows.

## September 24 Texas acceptance pass

At an 800 × 632 macOS window, navigated from South Carolina to the national
map and selected Texas. Opened the Scratch catalog and selected Bonus Break the
Bank; the panel closed and the scoped no-matching-activity notice remained.
This checks interaction only, not correctness across all date/filter settings.

Found and fixed severely overlapping county names at statewide zoom. Labels now
reserve measured screen space, prioritize selected/hovered counties, and reveal
additional names as zoom increases. Rebuilt, restarted the actual app, and
visually verified Texas at overview and one closer zoom. County boundaries and
underlying activity data are unchanged. Build passed; analysis retains the 12
existing informational notices. This is partial visual acceptance, not a state
completion sign-off.

Next concrete gap: the official retailer shortcut overlays the expanded Scratch
catalog panel at this window size. Resolve that stacking/interference, then
continue the filter-reset, timeline, retailer details and broader window checks.

Publisher 35970788624 succeeded: all four live feeds plus the new JSON/HTML
refresh-status report match 734d2b5. New Hampshire was retained after importer
failure while other states updated, demonstrating the independent-state policy.
Oklahoma's updated catalog is live; this does not expand claims-map coverage.

## September 24 Texas catalog and retailer interaction pass

Resolved the expanded-catalog overlap by rendering the compact state toolbar
above map shortcuts and controls. At 800 × 632, rebuilt and restarted the native
app, entered Texas, expanded its catalog and scrolled to Texas Loteria. Clicking
that row at the old retailer-shortcut position selected the game and closed the
panel; it did not open the underlying picker. After closing the panel, the
retailer shortcut opened normally. This validates both stacking and tap routing.

Searched the Texas retailer picker for Abbott: three matching locations were
shown. Selected Abbott's Travel Center and verified the address/county detail
sheet and the explicit statement that a directory listing alone does not create
a heat-map win. No directions or gambling transaction was initiated.

Nine targeted Texas/map/timeline tests and the macOS debug build passed.
Analysis retains the same 12 informational notices. All four live feeds and
refresh-status JSON still match the successful publication; no agency replies
were found during the initial check. This code is a native-app change, not a
new feed deployment.

Next acceptance work: exercise game-filter reset and date/timeline controls
with known covered dates, then resize and inspect those flows. The current
compact window clips most of the bottom timeline behind navigation, so its
layout and reachability need particular attention before state sign-off.

## September 24 Texas timeline reachability pass

Fixed the home map's forced 720-pixel minimum exceeding the available window
height. Its height now respects the available viewport, keeping the timeline
above bottom navigation. Rebuilt and restarted at 800 × 632; date anchor,
Day/Week/Month/Year controls, slider and return-to-now action are now visible.
Find a State search also successfully opened Texas at this size.

Selected August 14, 2026 (a date present in the verified Texas feed), then Week
scale's whole-day bucket: Texas county activity appeared and the scoped empty
notice disappeared. Return-to-now restored September 24 and the corresponding
no-matching-activity notice. Six targeted Texas/timeline tests and the macOS
build passed; analysis retains 12 existing informational notices. Live feeds
remain unchanged and verified; no new agency replies were found.

Next accuracy gap: Day scale selects an hourly bucket, but Texas claims are
provided with day-level dates rather than verified claim times. At 6 AM the
August 14 records disappeared, then appeared in the whole-day bucket. Resolve
that date-precision mismatch without inventing claim times, then finish
Scratch game reset and larger-window checks. Texas remains unaccepted pending
these remaining checks.

## September 24 Texas date precision acceptance pass

Texas now uses daily-or-coarser timeline buckets because its verified claims
source supplies dates without claim times. Entering Texas from an hourly view
automatically selects a whole-day bucket; the hourly Day option is hidden and
the timeline explicitly says “Claim dates only; times unavailable.” Original
source dates and records are unchanged. Other states retain their existing
controls pending their own source-precision review.

Rebuilt and restarted the native app at 800 × 632. Entered Texas through Find a
State, verified automatic Week selection and the precision notice, then selected
August 14, 2026. County activity appeared immediately without a manual scale
change, resolving the previously observed misleading empty hourly view.

All 72 Flutter tests pass, including initial and transition date-precision
regressions; the macOS debug build passes. Analysis retains 12 existing
informational notices. Initial checks found no new agency mail and verified
all four live feeds plus refresh-status JSON against the published files.
This is a native-app fix, not a new public feed deployment.

Next acceptance work remains Scratch game-filter reset, larger-window layout,
and integrated source/scope and offline behavior. Texas remains the active
state and is not yet signed off for its full available-data experience.

## September 24 Texas game reset and ranking scope pass

At 800 × 632, selected Bonus Break the Bank, then August 14, 2026.
The scoped no-matching-activity message appeared. Reopened Scratch and verified
that game was selected; choosing All Texas Scratch-Off activity restored mapped
activity without changing the date. This closes the specific Scratch game-reset
interaction gap, not every county/prize filter combination.

Zoomed the native window to the desktop size. Timeline, map controls and the
county ranking were visible. The ranking previously said “winning tickets”
without a local coverage warning. Texas rankings now say “published claims”
and explain that only selected Scratch top-prize claims with verified retailer
matches are included, filtered to the current view, not all Texas wins or tiers.
Rebuilt/restarted and visually verified the heading, metric and scope notice in
the larger layout, including its filtered-empty state. No underlying data changed.

The macOS debug build and targeted Texas/ranking tests passed; analysis remains
at 12 existing informational notices. All live feeds/status matched local
published files at the initial check; no new agency replies were found. One
initial computer-control attempt reported the app quit; relaunch restored it
and repeated catalog interactions succeeded. No reproducible catalog crash was
established.

Texas remains active. Next: integrated source/cadence accessibility, offline
loading/reconnection, and remaining county/prize filter combinations. This
partial acceptance and native-app copy fix do not constitute final readiness
or a new feed deployment.

## September 24 Texas offline cache retention repair

Found a loader regression while advancing offline acceptance: it restored a
valid device cache, then replaced it with bundled assets when remote downloads
failed. Downloaded Texas claims absent from an older bundle could disappear,
and the repository lost its cached-data status.

The loader now retains the restored snapshot when no remote feed succeeds.
First-run offline behavior still loads bundled verified records. Added a
regression that downloads a Texas fixture, simulates HTTP 503, verifies all
records and original update/source dates survive with cached status, then
reconnects to the same feed and checks records/dates remain unchanged while
cached status clears. The fixture is test-only and never published.

All 73 Flutter tests pass; analysis retains 12 existing informational notices.
The macOS debug build passes. This verifies the loader/cache/repository path,
not yet a complete native offline visual/reconnection acceptance pass.

Scheduled publisher 35999880720 succeeded. Fast-forwarded its aaf9f06 feed
commit and independently verified all four public feeds plus status JSON match.
Initial agency-mail check found no new responses. Texas remains active; native
offline/source accessibility and remaining county/prize filter checks remain
before a final available-coverage sign-off.

## September 24 Texas source-cadence gap

The shared official-source screen already exposes limitation notices and the
public refresh-status link, but Texas had no cadence notice. Added an explicit
distinction between Lottery Atlas's six-hour import attempts and the unconfirmed
agency publication cadence, with instructions to check individual source dates
and an explanation of retained data after failed refreshes. This notice is
also used by the map's existing source/coverage surface. Native visual
acceptance of this notice and offline reconnection remains outstanding.

A broader mail search discovered September 23 replies missed by prior narrow
checks. Updated Virginia (declined eligibility scope), Connecticut (public
referrals/unavailable joins), West Virginia (agency response closed, unresolved
definitions), Missouri (workbook received but not audited; daily draw-sheet
cadence), and Wisconsin (pending). Use an overlapping date window for future
mail checks and consult recorded responses to avoid duplicate follow-ups.
Texas remains active; these replies do not block scoped acceptance.

## September 24 Texas source-screen visual acceptance

Rebuilt and opened Texas through Find a State, then TX Lottery at 800 × 632.
Verified the six-hour Atlas refresh explanation is readable and distinguishes
it from unconfirmed agency cadence. Scrolling reaches dated top-prize retailer
reports, retailer directory, request links and the Atlas refresh-status button.
Found this screen lacked a Texas-specific coverage notice; added the verified
Scratch top-prize/selling-retailer/date-only scope and the separate-directory
limitation through the shared limitation registry. Rebuilt/restarted and
visually verified the complete notice and cadence text without clipping.

Build passes; analysis retains the 12 existing informational notices. No data
or parsing changed. Public feeds and status still match the latest successful
publisher; no September 24 agency responses appeared in the initial check.
This closes the specific source-screen reachability/cadence/coverage-copy gap.
Per-record date inspection, native offline/reconnection and remaining
county/prize filter combinations still need acceptance; Texas remains active.

## September 24 Texas catalog/directory offline acceptance tests

Extended Texas loader acceptance to verify first-run HTTP-503 fallback loads
the complete bundled catalog and directory, preserves its official source URL,
and does not add any records to the separate claims repository. Added a cached
catalog regression using a test-only future-dated fixture: newer cached games
and their state-scoped timestamp survive offline reload and an unchanged
reconnection. Tests use one in-memory preference platform cleared per test so
static service instances share the same store. All eight Texas tests pass.
No production data or importer behavior changed in this pass.

Limitation: retailer directories currently have bundled fallback but no
persistent downloaded-directory cache. A failed refresh therefore uses the
app-bundled directory, not necessarily the last downloaded directory. Native
offline/reconnection and per-record date/filter interaction acceptance remain
open; these service tests alone do not sign off Texas.

Initial live checks matched all four feeds and status JSON. South Carolina's
September 24 response is recorded in its source screen: requested consolidated
report unavailable, narrowing assistance offered, no delivery or fee approval.

## September 24 native Texas offline acceptance

Built a private acceptance entry point in ignored work/offline_acceptance.dart.
Its Dart HttpOverrides directs HttpClient traffic to a refused loopback proxy
(port 1, connection-refused verified), without changing computer network settings.
This tests application HTTP failure, not OS-wide airplane mode or external
browser links. Rebuilt and launched the actual macOS app at 800 × 632.

Verified offline navigation to Texas, the 19,655-location bundled directory
count, Scratch catalog rows, and August 14 whole-day mapped claim activity.
Opened Abbott's Travel Center from the directory and inspected the address,
county and explicit directory-is-not-a-win warning. Street-map tiles are not
guaranteed offline; local boundaries and lottery data remained usable.

Restored the standard lib/main.dart build, restarted it and verified normal
startup. Both final builds passed. Earlier service reconnection tests verify
records and source dates remain unchanged when the same feed returns; this
pass adds actual offline UI evidence. The private harness is not a production
entry point and was not committed or deployed.

Initial feed checks matched live files; mail contained only the already-recorded
South Carolina reply. No new action needed. Remaining Texas acceptance focuses
on per-record source/date visibility and county/prize filter combinations.

## September 24 Texas claim-date semantics repair

Inspected the individual activity detail path and found Texas claims still
labeled DRAW DATE, with a global merged-feed refresh timestamp beneath the
individual official source. Changed Texas's label to CLAIM DATE and replaced
that ambiguous timestamp display with an explicit explanation: time of day and
a separate source publication timestamp are not supplied for the claim; the
combined feed refresh is not its verification date. No source dates or records
were fabricated or changed.

Eleven Texas/timeline tests and the standard macOS debug build pass. Analysis
retains the 12 existing notices (the ignored offline harness import was also
corrected). Native inspection of this particular detail sheet remains pending,
as do county/prize filter combinations. Texas remains the active state.

Initial live-feed checks matched all published files. New agency responses:
Vermont quoted $1,368 and remains on hold under the no-fee instruction;
Washington estimates a January 18, 2027 response after a December 21 vendor
response and redaction review. These are recorded in source-screen documents
and do not block scoped app completion. No fee was authorized.

## September 24 county-to-claim detail acceptance

On August 14, selected the Texas heat point for Johnson County: the county
sheet showed one qualifying record and a $1K prize; its list opened the
Burleson claim for game 2678. Verified CLAIM DATE reads Fri, Aug 14.
Found mouse-wheel input was still routed to the map after the county sheet
opened an individual claim, preventing source-section access. The individual
sheet now releases/restores native map scroll handling, and county-to-claim
navigation waits for the next frame so the closing county sheet cannot
re-enable map scrolling over the new sheet.

Rebuilt/restarted and repeated the exact flow at 800 × 632. Scrolling now
reaches the official game/date source label and supporting source link. The
source explanation correctly distinguishes claim date from an unavailable
publication timestamp. Also replaced the county summary's ambiguous merged
refresh date with its partial top-prize scope and a direction to individual
claim evidence. Both source sections were visually verified. Eleven targeted
Texas/timeline tests and the macOS build pass; analysis retains 12 infos.

Latest publisher 36041852687 succeeded; fast-forwarded 110cb9f and independently
verified all public feeds/status. No new agency replies beyond recorded ones.
Next concrete gap: the individual claim sheet still offers View Lottery
Details, which currently invokes a coming-soon message. Remove or implement
that unsupported action for Texas, then finish remaining filter acceptance.
Texas is still active, without a final readiness sign-off.

## September 24 Texas official claim action acceptance

Replaced the Texas individual claim sheet's unfinished View Lottery Details
action with Open Official Claim Source. It opens the record's existing source
URL, and is omitted if that URL is absent. At 800 × 632 in the native app,
opened the August 14 Johnson County claim for Burleson/game 2678, scrolled to
the action and clicked it. Chrome opened the corresponding official Texas
top-prize selling-retailer report; its date and retailer matched the displayed
record. No ticket or pack identifiers were copied into public data or this log.

All 75 Flutter tests and the standard macOS debug build pass; analysis retains
12 existing informational notices. Independently compared all four live feeds
and refresh-status JSON with the repository: all match. Agency mail contains
only the already-recorded September 24 South Carolina, Vermont and Washington
responses. This is a native-app action fix, not a new feed deployment.

The opened report also supplies a page-level September 23 as-of date and says
its rows include fully processed claims; filed claims may appear in game-page
counts before this report. That page-level date is distinct from an individual
claim date or the combined Atlas refresh. Follow-up acceptance should ensure
this processing limitation is accessible and inspect whether imported metadata
can preserve the report as-of date without pretending it is a claim timestamp.
Remaining county/prize filter combinations and resets still need interaction
evidence before Texas's available-coverage sign-off.

## September 24 Texas processing limitation implementation

Added the official report's fully-processed-claims limitation to the shared
Texas notice used by the source screen and map coverage surfaces. It explains
why recently filed claims may already appear in game-page counts while absent
from selling-retailer reports. Eight Texas loader/data tests and the standard
macOS debug build pass. The enlarged notice still needs a native layout check;
this pass does not close integrated visual acceptance.

Inspected the importer: sourceLastUpdated currently holds the latest included
claim date, not the page's report as-of date. Recorded this distinction in the
Texas source screen and left original dates unchanged. Initial checks found a
clean repository, all five live JSON files matching, and no new agency replies
beyond the recorded September 24 messages. Next work remains county/prize
filter-reset interactions and the expanded notice's layout.

## September 24 Texas county/prize reset and notice visual acceptance

Restarted the latest standard native build at 800 × 632. The expanded Texas
source-screen notice displays the processing delay, date precision, partial
coverage and separate-directory explanation without clipping; cadence remains
visible below it. This closes the preceding notice-layout follow-up.

Selected August 14 and Johnson County, inspected its one qualifying $1K record,
dismissed the detail sheet and used Back. The map returned to the Texas overview
and preserved August 14. A second Back returned to the national controls.
Applied the shared prize range displayed as $109K–$30.0M, re-entered Texas and
verified the same date produced the scoped no-matching-activity explanation.
Returned to the shared prize controls, restored $1–$60M and applied it. Re-entering
Texas restored mapped claims on August 14 without changing the date. This adds
prize inheritance/reset and county-back evidence to earlier game/date resets.
The filter and scoped no-results checklist items are now accepted for these
supported flows. Prize controls currently require returning to the national
view; they are not offered directly by Texas's compact toolbar.

No production code changed, so no redundant build/test run was needed. Live
feeds/status independently match repository files; mail has no new responses.
Texas remains active: catalog remaining-count semantics and supported draw
flows need final integrated review before the overall testing-ready sign-off.

## September 24 Texas catalog semantics acceptance

At 800 × 632, found the catalog's numeric “remaining” label ambiguous. Shared
verified-catalog rows now explicitly say “top prizes remaining”; missing counts
say “Remaining count unavailable” without substituting zero. The panel explains
that remaining top prizes are not store stock. Rebuilt/restarted the standard
app and visually verified the explanation and both first rows fit correctly.
Together with earlier catalog scroll, selection and reset passes, this closes
the catalog checklist item for the available Texas catalog. Eight Texas tests
and the macOS debug build pass; no data or counts changed.

Opened Drawings in Texas and observed named draw games, CDT schedule labels
and countdowns. Selecting Lotto Texas closes the panel and produces the scoped
no-matching-activity view. Remaining draw acceptance should inspect selected-game
feedback and reset behavior; this observation alone does not establish schedule
accuracy or full draw-flow acceptance. An initial app-control attempt reported
the app quit; relaunch and repeated catalog actions succeeded. This intermittent
interruption remains noted rather than classified as a reproduced catalog crash.
Initial repository was clean; all five live JSON files matched; agency mail
contained only previously recorded replies. Texas remains active, not yet
announced ready for the full available-coverage experience.

## September 24 Texas draw selection and recovery acceptance

Selecting Lotto Texas previously displayed a generic suggestion to widen the
prize/date filters even though Texas's mapped feed has no draw-game claims.
The Texas empty notice now names the selected draw game, states that claim
locations are unavailable, explains the selected Scratch top-prize scope and
points to All Texas Scratch-Off activity as the recovery action.

Rebuilt/restarted at 800 × 632, selected Lotto Texas and visually verified the
complete new notice. Selected All Texas Scratch-Off activity, then August 14:
mapped Scratch claims returned and the draw-specific notice disappeared. Eight
Texas tests and the standard macOS build pass. This closes selected-draw
feedback and recovery, without asserting draw-claim coverage. Final acceptance
review must reconcile the remaining checklist and schedule-source evidence.

Pulled the scheduled a87e221 publication and independently verified all four
live feeds and refresh-status JSON match. Agency mail had no new messages
beyond recorded replies. No private records or new coordinates were published
by this app change.

## September 25 UTC Texas available-coverage acceptance

Texas is **ready for testing of the available-data experience** at c320f46,
with published data a87e221. This is not complete statewide claims coverage.
The previously unchecked items were reconciled with recorded evidence: Abbott
retailer details and the separate-directory warning; August 14 county/claim
inspection; date-only timeline and reset; source-screen cadence and coverage;
compact and desktop-size native visual passes; offline HTTP-failure pass and
loader reconnect tests. These are completed checks, not new untested promises.

Final review: all 75 Flutter tests pass; analysis has the same 12 informational
notices and no errors/warnings. The latest standard macOS build passed in the
preceding draw-recovery pass. All five live JSON files independently match
repository publication. No new agency mail appeared in the initial check.

Compared the implemented Texas state schedules with official sources on
September 25 UTC: Lotto Texas Monday/Wednesday/Saturday; Two Step Monday/Thursday;
Cash Five Monday–Saturday, each at 22:12 Central. Pick 3, Daily 4 and All or
Nothing use Monday–Saturday 10:00, 12:27, 18:00 and 22:12 Central. References:
[official drawing schedule](https://www.texaslottery.com/export/sites/lottery/Games/Drawing_Schedule/),
[Daily 4](https://www.texaslottery.com/export/sites/lottery/Games/Daily_4/),
[All or Nothing](https://www.texaslottery.com/export/sites/lottery/Games/All_or_Nothing/),
[Two Step](https://www.texaslottery.com/export/sites/lottery/Games/Texas_Two_Step/).
The native menu, selected-draw limitation and Scratch recovery were verified
in preceding passes. Schedule availability does not imply mapped draw claims.

Accepted limitations: selected Scratch top-prize claims with verified joins
only; claim dates have no times; directory is separate; remote directory is not
persistently cached; offline street tiles are not guaranteed; report as-of
metadata remains distinct from latest included claim date and is accessible at
the official source. Isolated app-control quit reports did not reproduce during
repeated navigation; retain them as a testing observation. No claim of zero
defects, complete records, or a newly deployed native application is made.

Kentucky is now active. Its next pass must read KENTUCKY_SOURCE_SCREEN.md,
identify its supported scope, and execute the equivalent native acceptance
checklist. Texas records requests and future data improvements continue
independently of Kentucky acceptance.

## September 25 Kentucky first source-screen acceptance pass

Opened Kentucky's source screen in the native app at 800 × 632. It had no
state-specific limitation or cadence notice. Added selected-winner and retained
historical coverage, excluded unmatched locations, separate-directory limits
and notice-date caution. The cadence notice distinguishes Atlas's six-hour
attempts from unconfirmed agency publication cadence and retained source dates.
The standard macOS build passes. Rebuilt/restarted and verified both notices
are completely readable without clipping at the compact size. No data changed.

Current generated files contain 36 current notices dated August 31–September 23,
2026 and eight retained historical notices dated March 8, 2024–December 12, 2025.
These are source-specific record counts, not distinct-ticket or statewide totals.
Initial live feeds/status matched and agency mail contained only recorded
responses. Next concrete gap: current and historical notice importers encode
date-only headings at synthetic noon, while Kentucky still offers hourly
timeline filtering. Resolve precision/display semantics before accepting dates.
The checklist remains open; this pass establishes visible coverage/cadence only.

## September 25 Kentucky timeline precision repair

Kentucky now uses whole-day or coarser timeline buckets. Entering from an hourly
state automatically selects Week and shows “Published dates only; times
unavailable”; Texas retains its existing claim-date wording. Original imported
dates remain unchanged. The shared initial-range regression now verifies the
published-date label and whole-day emission, alongside the existing transition
and calendar tests: all three pass. Standard macOS build passes; analysis
retains 12 informational notices.

Restarted native app at 800 × 632, entered Kentucky from South Carolina's hourly
view and verified Day is absent and the new wording is readable. Selected
September 23, 2026; mapped notice activity appeared immediately without any
manual scale adjustment. All live JSON files matched at startup; no new agency
mail. Next date acceptance gap: individual Kentucky details still use the shared
DRAW DATE label and merged-feed timestamp; review their notice-date semantics
and source accessibility before marking the full date checklist complete.

## September 25 user-directed Texas completion requirements

- [x] Verify and import available Powerball retailer-level winner records.
- [x] Verify and import available Mega Millions retailer-level winner records.
- [x] Inventory each other Texas draw game's official counts/location sources; implement supported flows.
- [x] Distinguish game, tier, draw/claim/publication dates, period and missing coverage.
- [x] Verify map selection, filters, resets, defaults and source links for both national games.
- [x] Integrate refresh/retention validation, tests, build and independent live verification.
- [x] Reconcile full Texas acceptance before advancing any other state.

Do not call schedules plus Scratch-only points fully developed Texas. Agency
requests remain no-fee; unavailable data is not permission to invent points.

### September 25 Powerball / Mega Millions implementation progress

- Implemented an official Where Sold importer: 190 draw pages, 10 exact-address
  mapped second-tier records; three unmatched addresses and one shared-jackpot
  amount excluded. No complete all-tier coverage implied.
- Added explicit map shortcuts opening the latest mapped draw date and resetting
  Texas camera bounds. Native inspection verified both games and source details.
- Added bundled/offline coverage, six importer checks and Texas refresh rollback
  integration. 75 Flutter tests and macOS build pass (12 existing analysis infos).
- Texas remains active. Other draw-game source inventory and integrated full-game
  acceptance are outstanding; this is not a new Texas completion declaration.

### September 25 expanded draw-game acceptance

- Official 2026 Where Sold coverage now includes Lotto Texas, Texas Two Step,
  Cash Five and All or Nothing in addition to Powerball and Mega Millions.
  Native game switching verified September 5, September 10, September 16 and
  August 3 latest mapped dates respectively. County details verified Lotto Texas
  Houston $7.5 million. Individual source copy distinguishes nominal prizes from
  verified cash payouts and draw dates from claims. Camera targets latest records
  so the timeline does not hide the selected point.
- Daily 4 native selection correctly explains unavailable selling locations,
  without claiming zero statewide wins. Pick 3 has the same evidence limitation.
- Seven draw importer checks (62 Node checks total), 75 Flutter tests, macOS build
  and analysis pass with only the 12 pre-existing infos. Offline fixture checks
  now require all six draw games. Live verification remains pending publication.
- No-fee follow-up sent in the existing Texas records thread, message
  1a0d714b2dc394b0, requesting receipt/status and existing row/prize/location/cadence
  definitions and missing Pick 3/Daily 4 retailer reports. August request unchanged.
- Texas remains active through final deployment and acceptance reconciliation.

Publication speed correction: push-triggered runs validate and publish the
checked-in reviewed data without refetching every state's sources. Scheduled and
manual runs retain the full six-hour refresh workflow and per-state rollback.
Push-only publication does not advance refresh/source dates. This removes an
unrelated multi-state import delay from Texas acceptance without weakening
publication validation.


### Live publication verified September 25

Publisher 36099818061 succeeded. Independently downloaded the live activity feed:
it is byte-for-byte identical to the local validated feed and contains all 144
Texas draw records across six games. The three other public catalog/directory/
state-total feeds also returned valid JSON. The native debug build succeeds;
75 Flutter, 62 Node and the Python suite pass, with 12 existing analysis infos.
Larger-window layout and return from draw selection to All Texas Scratch-Off
activity were visually checked. Texas draw activity is ready for testing.

Texas is **not** being advanced to Kentucky. Remaining acceptance work: complete
national-game prize/date/favorite/source-link interaction checks on the final
build; reconcile per-game limitations and the Scratch report footer as-of date
with the current latest-claim-date metadata; then review the full checklist.
Agency-only lower-tier and Pick 3/Daily 4 selling locations stay explicitly
unavailable and do not prevent finishing the supported app experience.


### Final provenance release verified September 25

Publisher 36100256963 succeeded for commit 489feb3. Live activity again matches
local validation exactly: 6,473 Texas Scratch claim records plus 144 draw records.
All current public Scratch IDs are opaque hashes; all Scratch record labels show
the report's September 23 as-of date separately from the claim date. Migration
normalizes old bundled/cache IDs and saved map favorites. 76 Flutter tests pass;
macOS build passes and analysis remains at 12 existing informational notices.

Final native Powerball inspection verified automatic August 8 date/focus, source
and nominal-prize limitations, add/remove favorite persistence (test addition
removed), and the official source button opening the correct draw report. Both
national games and all four supported state draw games have been exercised.
Scratch reset and compact/larger layouts have been checked. The expanded Texas
experience is ready for testing; complete statewide all-tier coverage is not
claimed. Texas remains the active state. The next available-data enhancement is
separate statewide draw-tier totals, which must never be mapped onto retailers
or summed across overlapping multiplier columns. Missing retail-location data
continues through the existing no-fee request.

### September 25 follow-up: statewide tier parsing

Started the separate Texas statewide prize-table path. The new parser preserves
source headers, each tier and each reported total column independently; it does
not produce map points or a combined ticket total. Real Powerball August 8 and
Lotto Texas September 5 fixtures demonstrate why: Power Play counts overlap the
base count, while Lotto Extra includes an Extra-only two-number tier. Each column
must reconcile independently. Unknown values, wrong dates/games, spanning cells
and inconsistent totals fail closed. Three new regression checks pass; 65 Node
checks pass overall. This is parser preparation, not a newly shipped app feature.
Next: inspect Mega Millions' multiplier layout and connect reviewed per-game
reports to a separately labeled statewide table view. Do not repurpose map counts
or the all-tier state ranking. Live deployed activity remains unchanged and
matches local; no new reply arrived in the checked Texas/NY/WV mailbox search.

### September 25 statewide prize-table implementation

Added a separate Drawings in Texas → Statewide prize tables view with nine
latest-draw reports across Powerball, Mega Millions, Lotto Texas, Texas Two Step,
Cash Five and the four All or Nothing sessions. Each table retains official tier,
prize and winner columns independently; no rows become retailer map activity.
Mega Millions multiplier partitions are validated against each tier total.
Source publication dates remain explicitly unavailable; draw dates are shown.
Pick 3/Daily 4 are explicitly excluded from this view pending source review.

The importer participates in Texas transactional refresh/rollback and six-hour
publication, with bundled/cache fallback. At 800×632, native acceptance verified
readable wrapped headers, game switching, horizontal scrollbar access to 10X
columns, and vertical access to the final total row. 77 Flutter tests passed
before the scrollbar refinement; the targeted widget test and macOS debug build
passed again afterward. All 66 Node checks pass. Analysis retains 12 prior infos.
Texas remains active; next gap is Pick 3/Daily 4 statewide source review and final
acceptance reconciliation. Complete statewide retailer claims are not asserted.

### September 25 Pick 3 / Daily 4 source review and coverage flow

Inspected both September 24 official detail pages, reached through their current
Winning Numbers indexes. The main content contains drawn digits and FIREBALL
combinations, no HTML prize-count table and no Where Sold section. This is a
concrete limitation of these reviewed reports, not a claim that no such records
exist elsewhere or that there were zero winners. Detail URLs:

- https://www.texaslottery.com/export/sites/lottery/Games/Pick_3/Winning_Numbers/details.html_1158379760.html
- https://www.texaslottery.com/export/sites/lottery/Games/Daily_4/Winning_Numbers/details.html_1158379760.html

Added an accessible “Missing games?” explanation beside the statewide table's
source button, with direct official results links for both games. Native 800×632
inspection confirmed readable explanation and both links without overflow;
widget interaction test and macOS build pass. The original no-fee request remains
pending; no new request or fabricated count was created. Startup mail check had
no new agency messages. Publisher 36105817217 succeeded and the live nine-table
feed still exactly matches the validated local copy.

The eight-game source inventory is now reviewed. Texas stays active. Remaining
acceptance work: explicitly exercise the newly added table view's bundled/cache
fallback and reconnection, then reconcile the revised full Texas checklist.

### September 25 full supported Texas acceptance reconciliation

The supported Texas experience is accepted for the verified coverage described
below. This supersedes the earlier Scratch-only acceptance; it does not establish
complete statewide claim data. Texas remains the active state for follow-up.

- Scratch: catalog, directory, 6,473 mapped top-prize claims, claim/report dates,
  opaque public IDs, filters/reset/favorites and sources accepted.
- Powerball and Mega Millions: 10 verified mapped second-tier records combined,
  latest mapped-date shortcuts, camera focus, filters, details and sources accepted.
- Lotto Texas, Texas Two Step, Cash Five and All or Nothing: supported mapped
  activity accepted; all six draw games total 144 mapped records. Exact-address
  exclusions and nominal-prize limitations remain explicit.
- Statewide tier tables: nine reports across those six games, separate from map
  counts, preserve tier/multiplier columns, dates and official source links.
- Pick 3/Daily 4: schedules/results links and evidence-based unavailable-count/
  location explanations accepted. Reviewed reports lack counts/Where Sold tables;
  the existing no-fee records request seeks missing coverage. No zero inferred.
- Compact/larger native interaction evidence is recorded above. New loader tests
  now exercise first-launch offline bundle, saved cache, corrupt response/cache,
  reconnection with unchanged source dates and persistence failure. An integrated
  offline widget test opens the actual table and coverage dialog. A cache-write
  failure no longer discards a valid downloaded report.

83 Flutter tests and macOS debug build pass. Live nine-table feed matches the
validated local data independently; publisher 36105817217 succeeded. This change
only affects the native loader/tests, so no public data publication is required.
Complete statewide retailer claims and lower tiers remain unavailable; acceptance
of supported flows does not imply that missing data has been obtained.

### September 25 publication acceptance follow-up

Closed a publication gap in the new statewide tables: pushes skip source refresh,
so the prior plain file copy could publish an edited JSON file without validating
its report structure. The publisher now checks the nine unique game/session
reports, official game-specific URLs, real calendar dates, provenance, row shape,
winner-column totals and Mega Millions multiplier partitions before writing.
It preserves the exact validated bytes and source dates. Two regression checks
cover current data and malformed/missing/duplicate reports; all 68 Node checks
pass. No source data or app UI changed. Existing live tables matched at startup;
no new agency replies. Texas remains active and its supported acceptance remains
as documented above. This strengthens publication acceptance without claiming
additional statewide coverage.

### September 25, 06:58 AM ET — Texas release decision: accepted and closed

Decision: the full supported Texas experience is complete for the verified
available coverage. This includes Scratch, verified Powerball/Mega Millions
retailer activity, four other draw-game activity layers, nine statewide prize
tables, and evidence-based Pick 3/Daily 4 unavailable-data explanations with
results links. It is not a declaration of complete statewide claim coverage.
No release-blocking defect remains in the recorded acceptance evidence. No
extension was used. Kentucky becomes active under the approved deadline rules.

Acceptance evidence reviewed, without inventing additional prerequisites:

- Native compact/larger layout, game selection, date/focus/reset, source details,
  favorite add/remove, source navigation and the table/coverage dialogs are
  documented in the September 25 acceptance entries above.
- 83 Flutter tests, including integrated offline tables and cache/reconnection
  validation, pass. macOS debug build passes; analysis has 12 existing infos.
- 68 Node checks pass, including publication validation and rejection tests.
- Publisher 36121391338 succeeded. Fresh independent downloads this session
  matched all five local public feeds byte-for-byte: activity, Texas tables,
  state catalogs, retailer directories and state totals.
- Repository was clean at review. No new matching agency email arrived.

Distribution distinction: public JSON feeds are live; the accepted app build is
local macOS debug. This decision does not assert an App Store/mobile release.

Texas backlog, outside completed supported scope: broader historical/all-tier
retailer coverage and Pick 3/Daily 4 count/location records, subject to official
responses and verified definitions. The existing no-fee request remains open.
Do not reopen for routine polishing or another unchanged verification pass;
reopen only for an actual defect or meaningful verified new data with a named,
bounded task. Preserve privacy, original dates, exclusions and partial-coverage
labels. Kentucky work must not wait for these agency-only data expansions.

### September 25 Kentucky scope and per-game gap inventory

Scope is all supported physical lottery games and official result information,
not Scratch alone. Release deadline remains September 28, 6 PM ET. This is an
initial inventory; open source/interaction gaps below must be resolved or evidenced
before acceptance. Official sources inspected September 25:

- https://www.kylottery.com/apps/ — current game menu and results headings.
- https://www.kylottery.com/apps/winners/index.html — current winner stories and
  date-grouped retailer notices (latest notice heading September 23).
- https://www.kylottery.com/apps/draw_games/pastwinning.html — official results
  destination; web reader timed out this session, so details remain unverified.

| Game/product | Existing verified app evidence | Required acceptance work |
| --- | --- | --- |
| Scratch | Catalog, separate directory, 35 current selected notices plus retained history | Catalog/reset, location/details, date/provenance, offline and final visual checks |
| Powerball, including any Double Play coverage | Two retained Powerball records; current official winners page also links Powerball stories | Inspect current stories for selling-store evidence; verify national-game selection and latest mapped date; distinguish Double Play |
| Mega Millions | Official current game/results presence; no record in the current/retained KY imports inspected | Review official result/winner sources; import supported selling-store evidence or explicitly document missing evidence, then exercise empty-state/source flow |
| Millionaire for Life | One current selected retailer notice; schedule configured | Verify game matching, annual-prize semantics (not a lifetime/cash total), date and source |
| Cash Ball 225 | Separate initial activity record and configured schedule | Verify provenance/date and game selection against official results |
| Pick 3 / Pick 4 | Midday/evening schedules configured | Verify official schedule/results, winner-count/location availability and honest empty-state flows |
| Keno / Cash Pop | Recurring schedules configured; homepage says every four minutes | Verify schedule window and source/result access; no fabricated map records |
| Fast Play | Official game menu/winner story presence | Review store-versus-online evidence and supported information flow; do not invent a draw schedule |
| Powerball xno homepage label | Separate current homepage result heading/link observed | Establish official product identity and applicability before mapping it to a game or treating it as unsupported |
| Online instant games | Official stories exist, including online-only prizes | Exclude from physical-retailer heat points; no inferred store or residence coordinates |

Current imported counts are selected rows, never statewide ticket totals. The
current importer contains 36 rows (35 Scratch, one Millionaire for Life), retained
history has eight rows (six Scratch, two Powerball), plus a separate initial Cash
Ball record. Records need overlap/semantic review before aggregating any display.

Fixed one concrete acceptance defect: current and retained Kentucky notice rows
were labeled DRAW DATE in individual details. These imported ID families now show
NOTICE DATE; the initial Cash Ball record keeps its separate draw-date semantics.
The timeline already uses date-only Kentucky labels. This label fix still needs
native details inspection in the next acceptance pass; no checklist is falsely
marked complete by a build alone.

Startup repository clean, no matching new agency mail, publisher 36121391338
successful; activity/catalog/directory feeds independently matched local copies.
Next work: inspect current Powerball stories and the official result pages, then
exercise Kentucky native game/date/detail flows. Texas remains closed.

Kentucky generated-data checks and the macOS debug build passed after the notice-date label correction. Public data is unchanged; this native UI change does not require a feed deployment.

### September 25 Powerball story audit and official results access

Advanced the current Powerball selling-store evidence gap. Three official story
pages were inspected directly and compared with the current verified directory:

- https://www.kylottery.com/apps/winners/all/LaGrangeWomanWinsPowerballPrize
  describes July 15, 2026 and a $50,000 prize; its winners-card summary instead
  says $150,000. The body identifies Smart Shop in Pendleton as seller, but no
  verified directory entry matches that store name. Hold this candidate.
- https://www.kylottery.com/apps/winners/all/PitStopPayDay describes August 1,
  2026 and $150,000 including Power Play, while its summary card says $50,000.
  It identifies Pilot Travel Center in Franklin, where the directory has three
  plausible stores (#046, #661, #438). Do not choose one from proximity or names.
- https://www.kylottery.com/apps/winners/all/CampbellsvillePowerballWinners
  describes two separate $50,000 tickets. The Lexington Kroger address has a
  malformed ZIP and abbreviated directory candidate. T-MART Campbellsville has
  one directory candidate, but the article gives only a relative draw date for
  that ticket and omits the year from the other ticket's April 18 date. Neither
  is ready for a dated map point without additional official evidence.

All candidates remain unpublished. Local originals are staged in ignored
work/kentucky_story_review. Summary cards cannot safely supply prize amounts or
winner residence as selling location; no new retailer coordinates were invented.
This review resolves why these visible stories cannot simply be auto-imported;
it does not imply absence of other usable official records.

The official past-winning-numbers page now loads. Its payout disclaimer explicitly
limits displayed payouts to Kentucky, separate from national results. Replaced
the app's generic Kentucky homepage result link with this direct verified page
and a scope-aware subtitle. Dynamic result rows still require inspection before
any statewide count import. The page explicitly identifies Powerball Xs & Os,
resolving the earlier opaque 'xno' label; this is a distinct product requiring its
own applicability/results review, not ordinary Powerball activity.

Source: https://www.kylottery.com/apps/draw_games/pastwinning.html
Next named gaps: inspect dynamic per-game results/definitions (especially Mega
Millions and Xs & Os), then Kentucky native notice-date/game-selection acceptance.
No new agency mail. Scheduled publisher 36135693365 succeeded; fast-forwarded the
clean checkout to 2bac915 and verified live activity matches again. The initial
mismatch was the scheduled refresh, not deployment failure. Deadline unchanged.

### September 25 Kentucky statewide tier source unlocked

Inspected the actual public results page's request code, then used its read-only
WinningNumbers.xhtml requests: infoRequest 11 for history and 17 plus drawNumber
for details. Game 26 is Mega Millions; game 24 is POWERBALLXO (distinct Xs & Os).
The current response contains 51 Mega Millions draws and two Xs & Os draws; this
is only the returned window, not a complete archive. No retailer fields supplied.

Latest reviewed Mega Millions draw 2380 (September 22) reconciles 2,465 reported
Kentucky winners and $49,433 payout across separate tier/multiplier rows. Xs & Os
draw 2 (September 20) reconciles 831 winners and $14,738. Draw timestamps encode
the Eastern calendar date; they are not evidence of exact event time. Source
publication dates remain unavailable. Official page disclaimer scopes payouts
to Kentucky: https://www.kylottery.com/apps/draw_games/pastwinning.html

Added a bounded parser and real-response regression fixtures for these two
layouts. It preserves base prize/multiplier fields and rejects wrong games,
unreviewed groups, inconsistent totals, duplicate tiers and jackpot-winner rows
requiring separate payout treatment. All 71 Node tests pass. No statewide totals
have been mapped onto stores or added to the public ranking/feed.

Next concrete acceptance work: connect these validated statewide results to a
separate Kentucky table view, inspect other game layouts, and exercise native
selection/notice-date flows. This resolves the earlier inability to inspect the
dynamic response; Mega Millions statewide data is available even though retailer
locations are absent. Kentucky deadline unchanged.

### September 25 Kentucky statewide table milestone

Implemented the separate Kentucky Drawings → Statewide prize tables flow for
verified Mega Millions and Powerball Xs & Os, with source dates, tier/multiplier
separation, coverage limitations, cache and bundled offline fallback. Native
800×632 interaction acceptance verifies both game selections, date changes,
scroll-position reset, horizontal/vertical access to reconciled totals and visible
limitations. Six focused Flutter checks, 74 Node checks and macOS debug build pass;
analysis has only the 12 existing infos. See Kentucky source screen for details.
This advances Kentucky's draw-game checklist, but does not close it: ordinary
Powerball and remaining state-game reconciliation and broader integrated flows
are still pending. Deadlines unchanged.

### September 25 Kentucky remaining game scope reconciled

The source-screen matrix now explicitly covers Powerball/Power Play, Double Play,
Mega Millions, Xs & Os, Millionaire For Life, both Pick 3/4 sessions, Cash Ball/EZ,
Keno, Cash Pop, Fast Play/online instant limitations, and Scratch. Official dynamic
responses establish which have tiers and which only aggregate totals. Added and
tested a Powerball/Double Play parser with subset-safe counts. Next implementation
step is expanding the separate table feed with reviewed layouts; do not map these
unlocated totals or misrepresent the current two-game sheet as final acceptance.
The scope inventory is recorded before September 26 06:58 ET. Release deadline
remains September 28 18:00 ET; broader integrated acceptance is still required.

### September 25 Powerball table gap closed

Kentucky statewide tables now include ordinary Powerball with a separate Power
Play subset column and a distinct Double Play report. Native interaction checks
verify both reconciled totals, scrolling, game-switch reset and source dates.
Six focused Flutter tests, 76 Node tests and macOS build pass; 12 existing analysis
infos remain. Publisher 36164788118 succeeded and live feed bytes match d1970e6.
Next: implement reviewed Kentucky state-game layouts and finish integrated
activity/catalog/favorites checks. Kentucky stays active; deadline unchanged.

### September 25 state-game parsing milestone

Kentucky's six reviewed state-game reports now have tested parsers and real-source
fixtures, including both Pick 3/4 sessions. Correctly scoped EZ totals and annuity
limitations are preserved. All 79 Node checks pass. Public table integration and
native acceptance for these six reports remain pending; do not mark them ready
or advance to Virginia. Kentucky's September 28 release deadline is unchanged.

### September 25 six state reports ready for testing

Kentucky statewide tables now include Millionaire For Life, Cash Ball 225, and
both Pick 3/4 sessions, bringing the reviewed table count to ten. Per-session dates,
separate EZ totals and explicit top-prize limitations are integrated. Seven focused
Flutter checks, 79 Node checks, native 800×632 inspection and macOS debug build
pass; 12 existing analysis infos remain. Publisher 36177493029 and independent
live-byte comparison verify deployment. Next: aggregate-only Keno/Cash Pop scope
and remaining integrated activity/catalog/favorites acceptance. Kentucky remains
active and its September 28 18:00 ET release deadline is unchanged.

### September 25 Keno/Cash Pop aggregate scope verified

Added tested parsing and source fixtures for individual-draw aggregate counts,
explicitly without tier reconciliation, exact times or retailer locations. Latest
selection uses verified draw-ID ordering, resolving the repeated-date ambiguity.
All 82 Node tests pass. Aggregate-only UI/feed integration is still pending; the
current public table scope stays at ten reports. Kentucky remains active.

### September 25 aggregate snapshot collection

Kentucky Keno/Cash Pop collection now checks history/detail consistency and
regression, preserves unchanged snapshot dates, and rejects partial collection.
Fifteen Kentucky Node checks pass. Public scope stays at ten tier reports;
aggregate presentation and integrated acceptance remain open. Maryland sent a
retailer PDF and a $438.75 ticket-extract estimate; replied with no-fee hold and
request for existing free alternatives. Directory content audit is separate.

### September 25 aggregate-only games ready for testing

Keno and Cash Pop are now separate individual-draw summaries in Kentucky's
statewide report selector, with draw IDs, dates, snapshot freshness and explicit
no-tier/no-retailer limitations. Nine focused Flutter tests, 83 Node tests, macOS
build and native 800×632 checks pass; analysis retains 12 existing infos.
Publisher 36195042965 succeeded and the live feed independently byte-matched.
This closes the aggregate presentation gap. Continue remaining integrated
Kentucky catalog/activity/filter/favorites/offline acceptance; do not add new
scope or advance to Virginia before the full release decision. Deadline unchanged.

### September 25 Kentucky catalog, retailer and Favorites acceptance

At 800×632, opened the Scratch catalog and verified its remaining-prizes versus
store-stock explanation. Selected $1,000,000 Luck, reopened to confirm the selected
row, reset to All Kentucky Scratch-Off activity and reopened to verify the reset.
The scoped no-matching-activity notice remains accurate for the current date.

Opened the 3,380-location official retailer picker and selected ADAIRVILLE MARKET,
135 S Main St, Adairville, KY 42202, Logan County. Its detail explicitly states that
a directory listing does not create a heat-map win. Saved this previously unsaved
retailer, verified its exact address in Favorites, opened the favorite to its map
point, and reopened matching retailer details. Removed the test favorite and
verified the save action returned, preserving pre-existing favorites.

These interactions close the catalog and retailer checklist entries. Other
filters, notice-date details, broader source access, offline/reconnection and
larger-layout acceptance remain open; Kentucky is not yet fully accepted.
No code/data changes or new tests were needed for this interaction-only pass.
Startup found no new agency replies; publisher 36195042965 remains successful,
and independent live Kentucky report retrieval still matches checked-in bytes.
Deadline remains September 28 at 18:00 ET. Next pass should use a known covered
notice date to verify activity details and date/filter behavior.

### September 25 power-outage recovery and Kentucky offline acceptance

User reported a power outage and requested continuation. Checkout was clean at
1bcf553; all prior acceptance work was saved and pushed. The deployed Kentucky
report still byte-matched the checked-in feed. A scheduled publisher was running,
not established as failed. No new agency reply required action. No calendar
extension is currently needed: Kentucky remains due September 28, 18:00 ET and
Virginia October 1, 18:00 ET; outage duration was not inferred.

Added Kentucky loader/repository regression coverage with a test-only downloaded
notice. Verified HTTP-failure reload retains exact cached records, cached status,
feed update date and original source date; unchanged reconnection preserves all
records/dates and clears cached status. Verified bundled Kentucky catalog and
retailer directory load offline with their expected counts/source attribution
without creating activity. Existing aggregate/tier offline loader and interaction
checks also pass: 14 focused Flutter tests, no analysis issues in the changed test.

Native app control is unavailable in this resumed tool session. No visual check
was claimed or previous evidence repeated as new. Keep integrated offline UI,
covered notice-date/details, remaining filters/source surfaces and larger-layout
acceptance open. This is automated recovery evidence, not Kentucky release closure.

### September 25 Kentucky ranking-scope correction

Source/coverage acceptance review found the shared ranking card still labeled
Kentucky selected notices as generic winning-ticket county rankings, without a
local partial-coverage explanation. Kentucky now uses published-record headings
and a visible notice that only selected official records with verified retailer
matches are ranked, including retained history. It states that current filters
apply, coverage excludes other wins/tiers, and statewide draw summaries do not
create retailer wins. No counts, coordinates or underlying records changed.

Three ranking-service tests and the macOS debug build pass; changed-file analysis
has no issues. Native visual acceptance remains open because app-control tools
are unavailable in this session. This corrects a named coverage gap without
claiming the remaining integrated checklist is complete. Deadline unchanged.
Startup found no new agency replies. Publisher 36205337159 succeeded; live Kentucky
reports match scheduled commit 9c964b1, explaining the initial local comparison
difference. Preserve that scheduled update when integrating this UI correction.
