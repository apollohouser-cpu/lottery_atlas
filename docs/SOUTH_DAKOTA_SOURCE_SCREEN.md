# South Dakota source screen — September 15, 2026

The South Dakota Lottery's official [Winning Players](https://lottery.sd.gov/winning-players/)
page publishes selected winners with claim date, game, prize, selling retailer
and city. The page describes these as players who won top prizes, so the list
does not prove complete all-tier coverage. Its records are useful verified
retailer-linked activity only when labeled as a selected-winner subset.

The official [Locations](https://lottery.sd.gov/locations/) page provides a
retailer search and can display recent published winner activity at individual
locations. An older official retailer PDF is also indexed publicly, but its
current completeness and stable update cadence have not been established.
Neither source proves a complete current retailer directory or a join for every
validated winning ticket.

An August 1–31, 2026 records and routing request was emailed September 15 to
the Lottery address published on both the Lottery and Department of Revenue
contact pages. It requests existing all-tier Lotto and Scratch winning-ticket
records, a complete active-retailer directory, winner-to-retailer joins, data
definitions, cadence and corrections. The request excludes claimant personal
information and asks staff to route it to the correct records custodian if
needed. Gmail confirmed “Message sent.” Requester contact information was
supplied directly and is not stored in this repository.

South Dakota remains suitable only for clearly labeled selected-winner
activity until responsive records establish complete coverage. It is not ready
for full-state testing.

## September 20, 2026 official catalog/API audit

The [Scratch Games page](https://lottery.sd.gov/scratch-games/) embeds a
Next.js `__NEXT_DATA__` payload. Its `post.blocks` Scratch-filter attributes
contain 100 game entries: 32 marked active, 64 closed and four upcoming;
additional featured/second-chance/closing tags can overlap these statuses.
The initial HTML has an empty rendered game grid, but the embedded catalog
is present. Do not infer an empty catalog from server-rendered text alone.
The 100-entry listing has no verified completeness/pagination metadata in
this audit, so it is a published-list subset, not proof of every state game.

Public site JavaScript calls
`/api/igt/games/v1/instant-games/games/{igtIdentifier}`. All 32 explicitly
active entries were retrieved successfully and agree with that endpoint's
`ACTIVE` validation status and explicit listing ticket prices. They contain
268 prize-tier rows. The API expresses ticket and cash prize amounts in cents;
the site's display divides by 100. Its remaining-count calculation is
`winningTickets - paidTickets`, with top prize selected from prize tiers.
Every audited tier has integer nonnegative counts and paid <= winning, and
every game has unique tier numbers. Preserve the components alongside any
derived remaining count. These are cumulative inventory/paid quantities,
not claims assigned to the requested 2026 period or retailer-level activity.

The endpoint supplies distribution/disable dates but no inventory verification
timestamp in the inspected responses. Do not convert a far-future operational
date into a verified consumer claim deadline. Publication cadence is unconfirmed;
retrieval time must stay separate from source verification time. Before an
import is enabled, add tests for cents conversion, explicit active status,
missing/negative/impossible counts, duplicate tiers, listing joins and the
100-entry coverage limit. No South Dakota public feed was changed in this pass.

Reproducible read-only audit materials are in ignored
`work/south_dakota_catalog/`: source HTML/JavaScript, `active_listing.json`,
32 official inventory responses, `audit.py` and `inventory_audit.json`.
The September 15 records request remains pending; no duplicate was sent.

### Validated subset import

A fresh official fetch validated 32 explicitly active games and 268 prize tiers.
The importer verifies Scratch type, unique identifiers, active-status agreement,
explicit listing/API ticket prices, cents conversion, unique tier numbers and
nonnegative integer inventory with paid <= original winning inventory. It finds
the maximum prize rather than relying on API tier order. Ambiguous top tiers,
missing fields and contradictory status stop publication before file replacement.

The combined feed and offline bundle now carry this subset. Every game discloses
published-subset scope, cumulative inventory semantics and unknown verification
time/store availability. `sourceDate` remains null; `updatedAt` is retrieval/change
time. Distribution and disable dates are deliberately not mapped to claim dates.
The six-hour refresh checks these same constraints. Five importer regression tests
and an offline app-loading test cover the core boundaries. This is catalog-ready
partial coverage, not all-state claims coverage or a completed retailer heat map.


## October 18 activation — current official route capture

South Dakota activated October 18, 2026 at 04:24 ET; scope due October 19, 2026 at 04:24 ET;
supported release due October 23, 2026 at 04:24 ET. See SOUTH_DAKOTA_ACCEPTANCE.md.
Fresh home/Lotto/Dakota Cash/winning-number HTML is private in
`work/south_dakota_scope/`, with retrieval metadata. Current navigation lists
Powerball/Double Play, Mega Millions, Dakota Cash, Millionaire for Life, Lotto
America and Powerball Xs & Os. Related-game content also retains Lucky for Life;
status is unresolved. Dakota Cash metadata mentions EZ Match. Actual draw API,
options, history and literal schedules remain to inspect before scope closure.
The Dakota Cash page's selected-winner cards include Powerball records: do not
assign cards to the hosting page's game. No new public feed, build or acceptance
claim is made. Existing Scratch validation remains intact; fresh audit pending.


## Scope closed October 18 at 05:22 ET — public API and product dispositions

Scope closed early; release deadline remains October 23 at 04:24 ET. This is
research scope closure, not collector/app/native acceptance.

| Product | Supported target and boundary |
| --- | --- |
| Powerball / Power Play / Double Play | Two completed draws each for base and Double Play, separate result groups; literal option schedules. Never attach base advertised jackpot to Double Play. |
| Mega Millions | Two completed results and full literal multiplier schedules. API multiplier prize rows kept distinct; geographic count attribution requires separate validation because this component says only Winners. |
| Dakota Cash / EZ Match | Two completed draw results, literal base and eight-row EZ Match prize/odds schedules. EZ Match is ticket-specific instant matching, not another dated draw. |
| Millionaire for Life | Two completed results and literal annuity/cash qualifications; zero top-tier API amounts are not zero-value prizes. |
| Lotto America / All Star Bonus | Two completed results, distinct multiplier semantics and literal schedules. |
| Powerball Xs & Os | Two completed team results using explicit source ID/team map, all literal rules and schedules. |
| Lucky for Life | Historical official route only. API returns February 21/20 local completed results followed by NO_MORE_DRAWS with a 1941 sentinel timestamp; no next draw or current-game claim. |
| Scratch | Fresh validated published active subset: 35 games, 293 tiers out of a 100-entry listing. Source verification timestamp remains null; original/paid/remaining quantities are cumulative inventory, not dated claims. All tiers required in app. |
| Video Lottery | Official overview and licensee/reports routes only; machine play, per-play results, claims and machine positions unsupported. |
| Retailers / selected winners | Official locations and selected-winner routes; no imported joins/coordinates or complete directory/claims claim. Locations default returns a bounded 96-result view, not proof of statewide completeness. |
| Players Club / second chance / mobile cashing | Official routes only; no login, entries, purchases or claims transactions in Atlas. |
| Older history | Official winning-number search route; ten-year import deferred. |

Target: **14 bounded results across six current families/seven result groups**,
plus literal game/option schedules and full supported Scratch tiers. No daily
Midday/Evening split was found in these current products; preserve source draw
identity and variant rather than inventing sessions.

The site's actual public request is
`/api/igt/games/v2/draw-games/draws?game-names=...`; past-number search adds
`date-from` and `date-to` Unix milliseconds. Six current identifiers each return
one OPEN record and two PAYABLE records. Select by status/results, never array
index. Powerball has Regular and Double Play result objects in each completed
record; repeated tier IDs across variants cannot serve as globally unique keys.

Preserve raw drawTime milliseconds and derive the calendar date explicitly in
America/Chicago. These API timestamps do not establish exact physical drawing
times; do not present their 21:15 operational value as broadcast time. The
estimatedJackpot field is cents while jackpots.amount and prize shareAmount
are dollar-valued in the site's respective formatters; never apply one global
unit conversion.

Official winning-number JS labels the generic table **SD Winners**, binding
shareCount to that column and multiplierShareCount to a separate SD option
column. This supports a source-labeled count unit, not unique persons or paid
claims. Mega Millions uses a different renderer, so geographic attribution and
zero/dash placeholders remain separate validation questions; exclude unsupported
counts rather than infer them. Xs & Os renderer suppresses the prize column;
use its literal schedule independently.

Private evidence: all seven current detail pages, Lucky for Life detail,
public responses and draw-api-audit.json; extracted *-rules.json; source JS
2-dti7y5tqmn2.js (history/table binding), 3ya3s1xnb6tvy.js (API client/card);
scratch-fresh.json and official route captures in work/south_dakota_scope.
No public feed or native build changed. Next: strict parsers for status,
date, variant, count units and schedule extraction, then coupled publication,
app integration and native gates.


## October 18 — bounded number parser checkpoint

Added strict six-family result parsing with the seven public result groups kept
separate. Eleven regression tests pass against captured public API fixtures: all
14 results, UTC-to-Central previous-day conversion, unordered response records,
variant-specific source links, domain/cardinality/duplicate checks, source
weekday checks, invalid/future/OPEN states and multiplier isolation. Powerball
Double Play never inherits the base multiplier or jackpot. No prize amounts or
winner counts enter this number-only output; reporting remains a separate
validation contract. Explicit raw timestamps and America/Chicago date zone are
retained. Missing/changed response structure fails closed.

This parser is not connected to publication yet. Literal schedule extraction,
count-report validation, coupled atomic collector, app integration and native
acceptance remain open. No feed, build, acceptance or deadline changed.


## October 18 — literal rule/schedule parser checkpoint

Seven current detail pages now have reviewed rule-tab contracts and strict
extraction into ordered text/table blocks with source links. All 23 tabs,
including claim qualifications, are retained; physical table rows are preserved:
Powerball page 18 (base plus Double Play), Double Play page 9, Mega Millions 9,
Dakota Cash 12 (four base plus eight EZ Match), Millionaire for Life 9,
Lotto America 9, Xs & Os 5. The overlapping Powerball/Double Play schedules
remain source-specific; these counts are physical rows, not unique prize types.
Fresh captured pages match the contracts. Changed prizes, removed qualifications,
ambiguous identity/tabs and malformed/spanning tables fail closed.

Two source inconsistencies require visible qualification during integration:
Millionaire for Life's page retains a Lucky for Life heading/purchase reference;
its actual prize rows name the Millionaire Ball and annuities. Preserve the
literal source text without relabeling the game or implying Lucky for Life is
current. Mega Millions' static table contains base amounts while its result
renderer separately exposes multipliers; do not represent the static base
amount as the final current ticket payout. Count/report integration remains
a separate validation contract. No inferred cash value or multiplier payouts.

24 South Dakota Python tests pass (11 bounded results, eight rule/schedule,
five existing Scratch). Fixtures contain only source API data or minimal
rule-tab page structures, not unrelated selected-winner content. No public
feed/build/native acceptance change. Next: dated report validation and coupled
atomic collection, followed by app/native integration.


## October 18 — atomic private collection checkpoint

The private collector now fetches six result APIs and seven rule pages, validates
all 14 results/23 rule tabs before replacement, and preserves raw source dates.
It rejects retrieval/date regression, missing groups and changed overlapping
draw identities/results pending explicit correction review. No public schema or
scheduled publication is enabled yet; dated count/prize reporting is still a
separate unfinished contract.

31 South Dakota Python tests pass. New transaction tests inject failure at each
of the 13 source requests, a changed literal schedule, a changed completed draw,
a regressed retrieval clock and an atomic-replace disk failure. Prior bytes and
dates survive each failure; temporary files are cleaned; no-baseline failure
creates no output. This is the private staging transaction, not a claim that
combined Scratch/draw public refresh or native cache testing is closed.

Fresh live private staging succeeded with retrieval 2026-10-18T12:21:52.734136+00:00;
14 results and seven rule pages agree with the strict contracts.


## October 18 — dated report parser checkpoint

Separate strict report parsing now binds every report to its validated completed
draw ID/date/variant. Twelve reports retain the official generic-table label
SD Winners; the two Mega Millions selections instead carry an explicit missing
count-geography limitation. MM counts are excluded, not converted to zero.
The generic source binding was established in captured official winning-number
JS; these are source-labeled counts, not unique people or paid claims.

Powerball's repeated tier IDs are validated in their complete ordered base/DP
contract. Double Play retains its own nine rows and no multiplier count; nonzero
DP multiplier data fails closed. Power Play and All Star Bonus source counts
remain separate from base counts and are not assumed to be subsets or summed.
Dollar shareAmount values are not divided by 100. Zero prize amounts remain
unknown/placeholder values with schedule guidance; no zero-dollar prize is
claimed. MFL top rows use the official renderer's annuity labels, and Xs & Os
amounts are omitted as in the official result table, with literal schedules
separate. No derived multiplier payouts or unsupported MM totals.

39 South Dakota Python tests pass, including eight dated-report tests for
variant separation, count types, missing/changed tier identities, monetary
placeholders, annuities and explicit MM gaps. Report parser is not yet connected
to staging/publication or app UI. Next integrate reports into atomic collection
and retain overlapping report corrections for review, then public/app/native.


## October 18 — reports integrated into private atomic collection

The all-source staging transaction now includes the dated reports alongside
14 results and seven rule pages. Twelve reports contain source-labeled SD
Winners; two MM records retain explicit missing-count limitations. Changes to
an overlapping report's counts, amounts, source label or structure require
review and preserve the retained collection. Missing retained report structure
and changed retained schedules also fail closed rather than silently migrate.
The earlier number-only private snapshot is preserved separately; the new
report-bearing baseline is work/south_dakota_scope/reports-collection-stage.json.

41 South Dakota Python tests pass, including new report-count correction and
missing-retained-report cases. Fresh live all-source collection succeeded at
2026-10-18T14:28:27.837853+00:00. No new public feed, scheduled
configuration, native build or acceptance. Next prepare the public contract and
coupled Scratch/draw refresh, then app integration and native validation.


## October 18 — public contract and coupled refresh configured

Fresh source collection produced schemaVersion 1 for the bounded 14 results,
12 source-labeled reports plus two explicit MM gaps, and seven rule pages.
Baseline files: data/south_dakota_draw_collection.generated.json and
docs/south_dakota_draw_collection.json. Staging/public mode changes require an
explicit baseline; no silent schema conversion of retained files.

The existing South Dakota refresh job now owns both Scratch and draw outputs.
Failure in either importer restores both prior byte streams and dates. The
publish workflow stages the draw feed alongside the existing combined Scratch
feed. 42 South Dakota tests and 13 shared transaction tests pass, including
South Dakota failure at each importer with both baselines restored. Warnings
in these tests are intentional injected failures.

App integration, source qualifications in UI, team-name presentation and native
acceptance remain open. This feed contract is not state acceptance. Deployment
and independent live-feed verification remain to confirm after push. No native
build or deadline change.


## October 18 — deployed feed verified; team identity contract

Both push and subsequent scheduled workflow runs for 6921225 completed
successfully. Independent live draw feed retrieval exactly matches the
scheduled baseline ea4ac9c, retrievedAt 2026-10-18T15:55:16.795276+00:00.
The difference from the earlier local baseline was retrieval time only;
results, reports and schedules were unchanged. The scheduled commit was
fast-forwarded locally without replacing unrelated work.

Xs & Os team IDs now validate against all 32 explicit official page mappings,
with duplicate, missing and renamed identities rejected before collection.
The captured result IDs 1/10/11/20/21/24/31/32 map to
ARI/DEN/DET/MIA/MIN/NYG/TEN/WAS. No team is inferred from list position,
a number's appearance, or an external sports result. This reviewed mapping
will support app presentation; no new feed shape or native build is claimed.
43 South Dakota Python tests pass. App/UI and native acceptance remain open.


## October 18 — app data layer checkpoint

Added independent Dart validation and remote/cache/bundle loading for the public
collection. The app validates reviewed rule/report structure, count integer
semantics, all number domains, date-zone conversion, local weekdays, variants,
source links, report-result binding and overlapping correction retention.
Time-zone data initializes within this validator, independent of other states.
The offline asset is registered. Five Flutter data-layer tests pass: complete
collection, malformed values/contracts, changed overlapping counts, request
failure retention and persistence failure with valid newer remote data.
Three production Dart files analyze cleanly.

This data layer is not yet wired to a visible South Dakota screen. Widget/native
flows, full Scratch tier UI and team presentation remain open. No new native
build, acceptance or deadline change.


## October 18 — visible draw screen integrated

South Dakota state source page opens the validated collection. Each of 14
selections retains its own report/date/variant, physical schedule fields and
official game return route. Xs & Os displays reviewed source team abbreviations.
MM count gaps and static base-payout limitations remain visible; MFL stale
source wording is explicitly qualified. Dated-search and game-page buttons
are distinct. Selecting another result resets the detail scroll.
Six Flutter tests pass including all 14 selections with enlarged 2x text;
changed UI files analyze cleanly. This verifies rendering, not native source
return, scroll traversal or OS text settings. Full Scratch tier UI and native
checks remain next; no readiness/deadline change.


## October 18 — full Scratch inventory app integration

Added a South Dakota Scratch sheet and validated remote/cache/bundle loader.
All 35 published active-subset games and 293 physical tiers retain original
winning inventory, cumulative paid tickets and computed remaining prizes.
Source verification remains unpublished; listing completeness, store stock,
dated claims and retailer joins are not implied. Search, ticket-price filtering,
game selection and reset share the existing accessible sheet pattern.

Three focused Flutter tests pass: strict arithmetic/unit/source validation,
original-inventory continuity and request-failure cache retention, plus enlarged
text search/empty/reset interaction. Three changed production files analyze
cleanly. Generated Scratch baseline is registered as an offline asset. Native
Scratch/detail/source returns and draw traversal, newer remote adoption and
production-loader native retention remain open. No native build, acceptance,
or deadline change; South Dakota remains due October 23 at 04:24 ET.


## October 18 — ordinary iOS build and initial native traversal

Ordinary main.dart simulator debug build at 3bcc8d8 passed (33.9-second Xcode
build), installed and cold-launched on the original iPhone 17e/iOS 26.5 UUID.
Android was shut down before iOS boot; PNY links and permissions unchanged.
Navigated normal map search to South Dakota and Sources and coverage.

Native draw dropdown selected all fourteen entries across seven groups and both
dates. Local dates/numbers changed with each selection; Double Play omitted the
base multiplier, both MM selections showed explicit excluded-count wording,
and both Xs & Os selections showed the reviewed team abbreviations. Portrait
Powerball screenshot showed readable separate source-count fields. This is
summary-selection evidence only, not complete rule traversal/source-return.

Native Scratch loaded 35 games, rendered original/paid/remaining fields and
unpublished verification time. Name substring search selected Moola (1/35),
reset restored 35/35, and the $1 filter selected four games. Moola tier scrolling
reached tier 9 and the source-date qualification in accessibility output; the
footer source buttons/return still need traversal. Some native scroll gestures
left the viewport unchanged; do not count those attempts as completed checks.

Remaining: complete long-rule and source-return flows, compact/wide/enlarged
text, Scratch footer/detail return, draw newer-remote adoption and controlled
production-loader request-failure retention. No acceptance or deadline change.
Ordinary iOS remains running on filtered Moola inventory; Android is stopped.
Private build evidence: work/south_dakota_scope/ios-build.log.
