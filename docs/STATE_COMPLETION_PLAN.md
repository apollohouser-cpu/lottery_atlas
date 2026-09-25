# State completion operating plan

Approved by the user September 24, 2026. This plan controls development priority;
state source-screen documents retain the detailed evidence and request history.

## Active work: Kentucky

Texas is accepted for its available-data scope as of September 25, 2026 UTC.
Finish Kentucky next, then Virginia.
Do not expand to a new state merely because another source is available. Agency
requests continue in parallel without blocking a scoped state release.

Two separate outcomes must be reported: **accepted for available coverage** and
**complete statewide data**. The former requires the checklist below; the latter
requires affirmative source evidence. Texas is signed off only for its
explicitly limited available-data experience. An unavailable feature needs an honest explanation, not fabricated data.

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

- [ ] Catalog browsing, selection, remaining-count semantics and reset.
- [ ] Verified map points, retailer details and separate-directory explanation.
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
