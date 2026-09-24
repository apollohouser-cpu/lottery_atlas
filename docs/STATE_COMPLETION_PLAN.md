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
