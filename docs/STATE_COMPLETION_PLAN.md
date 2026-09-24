# State completion operating plan

Approved by the user September 24, 2026. This plan controls development priority;
state source-screen documents retain the detailed evidence and request history.

## Active work: Texas

Finish Texas's verified available-data experience, then Kentucky, then Virginia.
Do not expand to a new state merely because another source is available. Agency
requests continue in parallel without blocking a scoped state release.

Two separate outcomes must be reported: **accepted for available coverage** and
**complete statewide data**. The former requires the checklist below; the latter
requires affirmative source evidence. No state is currently signed off by this
plan. An unavailable feature needs an honest explanation, not fabricated data.

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

## Texas acceptance checklist

Scope: current official Scratch catalog, mapped verified retailer directory,
selected Scratch top-prize claim activity, and supported draw-game information.
This scope does not include complete all-tier statewide winning-ticket totals.

- [ ] Catalog browsing and available filters work; unknown remaining counts stay
      unknown and remaining prizes are not described as store stock.
- [ ] Map loads verified points and retailer details; a directory location alone
      never becomes a winning-ticket record.
- [ ] State, county, game, prize and date filters behave consistently wherever
      offered, including clearing filters and returning to the default view.
- [ ] Timeline date semantics and source coverage are visible and accurate.
- [ ] No-results views explain missing or filtered data without implying zero
      statewide wins; denied/unavailable features have scoped explanations.
- [ ] Sources, periods, cadence and partial-coverage limitations are accessible.
- [ ] Bundled/cached data loads offline and reconnecting does not inflate dates.
- [ ] Integrated visual/interaction checks pass at representative window sizes.
- [ ] Relevant automated checks pass; live feeds are independently verified.
- [ ] Evidence is recorded and Texas is explicitly announced ready for testing.

Existing automated evidence: Texas generated catalog/directory/activity, draw
menu and offline activity checks exist in `test/services/texas_generated_data_test.dart`.
Those checks do not close the unverified interaction items above. First next
task: run the Texas flow in the app and record/fix the first concrete acceptance
gap. Kentucky and Virginia follow the same checklist adapted to their sources.

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
