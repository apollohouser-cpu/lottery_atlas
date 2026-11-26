# Connecticut supported-coverage acceptance

Status: ACTIVE, unaccepted. Activated November22,2026 at15:36EST (20:36UTC).
Scope deadline: November23 at15:36EST. Release-decision deadline: November27
at15:36EST (20:36UTC), fresh120elapsed hours, no extension.

## Opening evidence and scope reconciliation

Chosen after Delaware acceptance because a validated scheduled Scratch catalog
already exists while draw/report integration remains substantial. The November21
local catalog contains82 games; its retrieval timestamp is not a new source date.
Preserve game1725 exclusion, annuity/cash validation, ended-but-claimable labels,
per-game inventory dates and unknown/TBD deadlines described in the source screen.

The official homepage inspected November22 redirects from ctlottery.org to
https://ctlottery.com/ and exposes results/source routes for Powerball and separate
Double Play, Powerball Xs & Os, Mega Millions, Millionaire for Life, Lotto!, Keno,
Cash5, and Play3/Play4 DAY/NIGHT. Payout controls are visible for several games;
button presence is not proof of audited count semantics or a working importer.
Play3/Play4 detail routes were opened. Wild Ball/combination fields need explicit
classification; no exact event times or counts are inferred from displayed digits.
Full scope remains pending reconciliation by the scope deadline, including
historical/ended products, add-ons, rules and report units.

Opening source capture and hash: ignored work/connecticut_acceptance_20261122.
No capture has been promoted as validated app data. Current scratch importer:
tooling/import_connecticut_scratch_catalog.py. No dedicated Connecticut draw
importer was found in the opening tooling inventory.

## Required acceptance work

- [x] Fix full product/game scope and supported/unavailable matrix within24hours.
- [x] Audit structured results, prize/count definitions, dates, sessions and rules.
- [x] Integrate validated supported draws/reports with source links and disclosures.
- [x] Reconcile Scratch detail/tier presentation and retained source exclusions.
- [ ] Validate bundle/cache/remote adoption and byte/date retention on failure.
- [ ] Verify compact/landscape/enlarged-text navigation, details and source returns.
- [ ] Verify integrated physical offline behavior; automated tests alone do not close it.
- [x] Run proportional tests, build, publish and independently verify live bytes.
- [ ] Record evidenced acceptance or concrete unfinished gates by fixed deadline.

## Boundaries and comparison benchmarks

No verified complete retailer-linked claims or geographic activity is established.
The September23 agency response identifies public sources but no existing records
in the requested form linking winners to selling retailers, and no maintained
retailer coordinates. Missing agency records do not block honest supported release.
Do not invent map points, counts, store inventory or zero-activity conclusions.
Texas is the working-coverage comparison; New York is separately the12-month
breadth comparison. Connecticut does not yet match either benchmark. No full-year
history, all-tier statewide claims or complete geographic coverage is claimed.
Agency correspondence remains with its separate automation; no duplicate requests,
fees or new human attestations. Mobile beta gates remain independently open.

## November22 — reproducible structured source inventory

Added tooling/connecticut_source_inventory.py to extract the single embedded
nine-product draw inventory from captured Next.js stream chunks, rejecting
missing/duplicate/changed product sets, ambiguous inventories and unexpected
source routes. Four focused tests pass; the saved official homepage extracts
successfully into private draw_inventory.json. This is reconnaissance tooling,
not a validated result/count importer or public feed.

Observed product identifiers: powerball, xsandos, megamillions, mfl, lotto,
keno, cash5, play3, play4. Play3/Play4 explicitly label the additional digit
Wild Ball, not Fireball; DAY and NIGHT have distinct dates in the same capture.
Generic payout payloads put that digit in fields named powerPlayMultiplier and
multiplier: those keys must not be interpreted as actual prize multipliers.
Cash5 advertises Kicker, requiring separate rule reconciliation. Double Play
is nested under Powerball; its display date is empty and React references remain
unresolved, so do not invent an independent date from that display object.
Xs & Os numbers require verified team mapping. Keno includes a game number and
bonus but no payout rows in this snapshot; this is not proof of zero winners.
The current matrix remains provisional until rules, report units and historical
products are reconciled. Scope and release deadlines are unchanged.

## Supported scope fixed — November22,2026

Scope fixed before November23 15:36EST. Release remains November27 15:36EST.
All nine current draw detail pages were captured successfully and hashed privately;
visible schedules, prize/rule sections and game-specific official PDF links were
inspected. This fixes the release scope, not acceptance of parsers or completeness.

| Product | Bounded release scope | Required distinctions / unavailable coverage |
| --- | --- | --- |
| Powerball / Power Play | Dated results, separate add-on label, audited prize/rule information and source links | Multiplier is not a winning-ticket count; jackpot advertisement is not payout |
| Double Play | Separate dated result group and prize/rule source | Resolve explicit parent draw association; do not borrow an undated display object's date silently |
| Powerball Xs & Os | Dated team results, prize/rule information and promotion source | Verify numeric team mapping before display; promotion awards separate |
| Mega Millions | Dated results and multiplier-aware prize/rule information | Distinguish advertised base amounts from applicable multipliers and actual counts |
| Millionaire for Life | Dated results, literal life-prize labels and rules | Annual amount is not lifetime total or cash payout |
| Lotto! | Dated results, prize/rule information and sources | Preserve variable-prize qualifications |
| Cash5 / Kicker | Dated base results; separately labeled Kicker rules/prizes | Kicker is a player-selected additional number, not an independent drawn bonus; payouts may vary |
| Play3 DAY/NIGHT | Separate latest dated sessions, Wild Ball, wager-specific rules/prize tables | Preserve digit order and leading zeroes; generic multiplier fields actually carry Wild Ball |
| Play4 DAY/NIGHT | Separate latest dated sessions, Wild Ball, wager-specific rules/prize tables | Preserve digit order and leading zeroes; do not combine session dates |
| Keno / Bonus | Bounded dated/game-numbered snapshot, bonus and spot/wager rules | Not a live four-minute service; do not synthesize draw time or ticket counts |
| Scratch | Existing validated catalog plus audited available tier/detail presentation, dates, closeouts and sources | Keep1725 exclusion, annuity/cash checks, TBD omissions; remaining prizes are not retailer stock |
| Fast Play | Explicit bounded rules/source entry from official rules index | Current product inventory/results not established; do not infer active games from retained general rules |
| Historical/ended games | Explicit historical coverage limitation and official source routes where verified | No complete archive or current recurring schedule invented for old products |
| Second Chance / promotions | Separate official routes and scoped explanation | Do not count entries, promotional prizes or sports betting as retail lottery draw activity |

Dated statewide payout reports are included where their source fields and units
validate. Otherwise show a specific unavailable-count explanation alongside the
validated results and prize/rule table; a static prize chart never becomes an
actual winner report. Integration must preserve exact sources, observed dates,
source-versus-retrieval distinctions, and last-good bytes on failure. No full-year
history, complete all-tier retailer joins or new geographic layer is in scope.

Next implementation work: validated result normalization and source reconciliation,
then payout/report endpoint and units audit, bundle/cache/UI integration, and the
existing bounded native/publication acceptance checklist. No agency wait or paid
record request is added as a release prerequisite.


## November22 — initial validated result normalization

Implemented tooling/connecticut_draw_results.py for Powerball, Mega Millions,
Millionaire for Life, Lotto!, Cash5, Keno and separate Play3/Play4 DAY/NIGHT
snapshots. Number pools were checked against retained official detail-page text.
The private homepage replay produces10 result rows, preserving each session's
explicit source date, ordered digits/zeroes, Wild Ball, Power Play and Keno
identity/bonus. Non-Keno rows reconcile visible results with their explicit
API payload dates and numbers; overloaded Wild Ball fields never become payout
multipliers. Missing dates/sessions, future dates, invalid ranges, duplicate
pool numbers and source/payload disagreement fail closed.

Nine focused inventory/result tests pass. Private results_candidate.json remains
unpublished and unintegrated; no current freshness or native display is claimed.
Double Play reference/date resolution and Xs & Os team mapping remain separate
unfinished result requirements. Actual payout reports/units, rules integration,
production packaging and UI/cache/native checks remain open. This adds no claims,
retailer activity, winner counts or full-history coverage; deadline unchanged.


## November22 — Double Play date/reference validation

Double Play now has a separate normalizer using the explicit date on the API
draw that contains its nested result. A missing display date is not replaced by
retrieval time. The only supported Flight reference must target the same product,
display slot and root as the parent; arbitrary/cross-product references fail.
Inline arrays, bonus numbers, ranges and conflicting explicit dates are checked.
Power Play is never copied onto Double Play. Four new focused tests cover dated
association, bad references, inline mismatch and missing/conflicting data;13
Connecticut tests pass overall. Private opening replay now produces11 rows.
Xs & Os team mapping, actual reports/units, production integration and native
acceptance remain open. No public feed changed; deadline remains November27.


## November22 — Xs & Os mapping and payout endpoint discovery

Captured22 official script chunks privately with source hashes. The official
client's explicit32-team mapping is retained in tooling/connecticut_xsos_teams.json
with source URL/hash. Xs & Os normalization checks eight distinct valid IDs,
explicit date and API/display agreement, then maps IDs to reviewed team names.
All eight opening result names independently match the rendered homepage image
labels. Three new tests cover mapping, invalid/duplicate IDs and payload mismatch;
16 focused Connecticut tests pass. Private replay now has12 result rows across
all current draw/session groups including separate Double Play. No public feed
or app UI changed, and no team logos were copied into the app.

The official client exposes /api/winning-payouts with game, draw and date
parameters. A bounded Cash5 request for the captured November21 draw returned
numeric tier keys, counts, amounts and generic multiplier objects. Original bytes
and hash are private; tier mapping, Kicker/base meaning and count units remain
unaudited. Actual returned amounts differ from advertised combined Kicker prize
figures, so do not map numeric tiers or sum/add-on counts by assumption. The
endpoint discovery unlocks the next report audit without claiming publication.
Production packaging, rules/reports, UI/cache and native checks remain open.


## November22 — Cash5 payout tier audit

Official client Cash5 configuration explicitly maps source tiers1–7 to5,4,3,
4+Kicker,3+Kicker,2+Kicker,1+Kicker, under the label Winning Tickets. Its payout
chart uses separate Kicker amounts4350/65, while the detail's advertised combined
figures are4650/75. Preserve literal report amounts; do not silently substitute
advertised figures, add prizes together or sum base/Kicker counts into a unique
statewide ticket total. The footnote endpoint supplies general result/expiry text
but no additional payout-unit definition.

Added strict cash5 report parser and four passing focused tests: source draw/game
identity, draw-found flag, exact tier keys, nonnegative finite amounts/integer
counts, zero retention and separate Kicker semantics. The captured November21
report produces seven private candidate rows. Response echoes draw ID but no
date; the output explicitly attributes date to the audited result/request pair.
No report has been integrated or published. Other game reports, production
packaging, rules, UI/cache and physical acceptance remain open. Deadline unchanged.


## November22 — reproducible evidence-bound candidate builder

Added tooling/build_connecticut_candidate.py. It verifies original homepage and
Cash5 report byte counts/SHA256 before parsing, requires all12 unique result
session groups, and binds the payout request's exact game/draw/date parameters
to the captured result payload. Output is explicitly productionReady=false and
created exclusively, preserving any earlier candidate. No fresh source date is
inferred from replay time; the opening observed date remains November22.

22 focused Connecticut tests pass. The original captures build a private
coverage_candidate_v1.json with12 result groups and one seven-tier Cash5 report.
Additional replay probes correctly reject a changed request draw ID and changed
response bytes. This is a reproducible development artifact, not a published
release or device evidence. Remaining work includes other report/prize rules,
production schema/loader/UI, bundle/cache retention and physical acceptance.
No source scope or November27 deadline changed.


## November22 — Lotto, Xs & Os and life-prize report audit

Captured three additional payout responses using the opening result IDs/dates;
private manifest records request URLs, retrieval times, sizes and SHA256. The
official client explicitly maps four Lotto tiers, five Xs & Os team tiers and
nine Millionaire for Life tiers. A strict parser preserves literal source counts,
Lotto variable prizes and state-specific count headings, with no geographic
allocation or derived distinct-ticket totals. Three focused tests pass; private
replay yields18 report rows across the three products.

Millionaire for Life's API top amounts are18000000 and2200000, while the official
client displays annual life-prize labels. Their numerical meaning is not verified:
parser withholds those two numeric prize fields and retains the literal annual
labels, never presenting them as cash payouts or lifetime totals. Raw amounts
remain only in private source evidence. Other rows preserve dated reported prizes;
Lotto's actual report amounts differ from static advertised prizes as expected
under its variable-prize qualification. Counts/zeroes remain literal.

These candidates remain unintegrated and unpublished. Evidence-bound packaging
of the additional reports, Powerball/Mega Millions/Play3/Play4 report semantics,
prize/rule integration and native acceptance remain open. Deadline unchanged.


## November23 — four-report evidence package and remaining captures

The candidate builder now requires and verifies all four audited report captures:
Cash5, Lotto!, Millionaire for Life and Xs & Os. Every request's game, draw ID and
date must match its captured result; duplicate/missing manifests, wrong origins,
extra query parameters and hash/size changes fail closed. The private v2 candidate
contains12 result groups and four reports (25 literal tier rows). Earlier v1 bytes
remain preserved.26 focused Connecticut tests pass, including request binding.

Six additional official endpoint responses were captured privately with hashes
and retrieval times: Powerball (18 source count keys), Mega Millions (9), Play4
DAY/NIGHT (40 each), Play3 DAY/NIGHT (24 each). All report drawFound=true. These
key counts describe source schema only, not winner totals or accepted tiers.
Power Play/Double Play, Mega Millions multiplier partitions and digit-game
wager/Wild Ball semantics still require audit before normalization. Captures are
not promoted. No current freshness, app integration or physical acceptance is
claimed; fixed November27 release deadline and completed scope remain unchanged.


## November23 — Powerball report separation; Mega Millions reconciliation hold

The official client treats Powerball source counts as base counts and adds a
separate powerplay bucket for its combined display. New parser instead retains
both measures separately and leaves absent Power Play fields unknown. Source
tiers10–18 map exclusively to Double Play; no Power Play is applied. The jackpot
is labeled without presenting its API amount as an individual payment. Three
focused tests pass and the private replay yields18 separate tier rows. No public
report or statewide total has been published.

Mega Millions requires additional reconciliation: for the captured November20
draw, source tier4 counts=8 while its five explicit multiplier buckets sum to3.
Other tiers also differ. The official client uses multiplier sums for its display,
but this alone does not establish why aggregate counts differ. Preserve both
source measures privately and hold normalized MM payout counts until the
source semantics are resolved or disclose a bounded supported representation.
Do not force equality, invent missing multiplier winners, or use a sum as a
verified complete statewide total. Validated winning numbers remain independent.
Play3/Play4 units, report packaging and production/native integration remain open.
The fixed release deadline is unchanged; no agency message or paid work initiated.


## November23 — digit-game winning-play semantics and nine-report candidate

Audited the official client's Play3/Play4 display grouping. The heading is
Winning Plays, not tickets; source tiers overlap across Straight/Box combinations.
Parser preserves the exact reviewed groups and minimum-wager prize labels and
never produces a distinct-ticket total. Four separately dated DAY/NIGHT source
responses yield64 presentation rows. Source tier IDs, labels and grouping are
retained with official client URL/hash in connecticut_play_report_tiers.json.
Three focused tests cover overlaps, all four sessions and invalid/missing counts.

Candidate builder now binds and hashes Powerball plus four digit-session reports
alongside the prior four reports. Private v3 contains12 result groups and nine
reports; Double Play remains a separate section of the Powerball report. MM
payout counts remain explicitly withheld, not silently replaced or forced to
reconcile.32 focused draw/report/candidate tests pass. A broader discovery attempt
also selected the unchanged Scratch suite, which could not import lxml in the
system Python environment; no Scratch validation pass is claimed for this session.
No production feed/UI changed; packaging, rule presentation and native acceptance
remain open with the original deadline unchanged.

## November23 — release transport groundwork

Added the Connecticut release loader with an explicit reviewed SHA256 requirement
and supported-release identity check. Private candidates remain rejected even
when their hash is supplied. Failed/unreviewed refreshes retain the reviewed cache
or bundle and original source dates; valid remote bytes are cached verbatim.
Storage failures are reported separately from refresh failures; no valid source
fails explicitly instead of manufacturing coverage.

Six focused Flutter transport tests pass and targeted analysis reports no issues.
These use synthetic transport fixtures, not source validation or physical offline
lifecycle evidence. No production hash, endpoint, bundle or UI route is enabled
by this groundwork. Source packaging, rule presentation, app integration and
native acceptance remain pending; release deadline is unchanged.

## November23 — draw snapshot presentation

Implemented the Connecticut Drawings sheet for the reviewed candidate shape:
separate game/session selectors, preserved digit order/leading zeros and Wild
Ball, separate Double Play, reviewed Xs & Os team labels, and Keno game number
without an invented draw time. Dates and snapshot limitations remain visible;
Mega Millions payout withholding is disclosed. Official-source opening failures
leave results visible and show an error. No result creates mapped activity.

Five focused widget tests pass; targeted analysis has no issues. Fixtures are
synthetic presentation cases, not additional source or physical-phone evidence.
The sheet is not yet wired to production navigation or a published CT artifact.
Reports/rules presentation, packaging, integration and native acceptance remain
open. The November27 release deadline is unchanged.

## November23 — dated report presentation

Added report navigation from matching game/session/date snapshots, including the
separate Double Play section of the Powerball report. Presentation preserves
Winning Plays versus ticket labels, overlapping-group limitations, separate
Power Play counts (missing remains Not supplied), minimum-wager reference prizes
and life-prize numeric withholding. Dates and request/response provenance are
visible; no total, individual cash payment or selling location is inferred.

Nine draw/report widget tests pass and targeted analysis reports no issues.
Tests use synthetic fixtures; physical review and source packaging remain open.
These sheets still have no production app entry or published CT coverage feed.
Rules, Scratch detail integration and release acceptance remain pending; the
November27 deadline is unchanged.

## November23 — rule-source provenance and navigation

The private candidate builder now verifies all nine captured detail-page hashes
and game/source bindings before extracting one official game-rule PDF link per
product. Duplicate navigation links collapse; missing, ambiguous or foreign-host
rule links fail. Private v4 retains12 result groups, nine reports and nine rule
references. Link extraction establishes source routes only, not PDF-content
validation, current rule freshness or an offline rule/prize implementation.

Draw presentation now offers the matching external rule PDF and discloses its
offline limitation; Double Play uses the captured parent Powerball rule route.
Six focused Python checks and five draw widget tests pass; targeted Dart analysis
has no issues. Rules/prize content reconciliation, Scratch integration, production
packaging and physical acceptance remain open. No public CT artifact or new app
entry was enabled; the fixed release deadline is unchanged.

## November23 — Scratch detail presentation

Implemented a dedicated Scratch detail screen using the existing detail-verified
catalog schema. It displays original inventory dates, sales/claim dates with
explicit unknown/TBD values, original and unclaimed prize tiers, and separate
annuity labels versus verified cash options. Ended games remain labeled sales
ended. Game1725 is blocked defensively even if passed directly to the screen;
its conflicting cash amount cannot appear. Source opening is restricted to the
official hosts and failures preserve the displayed inventory.

Three focused widget tests pass, including scrolling to prize tiers; targeted
analysis reports no issues. These are synthetic UI checks, not a renewed source
audit or physical acceptance. Catalog navigation/production coverage packaging
and integrated phone verification remain pending. The release deadline is unchanged.

## November23 — integrated loader and Scratch navigation boundary

Connected the reviewed-release loader to draw presentation and a separate Scratch
catalog/detail navigation path. Catalog entries retain per-game inventory dates
and ended status, exclude1725, and preserve Back navigation. Loader failure is
visible with Retry/Close; retained observations show a refresh-failure disclosure.
This integration requires an explicitly provided reviewed release and does not
enable a production hash, bundle, endpoint or map route.

Two integration widget tests pass (offline catalog/detail/Back and no-valid-data
failure), with no targeted analysis issues. Synthetic fixtures establish widget
and loader behavior only, not physical lifecycle evidence. Actual source artifact
packaging, remaining rule/prize reconciliation and physical acceptance are still
pending under the unchanged November27 deadline.

## November23 — combined private coverage artifact

Private v5 now includes12 result groups, nine reports, nine official rule links
and82 games from the existing detail-verified Scratch catalog. Packaging requires
an explicit SHA256 match, preserves all original fields/source dates, and rejects
1725, duplicate IDs, future inventory dates, impossible remaining counts, missing
annuity labels and mismatched game-source URLs. This is packaging validation of
the existing catalog, not a fresh audit of upstream HTML or rule PDF contents.

The retained Scratch input digest is
70faf960a1502e88717efe8dee57e9641f14eff0d8fceb1fc4c12e2096a46c7d.
38 focused Python tests pass. The combined artifact remains private and marked
productionReady=false; no release loader bypass, publication or physical
acceptance is inferred. Rule/prize reconciliation, release review and production
wiring remain unfinished under the unchanged November27 deadline.

## November23 — source-bound rule qualifications

Reviewed the captured official detail-page prize and play explanations and added
bounded paraphrased notes for all nine products. Notes distinguish Power Play
from Double Play, ticket-specific Mega Millions multipliers, annual life-prize
labels, variable Lotto/Cash5 prizes, ticket-selected Kicker, Keno spot/wager/Bonus
qualifications, and digit-game wager/overlap semantics. Each summary is pinned to
its exact detail-page SHA256 and URL; changed captures require another review.

Private v6 includes the notes and draw presentation renders them beside official
rule links. Six focused Python checks and five existing draw widget tests pass;
targeted analysis has no issues. These notes are not complete wager/prize tables
or a review of all linked PDF contents. Remaining scope reconciliation, production
release packaging and physical verification remain open; deadline unchanged.

## November23 — actual-candidate presentation audit

Added an opt-in local presentation test using the exact private v6 artifact,
without committing its source payload. All12 result groups, nine reports and82
Scratch details rendered and completed one scroll at390×844 and844×390 with an
explicit2x text scale:206 presentation cases passed without Flutter exceptions.
Targeted analysis passes. Evidence and candidate SHA256 are retained privately in
work/connecticut_acceptance_20261122/presentation_v6.json.

This checks initial layout and one scroll, not every scroll position or visual
screenshot correctness. It is not physical landscape, actual iOS Dynamic Type,
source-return, persistence or offline-lifecycle evidence. Production packaging,
remaining rule/prize scope and native verification remain open; deadline unchanged.

## November23 — coverage, exclusions and ancillary source routes

Added a shared coverage screen reachable from Drawings and Scratch. It discloses
snapshot/date limitations, absent complete claims/geography/history, overlapping
play counts, Scratch1725, unresolved Mega Millions counts and life-prize amounts.
Fast Play is explicitly bounded to the official rules index; no current inventory
or results are implied. Second Chance and promotions have separate verified
source routes and are not counted as draw or map activity. External-source
failure leaves the page intact and visible.

Eight focused coverage/draw/navigation widget tests pass; targeted analysis has
no issues. Production wiring, full remaining prize-table reconciliation and
physical verification remain pending. No acceptance or beta gate is closed and
the fixed November27 deadline is unchanged.

## November23 — Keno spot prize references

Parsed all ten official Keno spot tables from the hash-verified captured detail
page:37 literal prize/odds rows. Packaging validates unique spot coverage, headers,
match ranges, prize notation and odds notation. Values retain their $1/no-Bonus
basis and are not converted into actual payouts or winner counts. Private v7
includes the tables, displayed as expandable spot sections beside retained Keno
qualifications and the official rules link. Bonus odds are not yet packaged.

Five focused parser/candidate tests pass. The actual-v7 presentation harness and
targeted Dart analysis pass; the harness tests initial/scroll layout, not expanded
table visual review or physical device behavior. Remaining prize schedules,
production review/wiring and native acceptance remain pending; deadline unchanged.

## November23 — additional reference prize schedules

Private v8 adds29 literal advertised prize/odds rows across Cash5 base/Kicker,
Lotto, Millionaire for Life and Mega Millions. Source row headers are now read
explicitly; jackpot labels, stars, annual amounts and base-prize headings remain
unchanged. Each table carries its variable-prize, annuity or multiplier basis.
Cash5 advertised combined Kicker prizes remain separate from dated report amounts.
Presentation uses source column headings instead of assuming every table is Keno.

Seven focused Python tests pass, targeted Dart analysis is clean and the actual-v8
initial-layout/scroll harness passes. Expanded-table visual review and physical
evidence are still pending. Powerball, Xs & Os and digit-game reference tables
remain unfinished, as do production release review/wiring and native acceptance.
The fixed scope and November27 release deadline remain unchanged.

## November23 — Powerball reference prize columns

Private v9 preserves nine Powerball/Double Play reference rows in separate prize
columns. Power Play has seven multiplier rows plus separately labeled source
cells spanning all multipliers: the jackpot is not multiplied and the five-white-
ball prize is fixed. The10X eligibility qualification remains explicit. UI now
renders every source column, including four/six-column references, instead of
assuming three columns. No reference prize becomes a payment or winning count.

Five focused Python tests, targeted Dart analysis and the actual-v9 initial-layout/
scroll harness pass. Expanded-table visual review remains pending, as do Xs & Os
and digit-game tables, production review/wiring and physical acceptance. Scope
was fixed on time November22; neither the elapsed scope deadline nor the fixed
November27 release deadline is extended.

## November23 — team prizes and multiplier reference odds

Private v10 adds five Xs & Os team-match prize references, six Keno Bonus outcomes
and five Mega Millions multiplier-frequency rows from the verified detail pages.
The No Bonus outcome stays explicit. Frequencies/odds are reference distributions,
not counts of winning tickets. Xs & Os jackpot and reduction qualifications remain
separate from promotional awards; unresolved Mega Millions payout counts remain
withheld despite the supported reference multiplier table.

Five focused Python tests and the actual-v10 initial-layout/scroll harness pass.
Expanded-table review, digit-game wager matrices, production release wiring and
physical acceptance remain pending. Source dates, exclusions and the fixed
November27 release deadline are unchanged.

## November23 — digit-game wager matrices

Private v11 now retains all four captured Play3 and all four Play4 reference
matrices: base and Combo, with and without Wild Ball.72 rows below the first
header include the additional Wild Ball wager headers. Source row/column spans
are expanded without calculating new prize values; dashes remain dashes, and
base/Wild Ball/total-wager distinctions and example combinations are preserved.
Changed matrix inventory, wager columns, ragged rows and unfinished spans fail.

Five focused Python tests and the actual-v11 initial-layout/scroll harness pass.
All nine draw products now have reference prize material, but expanded-table
review and final source/release reconciliation remain required. Production
publication/wiring and physical acceptance are not inferred from this private
candidate. The November27 deadline remains unchanged.

## November23 — expanded-table and reproducibility checks

Rebuilding from the retained captures and Scratch bytes produces a semantically
identical v11 candidate. Added explicit expansion/scroll checks for all29 reference
tables at390×844 and844×390 with2x harness text scaling:58 expanded-table cases
reach the final source row without Flutter exceptions. The206 initial-layout/
scroll cases also pass. An initial harness attempt tapped before scrolling settled;
awaiting settle fixed the test timing without changing production UI.

Private evidence: work/connecticut_acceptance_20261122/presentation_v11.json.
This establishes automated reachability, not screenshot correctness, physical
iOS Larger Text, source-return or offline lifecycle. Source/release reconciliation,
production wiring, publication and native acceptance remain open. Deadline unchanged.

## November23 — prepared release projection

Prepared268733-byte supported-coverage artifact privately from exact v11 bytes,
SHA25610ca4859d574887366c2fd027266dfabd50ec916e1c3d804ab7ff8a084c538dd.
Packaging requires the reviewed candidate digest, omits private capture manifests,
replaces development-only limitations with bounded public disclosures, preserves
original observations and rejects nested private fields/local paths/nonofficial
source hosts. The artifact is release-shaped but is not published, bundled or
installed; state acceptance is unchanged.

50 focused Python tests pass (the unchanged lxml-dependent Scratch importer suite
was not rerun). The prepared artifact passes the264 automated initial/expanded
layout cases. Private file: work/connecticut_acceptance_20261122/coverage_release_review.json.
Remaining work is final release review, production loader/navigation wiring,
publication/live-byte verification, signed build and physical acceptance. The
fixed November27 deadline is unchanged.

## November23 — production artifact and navigation wiring

Reviewed the prepared artifact identity, scope, exclusions and source-only fields;
added identical268733-byte release files to data/docs and pinned the published
loader to SHA25610ca4859d574887366c2fd027266dfabd50ec916e1c3d804ab7ff8a084c538dd.
Direct Connecticut map Drawings/Scratch and state-source routes now use the
reviewed loader. The bundle is registered; publication CI verifies exact digest
and bundle/public byte equality before deployment. Source dates remain unchanged.

22 focused Flutter tests pass; targeted analysis is clean. The release factory
initializes preferences lazily, allowing digest validation independently of the
platform store. Publication/live-byte verification and the signed native build,
installation and physical acceptance are still pending. No state or beta gate
is closed; the fixed November27 deadline remains unchanged.

## November23 — publication verified and signed iPhone update prepared

Publication run45309751050 succeeded. Independent live download matches the
reviewed268733-byte release SHA256
10ca4859d574887366c2fd027266dfabd50ec916e1c3d804ab7ff8a084c538dd.
The102.8MB signed iOS release built successfully, passed deep/strict signature
verification and contains exactly those reviewed Connecticut bundle bytes.
Private deployment/build/signature evidence is under
work/owner_iphone/connecticut_20261123.

The owner iPhone is disconnected; this prepared update has not been installed.
Connecticut physical navigation, source-return, layout and offline checks remain
pending. No acceptance or broader beta gate is closed; the fixed November27
15:36EST release deadline is unchanged.

## Prepared physical review — November23

The checked items above reflect the bounded source audit, production wiring and
verified publication/build evidence already recorded. They do not imply installed
or physical verification. The prepared build remains uninstalled while the phone
is disconnected; the existing connection request remains pending.

After installation, verify these Connecticut-specific flows on the physical phone:

- Open Drawings and Scratch from the Connecticut map and state-source routes.
  Switch Play3/Play4 DAY/NIGHT; keep Double Play separate from Powerball.
- Open reports and expanded prize tables, scroll to their final rows, then return.
  Check literal Winning Plays versus Winning Tickets labels and the withheld
  Mega Millions counts explanation; do not interpret reference prizes as payments.
- Open Scratch details, inspect tiers/dates and annuity-versus-cash labels, and
  confirm the disclosed game1725 exclusion. Follow an official source and return.
- Check portrait, landscape and actual iOS Larger Text for readable content,
  scrolling and reachable Back/Close controls in these Connecticut screens.
- After online loading, restart offline and try refreshing Drawings and Scratch.
  Verify retained content and original source dates remain visible; restore
  connectivity afterward. Record each observed outcome separately.

Native cache-byte evidence, owner observations and any failed checks must be
recorded without substituting automated layout tests for physical results.
No repeat Delaware checks or broader beta gate closure is implied.

## November26 — Connecticut update installed and launched

The owner iPhone became available. The prepared release passed deep/strict
signature verification again and its bundled Connecticut bytes matched the
reviewed digest. In-place installation and CLI launch both succeeded. Private
install/launch evidence is under work/owner_iphone/connecticut_20261123.
No repeat trust or sign-in was needed. This supersedes the pending-install status;
the owner may disconnect. Connecticut physical navigation, source-return, actual
iOS text/layout and offline checks remain pending, as does native cache evidence.
No state acceptance or broader beta gate closure is inferred. The November27
15:36EST release deadline remains unchanged.
