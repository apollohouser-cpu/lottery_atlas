# Idaho source screen — September 16, 2026

**October 22, 14:22 ET: Idaho is now the sole active implementation state.**
See IDAHO_ACCEPTANCE.md for fresh scope/release deadlines and opening evidence.
Earlier single-product testing and correspondence do not imply full acceptance.

The [official Scratch catalog](https://www.idaholottery.com/games/scratch)
shows remaining prizes by game and tier, including lower tiers on its “View all
prizes” display, plus percent sold. These are **remaining prizes**, not a
dated count of winning tickets claimed or validated. The screen did not expose
the original inventory or a stable historical snapshot for each tier, so
claimed tickets cannot safely be inferred from this page alone.

The [Idaho Cash game page](https://www.idaholottery.com/games/draw/idaho-cash)
has an “Idaho Winners” table with counts by match/prize tier for its latest
drawing. This is a promising official all-tier **single-game, single-draw**
count, including free-ticket wins. The page also lists past winning numbers,
but this screen did not establish historical winner counts for every draw or
similar coverage across every Idaho-sold draw game. The free-ticket tier must
be labeled as such rather than assigned a cash prize.

The [official retailer finder](https://www.idaholottery.com/pages/find-a-retailer)
searches by city, ZIP and map. It does not establish a complete exportable
active-retailer directory with stable IDs or a join from every winning ticket
to its selling store. The Lottery's
[public-records request form](https://www.idaholottery.com/images/uploads/general/Request_For_Records_Fillable_updated2025_email2.pdf)
is a potential route for the missing existing records; no request is claimed
as filed in this screen.

Idaho can show the currently published Idaho Cash draw-tier counts and current
Scratch remaining-prize snapshots only with exact game, drawing or source date,
count definition and coverage notices. It is not yet ready for a complete
statewide winning-ticket total or retailer heat ranking. Historical access,
refresh cadence and correction handling require verification.

September 17: a written 2026 year-to-date public-records request was sent to
`info@lottery.idaho.gov`, the email printed on the Lottery's official request
form. It asks for Idaho-sold all-tier draw-game counts, Scratch prize/claim
inventories, an active retailer directory, any maintained retailer joins, and
source cadence and correction definitions. An August 2026 sample is acceptable
for initial routing, but does not replace the requested year-to-date period.
Gmail confirmed the message was sent; agency acknowledgment and records are
pending. No fees were authorized.

## September 19 API and directory audit

The current official site's date-picker JavaScript exposes the public route
`https://www.idaholottery.com/api/v1/drawgame/idaho-cash/YYYY-MM-DD`.
`tooling/import_idaho_cash_draw_tiers.mjs` retrieved and validated every one of
**261 consecutive daily drawings from January 1 through September 18, 2026**.
It checked each response's game and requested date, five distinct numbers in
range, all four unique tier labels, and nonnegative integer counts. Tier
labels, rather than response ordering or `weight`, identify the prize tier.
The four sums are 5 jackpot-tier wins, 989 $200-tier wins, 38,046 $5-tier wins
and 476,082 free-ticket-tier wins. These are **published prize-tier winner
counts**, not verified distinct tickets or players. Idaho Cash offers two
plays on a $1 ticket, so adding tier counts must not silently become a count
of distinct tickets. Free tickets are not assigned a cash amount.

The dated audit is stored in `data/idaho_cash_draw_tiers.audit.json`, with a
direct official source URL for every drawing. It is not registered in the
public activity or state winning-ticket-total feeds, and it is not an
all-game Idaho total. The importer checks the latest published winner-table
date and rereads the complete year-to-date sequence when run; it has not been
added to the recurring publisher pending source-definition review. Daily
drawings do not establish an API publication SLA or correction policy.

The same official site's retailer-map JavaScript directly loads
`https://id-lottery-public.s3.us-west-2.amazonaws.com/Drupal-Site/Retailers/retailers.json`.
On September 19 this file contained **1,368 unique retailer IDs** with names,
addresses, city, state, ZIP, game types and coordinates. The response's
Last-Modified timestamp was **2026-09-19 10:00:29 UTC**, which is file metadata,
not proof of when each retailer record changed. There are 1,135 entries
listing Draw or Scratch games, 68 with no listed game type, and other entries
covering Tab games. All rows label their state `ID`; 137 have a zero latitude
or longitude, and 12 additional entries fall outside coarse Idaho bounds.
County-polygon and address checks remain necessary before map integration.
Do not assign nearby coordinates or describe this as a fully verified active
Draw/Scratch directory merely because the export is statewide.

A local point-in-polygon audit against the bundled 44 Idaho Census counties
found 1,216 of all entries in exactly one county, 137 with missing coordinates
and 15 outside those polygons. Within the 1,135 Draw/Scratch entries, 1,020
matched one county and 115 had missing coordinates; none were assigned to a
nearest county. This verifies containment of the published points, not an
independent street-address match. The working audit is retained locally in
`work/idaho_retailer_coordinate_audit.json` for the directory integration step.

The September 17 records request remains pending. A defined distinct-ticket
measure, winner-to-selling-retailer joins, publication/correction timing and
coordinate exceptions are still unresolved. Idaho is **not yet ready for
retailer heat-map testing**. The new API access advances historical-source
availability without removing those coverage limits.

## September 21 current Scratch catalog integration

A fresh official catalog and all 32 linked detail pages were validated against
one another and the separate [Scratch Claim Dates](https://www.idaholottery.com/games/claim-scratch)
schedule. The initial catalog contains **32 games and 222 remaining-prize tiers
of $25 or more**. All 317 printed prize-structure rows were inspected; the other
95 rows explicitly say remaining quantities are unavailable. Those amounts are
preserved separately as unknown, never converted to zero or used to infer claims.
The detail pages also publish original prize quantities, refining the earlier
September 16 listing-only screen. Original quantities are not dated claims.

The official detail-page statement specifies once-daily prize updates and excludes
remaining counts below $25. No inventory verification date is printed, so
`sourceDate` stays null and retrieval time stays separate. There are no verified
store-stock or winner-to-retailer joins. This is current Scratch inventory, not
a statewide or January-to-date winning-ticket total.

The importer checks unique official website game IDs, matching detail-image game
numbers, game names, ticket prices, top prizes, every published remaining tier,
original-prize bounds, and launch dates. It checks explicit end/claim dates and
excludes past-ended or future-launch games. Single-digit date components, such
as Galactic Cash's November 3, 2025 launch, are parsed without guessing. Current
catalog and detail disagreements stop publication before replacing the last
verified snapshot. There are currently no current-catalog/claim-schedule overlaps.

Three older claim-schedule rows disagree with the site's general 180-day rule:
1845 Lemon Twist Bingo (179 days), 1900 50X Multiplier (165 days), and 1892
Feelin Lucky (179 days). The parser preserves the dates exactly as published and
flags their window mismatch; it does not calculate replacement deadlines. None
is in the current catalog. A current eligible game's conflicting deadline would
stop the import for review.

The catalog is bundled for offline use and added to the recurring feed publisher.
Idaho Cash draw-tier and retailer audits above remain separate and are not
promoted to complete winning-ticket totals or retailer heat rankings by this work.

Validation: 118 Python, 48 Node and 69 Flutter tests passed, plus five HTTP
checks and the macOS debug build. Analysis retained only the 12 existing
informational notices. Regression coverage includes unknown lower-tier counts,
zero remaining prizes, original-prize bounds, duplicate identities, mismatched
catalog/detail inventory, source structure, source cadence, future launches,
inclusive ending dates, and explicit conflicting deadlines. All 25 existing
catalogs remained unchanged. Idaho is ready for local current-catalog testing;
live publication is checked separately from this build.

Live verification September 21: publisher run 35665265146 succeeded. All 32
Idaho games were present in the live combined catalog, which exactly matched
the publisher's repository snapshot. The live activity and retailer feeds also
matched their repository snapshots. Idaho is ready for current-catalog testing;
its broader winning-ticket and retailer-map limitations remain unchanged.

## October 8 official-form requirement and nonresident clarification

The agency acknowledged the September request and requires the official request
form before processing it; the form may be emailed directly to the responding
records contact. No responsive records, fee estimate or delivery date arrived.
The current [official forms page](https://www.idaholottery.com/pages/forms)
links a September 2025 form that includes verification of Idaho residency under
penalty of perjury. The requester cannot automatically make that declaration.

Verified the new thread had no prior reply, then sent a bounded clarification
asking whether a nonresident may leave that declaration blank or should use a
separate form/process. Sent status is confirmed. Electronic delivery and no
fee authorization were reiterated. No residency declaration, signature or form
submission was made. Await guidance; do not resend. Existing technical source
coverage remains unchanged, and Idaho is not activated by this correspondence.

## October 14 nonresident guidance and form submission

The agency confirmed that a nonresident may submit the official form and said
residency affects response timing. It supplied no records, fee estimate or
calendar delivery commitment. The full thread and October 8 Sent clarification
were verified before replying.

Submitted the official editable form with the original request scope attached,
explicitly identifying a nonresident requester. The residency declaration,
signature and signature date remain blank; no human attestation was made.
Electronic delivery and the prohibition on fees or paid work without approval
were retained. Both pages were rendered and inspected; field values and blank
attestation fields were checked after reopening the PDF. Sent status and the
attached PDF size were confirmed in the same thread.

Await processing or records; do not resend. The form and contact details remain
private. This correspondence does not activate Idaho or change public data
coverage, and no delivery deadline is inferred from the general form text.


## October 22 — all-game source-contract audit

Dated APIs were inspected alongside their actual page tables and JavaScript;
see IDAHO_ACCEPTANCE.md for the contract boundaries. Seven game routes returned
JSON; Millionaire For Life's page-derived dated route returned404 while its HTML
still carries results. Pick4 duplicated report labels, undisplayed Powerball base
zeros, and conflicting Powerball historical jackpot values remain explicit gaps
pending bounded parser decisions. No source normalization, invented counts,
public feed promotion or complete coverage claim. Raffle final and promotional
results, InstaPlay and Tabs require separate dispositions. Private source captures
are retained; this technical audit sends no agency correspondence.


October22 product audit: all12 listed InstaPlay and11 Tab detail pages captured.
Their schedules do not establish remaining inventories. Progressive $0 fields
remain unavailable, fractional wagers/prizes retained, TouchTab and fixed Tab
schedules distinguished. Two Sum It Up images visually transcribed with hashes
in tooling/idaho_sum_specs.json. See IDAHO_ACCEPTANCE.md for planned scope and
remaining validation; no public product integration or acceptance yet.


## October 22, 22:27 ET — literal draw schedule contracts

Reviewed and gated all eight captured HTML prize matrices:70 physical rows,
with exact game titles, column headings, ordered match identities, ball-symbol
classes, literal cells and surrounding schedule text. Powerball preserves its
PowerPlay and Double Play columns separately and its conditional10x footnote;
no base schedule is invented. Pick3/4 retain the explicit $1 wager basis and
Idaho Cash retains categorical Free Ticket and quick-pick qualification.
Mega Millions' source heading literally says “Megaplier”; this legacy heading
is preserved as source text, not interpreted as a shared draw multiplier.

All eight retained full-page captures pass the contracts. All35 Idaho Python
tests pass, including removed/duplicated tiers, altered prizes/matches/symbols,
wrong titles/headers, changed qualifications and duplicate matrices. These
contracts cover the tables and their immediate qualifications only; broader
option, sharing, annuity and history rules still require reconciliation before
scope closure. No fresh retrieval, public feed, build, UI or acceptance claimed.
Next finish those rule contracts and product dispositions, then coupled atomic
collection. Original scope/release deadlines remain unchanged.


## October 22, 23:27 ET — draw rule prose contracts

All eight retained game pages now pass strict rule-prose contracts alongside
schedule validation. These retain purchase/option terms, Sum It Up exclusions,
annuity/cash alternatives and sharing/liability qualifications. No new source
retrieval is claimed. All39 Idaho Python tests pass, including changed/removed
prose and wrong-game rejection; presentation styles are excluded from rule text.

Explicit source discrepancies must accompany presentation: Powerball prose says
10x at $150 million or less while its footnote says under $150 million. Pick3
introductory 4-way wording conflicts with its 3-way schedule, and its repeated-
digit examples are inconsistent; never compute matching outcomes from those
examples. Both Pick pages have ambiguous drawing-time wording, so no corrected
cutoff is inferred. XsOs general split-prize language is qualified by the later
lower-tier liability-limit rule. MM's legacy table heading remains subordinate
to its explicit per-ticket multiplier description. These are source limitations,
not permission to silently repair official text or broaden counts.

Scope closure still requires final product/history dispositions and subsequent
strict product collection. No public feed/build/UI or acceptance; scope due
October23 14:22ET and release due October27 14:22ET remain unchanged.


## October 23, 00:29 ET — supported scope reconciliation

The complete product/history/gap matrix is now fixed in IDAHO_ACCEPTANCE.md.
Scope is closed ahead of its October23 14:22ET deadline; release implementation
and acceptance remain open until evidenced. Raffle final and daily promotion
remain separate, all retired-game imports are unavailable, and all current
instant products require strict typed parsing before publication. Retained
October22 captures support this decision; no newer source retrieval is claimed.
Next strict product parsers and coupled atomic collection. No deadline change.


## October 23, 01:34 ET — strict InstaPlay detail schedules

Added reviewed contracts for all12 retained InstaPlay detail pages and110 literal
schedule rows. Exact title, rule text, odds-section qualifications, headers,
ordered counts/prizes/odds and count attributes must match before projection.
Changed details fail closed for review. Printed counts become schedulePrizeCount,
never remaining inventory. All source $0 amounts become unavailable with their
literal source label retained, including all seven $10 Cash Spot rows. No current
progressive jackpot is inferred. Published odds remain literal even where they
appear inconsistent; no recalculation is substituted.

All12 full captured pages validate; all43 Idaho Python tests pass, including
changed/missing rows, altered rules, wrong identity and placeholder semantics.
No new retrieval or public publication. Listing-to-detail completeness, Tab and
Raffle parsing, fresh Scratch and coupled atomic collection remain next; then
app/native integration. Scope remains closed and release October27 14:22ET is
unchanged. This detail-parser checkpoint is not acceptance or a new build.


## October 23, 02:36 ET — strict typed Tab detail schedules

Added exact reviewed contracts for all11 retained Tab detail pages/46 rows.
Nine TouchTab schedules project wager/top-prize amounts in integer cents with
literal overall odds; two fixed schedules project printed prize counts and
amounts separately. Fractional values such as $0.25 wagers and $50.75/$101.75
prizes survive exactly. Neither schedule type creates remaining-prize counts.
Rules and location/day-of-play redemption qualifications remain source text.
Changed headers, rows, identities or rules fail closed for review.

All11 full captured pages validate and all47 Idaho Python tests pass, including
wrong fixed/TouchTab variant, fractional money and malformed schedules. No new
retrieval, public feed or build. Next listing/detail completeness and Raffle,
then fresh strict Scratch and coupled atomic publication, followed by app/native.
Scope closed; release October27 14:22ET unchanged; no acceptance claimed.


## October 23, 03:33 ET — instant catalog completeness joins

Added strict list-to-detail collection for all12 InstaPlay and11 Tab games.
Reviewed listing identities, names, types and prices must match, and grid/detail
links cannot introduce unreviewed games. Each listed detail must validate with
its own typed parser before a complete result returns. Blank official game IDs
remain null; route slugs identify those games without inventing numeric IDs.
Catalog prices are separately labeled from TouchTab's multiple wager options.

Both full retained listings and all23 details pass. All51 Idaho Python tests
pass, including failure at each of23 detail positions, changed listings and
wrong-detail identity. This is an in-memory complete join, not disk publication
or a fresh retrieval. Next Raffle parser, fresh strict Scratch and coupled atomic
retention/publication, then app/native. Scope and October27 14:22ET deadline
unchanged; no new public feed/build/UI or acceptance.


## October 23, 04:38 ET — Raffle schedule and daily promotion parser

Added strict2026 Raffle identity, seven-tier schedule and full two-section rule
contracts. Daily promotion paragraphs are parsed separately: valid source-window
dates, six-digit tickets000001–500000, unique dates and agreement between both
published copies are required. Additional dated promotions can advance without
changing static rules; missing/malformed copies fail closed. Final results remain
unavailable and parsing stops for new review at the December29 announcement
period rather than silently retaining a pending status after it.

Retained October22 page validates with Oct21 promotional012426. Printed top-tier
odds1:225000 and the500000-ticket/two-prize discrepancy remain explicit; final
announcement qualifications and all claim/rule prose are preserved. All55 Idaho
Python tests pass, including promotion progression, leading zeros, copy mismatch,
invalid dates/numbers and changed odds/rules. No fresh retrieval or publication.
Next fresh strict Scratch and coupled atomic collection/retention, then public
feed and app/native. Scope closed; October27 14:22ET release unchanged.


## October 23, 05:34 ET — fresh Scratch source availability change

Fresh official listing now contains33 cards. Mistletoe Mystery (public game1933)
has blank remaining counts in all seven listed $25-plus tiers; its detail shows
*not available for those same tiers and launch date October22. This is not a
future-game exclusion or zero inventory. The existing strict importer correctly
rejected the listing; no public snapshot or source-date advancement occurred.
Raw listing/detail/claim captures and hashes are private under the dated
work/idaho_scope/scratch-refresh directory.

A diagnostic-only replay explicitly removed that one card to investigate the
rest:32 other games/225 inventory tiers validate against fresh details and claim
schedule. The private result is marked nonpublishable and is not a complete
catalog. All56 Idaho Python tests pass, including regression checks that blank
or unavailable high-tier counts cannot become zeros or lower-tier unknowns.

Next add an explicitly typed unavailable-inventory disposition for this game,
with full listing/detail identity and prize-structure validation, before coupled
publication. Do not silently drop it, weaken existing numeric validation or use
stale counts. This is a source availability change, not an extension: scope stays
closed and release October27 14:22ET remains unchanged. No public feed/build/UI
or acceptance is claimed.


## October 23, 06:39 ET — typed unavailable Scratch recovery

Added a separate reviewed unavailable-inventory type for Mistletoe Mystery,
without relaxing the existing numeric importer. Exact listing identity, blank
high-tier rows, detail image identity, price/top badges, all11 prize-structure
rows, launch date and qualifications must agree with the reviewed source.
Remaining counts stay null at every tier; original quantities are structure,
not inventory. Unreviewed blanks, partially changed availability, identity or
status changes fail closed. Numerically reported games retain strict validation.

Complete replay of the fresh October23 captures now retains all33 listed games:
32 numeric inventories/225 tiers plus one explicitly unavailable inventory with
11 structure rows. Private typed-coverage-stage.json is not yet a published feed.
All60 Idaho tests pass, including mixed known-zero/unknown inventories, duplicate
identity and fetch failure. The source-availability parser blocker is resolved;
coupled atomic collection/publication and app/native remain open. No newer
retrieval, source verification date, public feed/build or acceptance claimed.
Release October27 14:22ET unchanged. Next coupled collector and retention tests.


## October 23, 07:42 ET — fresh complete coupled in-memory collection

A fresh85-request official collection passed all supported components together:
22 draw selections with12 exact Idaho reports/10 gaps, eight schedule/rule
pages, both image schedules,12 InstaPlay/11 Tab details with complete listing
joins,33 Scratch listings (32 numeric inventories and one explicitly unavailable)
and the Raffle schedule/rules plus Oct21 daily promotion. Collection started
11:41:13UTC; individual actual retrieval timestamps/hashes are private in
work/idaho_scope/coupled-20261023T114113/manifest.json. Source verification dates
remain unchanged/unknown where not published; request time is not verification.

The new collector returns only after every component validates. Full replay
matches the complete private stage, and controlled failure at each of85 request
positions aborts collection. All63 Idaho Python tests pass. This establishes
complete in-memory collection, not atomic public publication or persisted-cache
retention. Next add correction/regression continuity and atomic disk replacement,
then audited feed/workflow integration and app/native. No public feed/build/UI or
acceptance yet; release October27 14:22ET unchanged.


## October 23, 08:46 ET — continuity and atomic snapshot retention

Added single-file atomic refresh around the complete collector. Existing draw
windows cannot regress; overlapping result/report corrections or loss of known
reports fail closed. Newly available exact-date reports may fill prior gaps.
Scratch identity/status/structure changes require review and known remaining
counts cannot increase. Instant catalogs and rule contracts must remain equal;
Raffle promotion history cannot disappear or change. Unknown-to-known Scratch
status currently requires review rather than silently changing representation.

Unchanged content retains original bytes and collection date. A unique staged
file is flushed before replacement; concurrent snapshot changes abort, and failed
replacement cleans the temporary file. All67 Idaho tests pass, including count/
date corrections, request failure, disk-replace failure and unchanged-byte/date
retention. Full85-request retained-source replay initially writes successfully;
controlled failure at every request preserves the prior complete snapshot bytes.
Evidence is private atomic-replay-checks.json beside the prior coupled capture.

No fresh retrieval, public feed, native build or acceptance. Next audit/export
the coupled baseline and wire scheduled publication, then app/native integration.
Release October27 14:22ET unchanged; scope remains closed.


## October 23, 09:46 ET — audited coupled baseline and publisher wiring

Staged identical public data/idaho_coverage.generated.json and
 docs/idaho_coverage.json from the fully replay-validated October23 11:41:13UTC
collection (223591 bytes each). All85 evidence URLs are public official sources;
no private correspondence, local paths or agency identifiers enter the baseline.
The feed retains all products, unavailable inventory and explicit report gaps.

The scheduled Idaho transaction now invokes the coupled collector and preserves
that single baseline on failure. Workflow staging/commit paths include the new
feed. The old data/idaho_scratch_catalog.generated.json remains byte-for-byte
unchanged with its original date; its numeric-only legacy schema cannot represent
the new unavailable game. It is not refreshed or relabeled as this complete
snapshot. The forthcoming Idaho app integration must use the coupled feed for
current typed coverage. No legacy zero-count substitution or silent game removal.

All476 Python tests pass, including67 Idaho tests and existing transaction tests.
This checkpoint prepares publication; deployment/live-byte confirmation remains
next, followed by Dart loader/UI and native acceptance. No native build or state
acceptance; October27 14:22ET release deadline unchanged.


## October 23, 10:44 ET — coupled deployment verified

Publisher run39964023035 for fac9587 completed successfully. Independently fetched
https://apollohouser-cpu.github.io/lottery_atlas/idaho_coverage.json and compared
all223591 bytes with the audited tracked baseline: exact match, SHA256
adcb110a68d8220120b4cd91b7f2bae48eb9bd974812f1351db339f9980e6642.
This closes initial feed deployment, not mobile acceptance. No source retrieval
date was advanced by checking the hosted copy.

Next implement the Idaho Dart validator/loader with bundled fallback, strict
dated result/report and typed product validation, and cache continuity before
visible UI integration. Do not adopt only the old numeric Scratch feed or turn
unknown inventory into zeros. The remaining work is draw/product presentation,
native traversal and cache recovery/ordinary-build restoration. No new native
build or state acceptance; October27 14:22ET deadline unchanged.


## October 23, 11:46 ET — initial Dart baseline loader

Added the coupled Idaho asset, loader and audited baseline contract. Cache and
bundle fallback preserve typed unavailable inventory, including Mistletoe Mystery;
a rejected or failed remote request does not write over the retained cache.
A valid remote response remains usable if persistence fails.

This is an initial exact-content gate, NOT completed app integration: advancing
source dates/counts currently fail closed. Next replace the baseline restriction
with strict dated result/report and typed product validation plus continuity
before wiring visible screens. No UI or native build changed, and no acceptance
or deadline change. Five Flutter tests pass; the three production Dart files
and test analyze clean. Existing Python publication checks remain unchanged.


## October 23, 12:46 ET — Dart numeric Scratch continuity

The coupled loader now accepts decreasing known Scratch remaining quantities
while preserving reviewed game/tier identities, original quantities, source
metadata and explicit unknown status. Top-prize summaries must match the first
tier. Increased, fractional or negative counts, missing games/tiers, changed
structure and invented source dates fail closed. Continuity compares with the
retained cache, not only the bundled baseline. Eight Flutter tests pass,
including remote adoption and retention against a newer lower-count cache.

Draw/date/report advancement and Raffle promotion advancement still require
their strict dynamic validation before visible UI integration; their current
exact-baseline gate remains. No native build, acceptance or deadline change.


## October 23, 13:46 ET — Dart Raffle promotion validation

Raffle daily promotions now advance independently of the unavailable final
drawing. Validation requires ordered unique real dates within the reviewed
October21–November9 promotion window, no later than the Boise collection
calendar day, and literal six-digit ticket numbers 000001–500000. Existing
promotions cannot disappear or change against either baseline or retained cache.
Rules, schedules, edition, limitations and final-result status remain exact.
Collections entering the December29 final-announcement period require review.

Twelve Flutter tests pass, including synthetic promotion adoption, date/ticket
rejection, Boise midnight boundary and correction/loss cache retention; changed
Dart and test analyze clean. These synthetic tests do not assert a new source
result. Draw/date/report advancement is still exact-baseline gated and remains
next before visible UI. No source refresh, native build, acceptance or deadline
change.
