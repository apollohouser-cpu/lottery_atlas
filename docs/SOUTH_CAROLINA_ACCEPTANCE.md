# South Carolina supported-coverage acceptance

Activated September 30, 2026 at 17:03 ET. Release decision due October 3 at
17:03 ET (72 hours). Scope reconciled September 30, before October 1 at 17:03 ET.
Not yet ready for integrated native testing or accepted. Agency records are a
separate outcome; no fees or complete-records prerequisite.

## Per-game scope and gaps

Official pages inspected September 30, 2026. These statewide draw reports are
separate from retailer-linked claimed prizes. Never distribute their totals to
stores or counties, or add them to claims as distinct tickets.

| Game | Verified public scope | Implementation gap / limit |
| --- | --- | --- |
| [Powerball](https://www.sceducationlottery.com/Games/Powerball) | SC tier winners, separate base, Power Play and Double Play columns | Existing claim filter; add statewide report with variants kept separate. September 28 total 10,746 includes all three columns. |
| [Mega Millions](https://www.sceducationlottery.com/Games/MegaMillions) | SC tier counts, prize ranges; September 29 total 10,193 | Existing claim filter; add statewide report. Prize ranges do not support an exact total payout. |
| [Powerball Xs & Os](https://www.sceducationlottery.com/Games/PowerballXO) | SC five-tier report; September 27 total 1,773 | Missing game/filter. Existing import labels two `Xs and Os` groups as Scratch: correct classification and regenerate before release. Preserve source-specific tier amounts rather than assuming current advertised prizes apply historically. |
| [Palmetto Cash 5](https://www.sceducationlottery.com/Games/PalmettoCash5) | Four-tier counts; September 29 total 6,022 | Existing claim filter; add statewide report. Page's multiplier description and displayed tier amounts differ: retain reported values, do not infer multiplied payout. |
| [Pick 3 Plus FIREBALL](https://www.sceducationlottery.com/Games/Pick3) | Midday/evening play-type counts, base and FIREBALL columns | Existing Pick 3 claim filter; preserve session and variant in statewide report. Counts are source-reported winners, not deduplicated tickets. |
| [Pick 4 Plus FIREBALL](https://www.sceducationlottery.com/Games/Pick4) | Midday/evening play-type counts, base and FIREBALL columns | Existing Pick 4 claim filter; same separation and limitations as Pick 3. |
| [CASH POP](https://www.sceducationlottery.com/Games/CashPOP) | Session winner totals and payouts; September 30 midday 2,242 / $102,490 | Existing claim filter; add statewide session report. Published odds tables are not actual tier winner counts. |
| [Scratch daily claims](https://www.sceducationlottery.com/Games/DailyInstantWinners) | Daily statewide claimed-prize tiers, distinct from the rolling $500-plus retailer report | Existing Scratch screen uses this source, not remaining inventory. Restore reliable refresh; preserve source day and grouped duplicate-title semantics. |
| [Scratch remaining inventory](https://www.sceducationlottery.com/Games/PrizesRemaining) | Estimated remaining prizes | Separate official source, not the existing daily-claims feed; do not label daily claims as remaining prizes. |

The app's current “all six” draw-game wording is stale. Public availability is
not the same as imported coverage: no SC statewide draw-report importer was found
in this audit. Report integration is a named supported-draw gap, not a dependency
on the pending agency response.

## Existing claims snapshot and semantics

`data/south_carolina_current_winner_activity.generated.json`, source date
September 30: 10,019 mapped groups / 10,330 reported claims, July 6–September 29.
Source limits to prizes at least $500 and a rolling three-month report;
1,072 claims excluded for lack of an exact Census address geocode.
These are partial counts, never complete statewide totals.

Current group counts: Powerball 59; Mega Millions 136; Palmetto Cash 5 957;
Pick 4 2,684; Pick 3 465; CASH POP 436; currently classified Scratch 5,282,
including the two misclassified Xs and Os groups. Counts describe this snapshot.
The importer groups identical date/prize/game/location fields and retains the
number of report rows; no independent ticket identity is established.

The schema's `drawDate` stores the source **claim date**, with UTC noon used for
date storage. Audit map/timeline/details to ensure they show claim-day precision,
not a draw time or an hourly event. Missing mapped records can also reflect
geocode exclusions; the current coverage-screen claim that absence necessarily
means no qualifying source record must be corrected.

SC-specific retailer feed has no default remote URL and a starter fallback;
verify its route and disclosures against the shared live activity feed. Do not
present starter records as a complete current retailer directory.

## Release checklist

- [x] National/state draw games and Scratch inventoried with official sources.
- [x] Public available data separated from complete agency-records outcome.
- [x] Correct Xs and Os classification/filter, coverage wording and date semantics.
- [x] Integrate available statewide draw reports with source, date/session, tiers,
      cadence and limitations; validate totals and preserve prior data on failure.
- [x] Verify Scratch catalog/fallback and retailer route limitations.
- [ ] Test state/county/game/prize/date filtering, reset, empty states and sources.
- [ ] Observe native layouts/interactions at 800×632 and 1280×900 logical sizes,
      including national and state draws, Scratch and directory/detail routes.
- [x] Verify offline/cache recovery and reconnection without fabricated freshness.
- [x] Appropriate automated checks, build and independent live-file verification.
- [ ] Record supported-coverage release decision by the deadline.

September 30 opening check: clean repository, latest publisher 36759391265
successful, no new agency reply beyond the already-handled Texas clarification.
No repeated Kentucky/Texas acceptance tests were run. Pending SC narrowed request
and historical evidence remain in SOUTH_CAROLINA_SOURCE_SCREEN.md.


## September 30 classification and date corrections

Implemented Xs and Os as a distinct draw filter/card using the report's exact
`Xs and Os` title. Corrected importer classification and only the two affected
snapshot game codes; claim counts, coordinates, dates and source freshness are
unchanged. Coverage now lists seven draw games and explains geocode exclusions
instead of asserting that absent mapped data means absent source claims.

Current `sc-winners-` detail records show CLAIM DATE and explain missing draw/time
information. South Carolina's timeline uses the existing whole-day source mode,
preventing synthetic noon timestamps from becoming hourly activity.
Five focused classification/calendar tests pass; changed classification/screens
analyze cleanly. Native verification and independently published data verification
remain pending. Statewide draw-report integration remains the next implementation
gap. No release decision or deadline change.


## September 30 publication and fallback audit (20:00 ET session)

Publisher 36789068922 succeeded for 67b9213. Independently fetched the public
GitHub Pages activity.json: all 10,019 local SC activity objects match by ID and
full object value, including both Xs and Os entries as state-draw. This closes
that publication check; native interaction verification is still pending.

Correction to the initial scope description: the SC-specific Scratch screen
loads **DailyInstantWinners**, not PrizesRemaining. Its built-in snapshot is dated
August 17, 2026; the screen labels built-in/saved/published status and snapshot
date, and explicitly describes daily claimed tiers. The configured external
south-carolina-scratch-offs.json endpoint returned HTTP 403 in this session.
There is no matching daily-Scratch publisher in the repository. This is a named
refresh gap: wire the existing daily-claims schema into the maintained publishing
pipeline, preserving the actual source day and prior valid data on failure.
Do not call the old snapshot current or infer inventory from claimed counts.
The official daily source is available; the web-reader copy inspected was dated
September 27 (updated September 28), so do not treat its crawl as today's data.

Retailer fallback audit: no default remote retailer feed is configured. Built-in
records carry cityLevelPlacement=true and are explicitly a starter subset; the
list says it is not every retailer. The repository has no source update date,
and its phrase “recently reported” is misleading for retained starter records.
Map markers use these city coordinates, although details disclose city-level
placement. Before acceptance, prevent these from being represented as precise
store positions or used as precise nearby distances; use verified shared-feed
locations or an explicit non-map address list. No invented replacement locations.

No new agency response was found. Statewide draw-report integration remains
open, with the original October 3 at 17:03 ET release decision unchanged.


## September 30 retailer-position correction (21:00 ET session)

The retained retailer subset is mixed: some entries have cityLevelPlacement=true,
while its later address-level entries are marked false. This clarifies the prior
fallback audit; not every starter row is approximate. Added a shared mappable
subset that excludes city-level positions from map pins and nearby-distance
results. The address list remains intact, and map-action counts use only eligible
positions. Saved approximate-retailer navigation opens details without a store
zoom. Native verification and provenance review of retained address-level entries
remain pending; this change does not certify every existing coordinate.

Two regressions cover exclusion of approximate starter records and mixed-feed
retention of address rows. Publisher 36797307567 was successful at the opening
check; no new agency reply. Scratch refresh and statewide draw integration remain
open. No change to the October 3 release-decision deadline.

## September 30 daily Scratch refresh implementation (22:00 ET session)

Added a maintained official DailyInstantWinners importer and a baseline for
September 29 claims, published by SCEL September 30 at 10:00:03 EDT: 31 grouped
titles. Payout arithmetic, table boundaries, integer values, source dates and
regressing claim days are validated. Duplicate source titles retain summed tier
counts and the number of grouped source entries. Output is written only after
validation. This snapshot is statewide daily claims, not remaining inventory,
retailer totals or a current sales catalog.

The existing South Carolina transaction now includes this output, preserving its
previous file alongside the rolling claims file if either importer fails. The
publisher stages south_carolina_daily_scratch.json; the app uses that GitHub Pages
URL instead of the HTTP403 endpoint and exposes claim day separately from source
publication date. Cached failures retain both dates. Five parser regressions and
a Flutter network-failure/cache regression pass. Analysis reports two existing
string-interpolation infos in the Scratch screen. Live publication and native
checks remain pending; statewide draw reports remain the next implementation gap.

## September 30 daily feed verification and draw parser (23:00 ET session)

Publisher 36804028771 succeeded for 1477dc6. Independently fetched the public
south_carolina_daily_scratch.json and confirmed a byte-for-byte match to the
committed snapshot. Native Scratch screen verification remains pending.

Staged a validated Mega Millions draw-report importer and five official recent
draw tables in data/south_carolina_draw_reports.generated.json. September 29
reconciles to 10,193 statewide winners. Each report requires nine distinct tiers,
exact columns, integer nonnegative counts, a matching SC scope date and a
reconciled total; duplicate/unordered dates and date regression are rejected.
Prize ranges are retained verbatim and reportedPayout/sourcePublicationDate are
null, rather than inventing totals or treating retrieval as source publication.
Six regressions pass, including count/date mismatch and duplicate rejection.

This is staged data, not an app report release: remaining national/state games,
the report view, transactional refresh and public report publication still need
integration. The existing retailer feed remains separate and unchanged. No new
agency response, state acceptance or deadline change.

## October 1 additional draw parsers (00:00 ET session)

Extended staged reports to Powerball Xs & Os and Palmetto Cash 5: 12 reports
across three games. Latest counts reconcile to 1,773 for Xs & Os September 27
and 6,911 for Palmetto September 30. Exact tier names, columns, totals, date order
and per-game non-regression are checked. Xs & Os requires a matching SC scope
date; its historical tier values are preserved. Palmetto's Winners and Total
columns must agree and are never added together; payout remains unknown.
Eight parser regressions pass. An initial strict span matcher rejected the Xs &
Os page's class attribute without overwriting prior data; it now accepts span
attributes while retaining date/scope validation.

Regular Powerball variants, Pick 3/4 FIREBALL sessions and CASH POP remain to be
implemented, followed by app/report publication integration and native checks.
Publisher 36808635720 succeeded at the opening check, with no new agency reply.
The staged reports are not yet exposed as a completed app feature. Deadline
remains October 3 at 17:03 ET.

## October 1 CASH POP session importer (01:00 ET session)

Added six official CASH POP session reports; the staged file now has 18 reports
across four games. Latest September 30 evening reports 2,705 winners / $105,640;
midday reports 2,242 / $102,490. These are reported session totals, not tier
counts inferred from odds. Empty tiers are deliberate and explicitly explained.
The parser requires date/session, exact totals labels, valid nonnegative counts
and monetary format, consistent zero totals, unique sessions and newest-first
ordering. Import regression checks now preserve the latest date for each game
and session separately. Twelve parser tests pass, including missing/duplicate
session and malformed payout rejection.

Publisher 36813266540 succeeded at opening; no new agency response. Powerball
variants, Pick 3/4 FIREBALL, app integration and native verification remain open.
Staged reports are not public app coverage yet. No deadline change.

## October 1 Powerball variant parser (02:00 ET session)

Added five official Powerball reports, bringing staged coverage to 23 reports
across five games. September 30 reports base 5,627, Power Play 4,054 and Double
Play 2,796, matching the source combined 12,477. These columns remain separate;
the combined total is explicitly not a base-only Powerball count. Only the
jackpot Power Play `--` is treated as inapplicable for reconciliation; missing
counts elsewhere are rejected. Every tier row, column total, tier label, header,
multiplier and scope date is validated. Payout remains null.

Fifteen parser tests pass, including row mismatch and misplaced-dash rejection.
Publisher 36817870135 succeeded at opening; no new agency reply. Pick 3/4 FIREBALL
sessions, app/report publication integration and native checks remain pending.
Deadline is unchanged; this staged work is not release acceptance.

## October 1 Pick 3/4 FIREBALL parsers (03:00 ET session)

Added six sessions each for Pick 3 and Pick 4, bringing staged reports to 35
across all seven supported draw games. Base/FIREBALL rows and totals reconcile
independently, with exact play-type/column checks and date/session identity.
The source explicitly bases these counts on 50-cent wagers; reports preserve
that limitation and do not call them distinct tickets or infer payout from odds.
Missing wager-basis text, duplicate sessions and count mismatches are rejected.
Nineteen draw-parser tests pass.

Publisher 36825827761 was successful at opening, with no new agency reply.
All game parsers now exist, but report UI, cached/bundled loading, transactional
refresh/public publication and native acceptance still remain. This is not yet
release or testing-readiness acceptance. October 3 at 17:03 ET remains the deadline.

## October 1 report UI and publication integration (04:00 ET session)

Added South Carolina statewide draw reports from the state screen, with game,
draw date/session, official source link, source-specific columns/limitations and
retrieval metadata. Report data is separate from retailer claims. CASH POP shows
session totals, Pick reports retain the 50-cent wager limitation, and Powerball
variant columns stay separate. The loader requires SC provenance and all seven
games, uses valid cache on network failure, and has a bundled baseline.

The SC refresh transaction now includes draw reports alongside daily Scratch
and rolling claims. The publisher stages south_carolina_draw_reports.json and
preserves previous state outputs on importer failure. Loader and compact/larger
widget tests pass; changed-file analysis is clean. Nineteen parser tests remain
passing. Live publication and actual native interactions still require verification;
widget layout tests do not constitute native acceptance. State remains unaccepted.
Publisher 36828045793 succeeded at opening; no new agency reply or deadline change.

## October 1 live publication and first native reports (05:00 ET session)

Publisher 36833941360 succeeded for db8e949. Independently downloaded public
south_carolina_draw_reports.json and confirmed byte equality with the committed
35-report file. No new agency response was found in the opening mail check.

Relaunched the ordinary debug app and opened SC LOTTERY → Statewide draw reports
at the retained 800×632 logical window (1600×1264 screenshot). Native Mega Millions
September 29 exposed all nine tiers and total 10,193 in accessibility, with the
prize-range and no-retailer-allocation disclaimer visible. Opened the actual
report dropdown and selected CASH POP September 30 Evening: the native table
showed 2,705 winners and $105,640.00, with session-only/no-tier-breakdown wording.
The official-source button opened sceducationlottery.com/Games/CashPOP in Chrome;
its displayed official evening total matched both values. Returning to the app
retained that report selection. No crash was observed during this bounded flow.

This verifies first compact report selection and source navigation, not all-game
native acceptance. Remaining native report choices, table scrolling, larger-size
checks, Scratch/map/filter/offline flows and retained retailer provenance remain
on the existing checklist. SC is not accepted; October 3 at 17:03 ET is unchanged.

## October 1 compact Powerball and Pick 3 native checks (06:00 ET session)

Opening repository was clean; publisher 36833941360 remains successful and mail
contained no new agency response. Continued the existing 800×632 native window.
Selected September 30 Powerball from the actual dropdown. Its separate base,
Power Play (x4), and Double Play columns exposed 5,627 / 4,054 / 2,796, total
12,477. Scrolled vertically to the final row and dragged the horizontal scrollbar
right: screenshots visibly exposed the variant totals and combined total. The
combined-count, unknown-payout and no-retailer-allocation disclaimer stayed visible.

Selected Pick 3 Plus FIREBALL September 30 Evening from the native dropdown.
Accessibility exposed nine play types and totals 2,329 base / 152 FIREBALL / 2,481,
with the explicit 50-cent-wager basis, no distinct-ticket claim, and no inferred
payout. This is selection/semantics evidence; remaining game selections and larger
window checks are not implied. No crash was observed. No source changes or repeat
build/tests were needed. Integrated state acceptance remains pending, deadline
October 3 at 17:03 ET unchanged.

## October 1 remaining compact draw selections (07:00 ET session)

Repository clean, publisher 36833941360 successful, no new agency reply at opening.
Continued the retained 800×632 native report sheet. Actual dropdown selection of
Pick 4 September 30 Evening exposed all 13 play types and base/FIREBALL/combined
counts 102 / 108 / 210, with the 50-cent-wager limitation. Scrolling the dropdown
up reached Powerball Xs & Os September 27; selection exposed its five tiers and
1,773 total, with historical amounts preserved and payout explicitly unknown.
Selected Palmetto Cash 5 September 30: four tiers and 6,911 total, with duplicate
winner/total columns explicitly not summed and multiplier/payout limitations.
No crash was observed. Together with prior sessions, one native report selection
for every supported draw game has now been observed in the compact window.
This does not imply every date/session or larger-window/offline acceptance.

Next unchecked work remains larger-window reports, Scratch/filter/map and offline
flows, and retained retailer provenance. No source edits or unchanged test reruns.
South Carolina remains unaccepted; October 3 at 17:03 ET deadline unchanged.

## October 1 larger-window report and Scratch freshness (08:00 ET session)

Opening repository clean, publisher 36833941360 successful, no new agency reply.
Resized the running native app to 1280×900 logical (2560×1800 screenshot).
Palmetto report retained its selection and displayed all four tiers, total 6,911,
limitations, retrieval footer and source button without a crash or overflow.
Closed the sheet and opened Scratch-Off prize tiers. Native header correctly
showed publication September 30 and claims September 29, 31 grouped games and
121,051 daily claims, separately from 5,281 matching published map records.

Found an actual stale-date defect: each game card still called those claims
"yesterday" on October 1. Changed the card text to "for this daily snapshot",
which uses the dated header's scope and remains true for retained/cache data.
Changed-file analysis has only the two existing interpolation infos. Native
verification of the rebuilt wording remains pending; this is not SC acceptance.
Remaining Scratch/filter/map/offline and retailer-provenance work is unchanged.
MacOS debug build passed for the wording correction. October 3 at 17:03 ET remains
the release-decision deadline; no new acceptance prerequisites were added.

## October 1 rebuilt Scratch and prize-filter handoff (09:00 ET session)

Opening repository clean; publisher 36863104549 was in progress during the single
check, so its publication is not independently verified here. No new agency reply.
Relaunched the ordinary debug build. Scratch finder initially showed its labeled
August 17 built-in baseline, then completed loading the published September 30 /
September 29 claim snapshot. Corrected cards now say "for this daily snapshot".

Selected 200X: 3,387 daily claims and 272 separate rolling map records. Raised
minimum prize to $500: 41 daily claims (38 at $500, two at $1,000, one at $5,000),
272 rolling map records, and zero-valued higher tiers remained explicitly scoped
to the day. Map handoff returned with the 200X / $500–$2.5M filter, retained October
1 timeline and correctly scoped zero matches for that date. No crash observed.

A further freshness discrepancy is now observed: the home Scratch shortcut menu
still lists 200X as 3,080 claims, matching the old built-in baseline, while the
finder shows the published 3,387. Audit that menu's source/date labeling next;
do not present its retained counts as current. Remaining offline and retailer
provenance checks continue. SC not accepted; deadline unchanged.

## October 1 shortcut freshness correction (10:00 ET session)

Confirmed home Scratch shortcuts read the static August 17 catalog. Removed
undated claim counts from those shortcut rows and explicitly labeled their
retained catalog date, directing users to Prize Finder for dated daily counts.
Catalog top-prize values are labeled as catalog values. This resolves the
observed 200X 3,080 versus 3,387 presentation mismatch without pretending the
retained shortcut inventory is a current daily report. Changed-file analysis is
clean; native rebuilt-menu verification remains pending.

Publisher 36863104549 succeeded; independent downloads of activity.json,
south_carolina_draw_reports.json and south_carolina_daily_scratch.json all match
committed public bytes after b6d3c4a. SC transaction updated successfully.
Texas transaction also reports updated; its per-feed recovery verification is
still pending before closing the October 1 15:00 ET checkpoint. NH remains
retained after failure. No new agency reply. SC release deadline unchanged.
MacOS debug build passed. No unchanged test suites were repeated for this text fix.

## October 1 shortcut fix native verification (11:00 ET session)

Relaunched the d2834eb debug build and expanded native Scratch shortcuts. The
August 17 retained-catalog notice and Prize Finder direction are exposed; 200X
now shows only "Catalog top prize $2M", with no stale 3,080 claim count. Other
visible shortcuts likewise omit claims. No crash observed. This closes native
confirmation of the menu text fix; offline/provenance and remaining integrated
map checks remain. SC is not accepted; deadline unchanged.

Publisher 36863104549 succeeded. Independent downloads of Texas draw tiers,
shared Scratch catalogs, shared retailer directories, activity and refresh status
all byte-match committed public files after b6d3c4a. Texas transaction reports
updated for all five state outputs. October 1 15:00 ET importer-recovery checkpoint
is closed; this does not reopen Texas acceptance. New Ohio agency response needs
a personal requester confirmation, recorded in OHIO_SOURCE_SCREEN.md.

## October 1 retained retailer provenance correction (12:00 ET session)

Audited the supposedly address-level starter entries. The repository explicitly
identifies _countyHeatCoverageRetailers as county heat-point context, and multiple
unrelated York County addresses share 34.99242, -81.1794. The helper nevertheless
set cityLevelPlacement=false. These are not evidenced store geocodes.

Corrected that helper to mark coverage coordinates approximate. All built-in
retailer addresses remain listed, but none now qualify for store pins or nearby
distances. Existing verified address-level published-feed behavior remains intact.
Strengthened the position regression to assert county-coverage entries are all
approximate and no starter entry is mappable. Both position tests pass; changed
files analyze cleanly. Native verification of the rebuilt address-list/map
behavior remains pending. This closes the provenance audit through an explicit
unavailable-precise-location outcome, without inventing geocodes or requiring
new agency records. SC is not accepted; deadline unchanged.

Opening publisher 36863104549 remains successful; no new agency response beyond
the already-notified Ohio requester action. No accepted state was reopened.
MacOS debug build passed for the coordinate-classification correction.

## October 1 native retained-retailer verification (13:00 ET session)

Relaunched the corrected 0837c47 ordinary debug build and opened SC LOTTERY →
Browse retailer claim locations. Native directory retained 51 address records,
explicit retained-subset/not-current-or-complete wording, and a zero-verified-
positions map control. The displayed source was built-in with no configured
public retailer feed. Opened Find nearby and searched Orangeburg: the result
explicitly reported no address-level positions available, with city-level starter
records excluded from distance results. No invented store distances appeared and
no crash was observed. This closes the built-in approximate-position native check;
no claims of precise retailer availability are made.

Publisher 36863104549 remains successful. Washington delivered an early retailer
workbook; receipt is recorded separately, contents not yet audited or published.
Remaining SC offline and integrated map checks continue without a deadline change.

## October 1 native request-failure probe (14:00 ET session)

Built the preserved private work/native_offline_check/main.dart harness, which
routes Dart HttpClient requests through unavailable localhost proxy port 9, and
relaunched the native app. SC draw reports retained Mega Millions September 29,
10,193 winners and the original October 1 07:01 UTC retrieval metadata. Scratch
finder explicitly showed SAVED SOUTH CAROLINA SNAPSHOT with publication September
30, claims September 29, 31 games and 121,051 daily claims, separate from 5,336
retained rolling map records. No fabricated fresh source date or crash observed.
This is a Dart request-failure/cache check, not a claim that OS networking was off.

Reconciled already-completed implementation and automated/live checks in the
summary checklist. Reconnection and remaining integrated map flows are still
required before acceptance. Opening publisher unchanged/successful; no new agency
reply beyond previously recorded Ohio/Washington messages. Deadline unchanged.
Ordinary lib/main.dart debug build passed and was relaunched after ending the
probe. Native reconnection data verification remains for the next unchecked flow.

## October 1 native reconnection verification (15:00 ET session)

With the ordinary lib/main.dart build restored, opened statewide reports and
observed Mega Millions September 29 total 10,193 with updated retrieval metadata
2026-10-01T18:50:38.557982+00:00, matching the independently fetched public report.
Opened Scratch finder and observed its asynchronous transition from explicitly
labeled built-in data to PUBLISHED SOUTH CAROLINA SNAPSHOT: October 1 publication,
September 30 claims, 30 games and 132,557 daily claims. These exactly match the
new public daily JSON. The 5,336 rolling map records remain separately labeled.
No crash observed. This completes the prior request-failure/reconnection flow;
the failure probe was not repeated.

Publisher 36908045746 succeeded, and both SC report and daily Scratch public JSON
byte-match 0d74deb, integrated by fast-forward. No new agency response beyond the
already-recorded Ohio/Washington messages. Scratch fallback/retailer limitations
and offline/reconnect summary boxes now reflect accumulated native evidence.
Remaining integrated map/filter/detail checks and release decision are pending;
SC is not accepted, and the October 3 17:03 ET deadline is unchanged.

## October 1 native date/county/claim-source flow (16:00 ET session)

At compact 800×632 logical size, used Show all SC activity on map and observed
October 1 scoped empty state. Changed the calendar to September 30: the map
showed 91 matching records and source-date-only/time-unavailable labeling.
Selected Horry from county ranking (11 reported winning tickets), then MYRTLE
BEACH (7), then Circle K Stores #2708114 (ranked aggregate 2). The opened
individual Pick 4 claim detail showed one winning ticket, September 30 CLAIM
DATE, $3K, retailer address 6501 N Kings Hwy, and the explicit statement that
draw date/time are not supplied and only mapped claims of at least $500 appear.
The source button opened the official SC WinnersReport page in Chrome. Returning
to the app retained the claim detail. No crash was observed.

This advances date navigation, county/city/retailer drilldown and claim-source
checks; it does not close remaining game/prize reset and integrated navigation
checks. Opening repository was clean, publisher 36908045746 remained successful,
and mail contained no new agency reply beyond previously recorded messages.
South Carolina remains unaccepted; deadline unchanged.

## October 1 native national-game filter/reset (17:00 ET session)

Dismissed the retained Circle K claim detail and opened Change South Carolina
game. All seven draw choices, including Xs and Os, were present. Selecting
Powerball on September 30 produced the explicit scoped-empty map and ranking
state (zero mapped records, not a claim of zero statewide winners). Selecting
All South Carolina activity restored 91 mapped records without changing the
date. The retained retailer ranking again showed its two Pick 4 records. No
crash observed. Prize reset and remaining integrated navigation verification
remain pending; no state acceptance or deadline change.

Opening repository was clean and publisher 36908045746 remained successful.
Michigan's new fee-conditioned response is recorded separately and does not
block South Carolina work.
