# North Carolina supported-coverage acceptance — active

Activated **October 8, 2026 at 10:38 ET** as the sole active state after Missouri.
Scope/gap matrix due **October 9 at 10:38 ET**; supported release decision due
**October 13 at 10:38 ET** (120 hours). No extension used. North Carolina is not
accepted. Mobile beta platform work continues independently.

## Selection and opening evidence

Chosen for its existing scheduled high-prize winner importer, dedicated Scratch
UI and official retailer-directory parser. These reduce startup work but do not
constitute an accepted full supported experience. Broader catalog/report/product
integration and validation are substantial, so this is a fresh 120-hour window.
The committed winner snapshot carries October 7 source/retrieval dates and says
17,983 matching claims; that is existing importer metadata, not an independently
revalidated distinct-ticket count or approved complete retailer join. Audit
collision handling, matching, source dates and news/archive overlap before
extending or promoting the feed. The bundled Scratch snapshot is dated August 25.

Fresh October 8 official home and remaining-prize HTML were captured privately
with the existing importer's HTTP user agent. The browser fetch returned 403,
while curl succeeded; no authentication or access control was bypassed. Home
navigation includes Powerball, Mega Millions, Cash 5, Pick 3, Pick 4, Cash Pop,
Millionaire for Life, Powerball Xs & Os, Keno, Scratch-Offs, Fast Play, Digital
Instants, promotions and rewards. This is an opening inventory, not scope closure.

The current [remaining-prize page](https://nclottery.com/scratch-off-prizes-remaining)
states that its counts are not-yet-claimed prizes through October 7, updated daily,
and that Reordered status increases the prize count. Do not subtract snapshots
into new claim counts or interpret remaining prizes as retailer stock. Capture
literal tier/price/status/date definitions and reconcile listing/detail identity.
Private captures: work/north_carolina_scope/{home,scratch}.html.

## Acceptance gates

- [x] Full current product/game/option/history scope and explicit gaps (October 8, 11:39 ET).
- [x] Winner-source date/unit/overlap and retailer-join audit (October 9; bounded archive rows only, news/shared prizes/ambiguous joins excluded).
- [x] Strict current Scratch catalog and available draw-report imports (83 listed games; 28 bounded reports, eight families/14 groups).
- [x] Validated directory coverage and coordinates, or explicit supported limits (official positions retained; structural guards, all repeated name/city keys excluded; no independent geocode certification).
- [x] Atomic refresh, regression/failure preservation and public byte verification (first scheduled three-output publication verified October 9).
- [ ] App source routes, catalog/reports/directory with honest coverage labels.
- [ ] Compact/wide native use, source-return and request-failure recovery.
- [ ] Consolidated checks and supported release decision.

Missing broader agency records do not block honest supported-app completion.
No new correspondence, fees, human attestations or private attachment promotion
occurred at activation. Existing request history remains in NORTH_CAROLINA_SOURCE_SCREEN.md.

## Supported scope closed October 8, 11:39 ET

Fourteen official product/directory pages plus Pick 3 and Pick 4 dated detail
pages were captured privately. Scope is closed ahead of October 9; implementation
and validation gates remain open. Source content embedded in cross-game footer
cards must never be parsed as the selected game's main report.

| Product | Supported implementation target | Limits / separate gaps |
| --- | --- | --- |
| Powerball | Dated NC tier reports, separate base/Power Play and Double Play | Preserve literal jackpot labels; no complete claims or retail positions from tiers |
| Mega Millions | Dated NC tier report with each printed multiplier column | Do not flatten concatenated HTML values or silently relabel the source's Megaplier heading |
| Cash 5 | Separate base and Double Play dated prize/win tables | Rollover is an advertised estimate, not a payout to a winner |
| Millionaire for Life | Dated NC nine-tier report | Preserve annual-for-life labels, no inferred cash conversion |
| Powerball Xs & Os | Dated NC five-tier payout report | Shared jackpot and potential pari-mutuel limits stay visible |
| Pick 3 / Pick 4 | Daytime and Evening identities, dated combined winner/payout summary and literal base/Fireball payout schedule | Sample detail pages provide combined winners, not winner counts per payout row. Never synthesize those missing counts or distinct-ticket totals |
| Cash Pop | Five named daily sessions with date, Pop, source winners and payout | Aggregate session rows only unless a verified tier source is found; animated drawing link is not a claim record |
| Scratch-Offs | Refreshable literal listed-game/tier catalog with source date and Reordered status | Original printing vs remaining; no subtraction into claims or stock, no invented end dates |
| Retailers / mapped activity | Strict directory audit and bounded high-prize archive/news activity | Audit duplicate retailer candidates and news/archive overlap; unmatched/ambiguous locations stay excluded, no inferred coordinates |
| Keno | Official game/results route and explicit available coverage | Four-minute draw results are not a complete winner-count history; options require source-labeled treatment |
| Fast Play | Official current product/catalog/jackpot routes and explicit gap | Progressive advertisement is not an actual per-ticket payout or claim total |
| Digital Instants | Official product route and clear unsupported claim coverage | No account access, gameplay or gambling transactions; no inventory-to-claims inference |
| Promotions / rewards / second chance | Official routes and separate coverage limits | No participation, personal-account data or synthetic winning-ticket totals |
| Historical/replaced games | Explicit historical gap and official historical routes where available | Ten-year history remains later; current navigation is not proof of historic completeness |

Report target is two bounded recent reports per eight current draw families and
14 game/session groups where the official history supports it. Pick 3/4 and Cash
Pop summaries are deliberately different from tier-count reports. The October 7
Evening detail examples print Pick 3 combined 1,527 winners / $227,915 and Pick 4
893 / $261,622; these are private source observations, not promoted app totals.
No new public feed, native acceptance, correspondence or deadline change.

## October 8 directory collision audit (12:40 ET)

Fresh official directory capture contains 7,528 rows and 7,494 normalized
name/city keys. Twenty-eight keys contain 62 rows. The existing archive matcher
silently kept the last branch for repeated keys; 107 activities in the retained
snapshot have one of those ambiguous keys. Those positions are not validated
joins. Counts describe this audit, not a newly accepted statewide directory.

The importer now excludes every repeated normalized name/city key from archive
matching, including third occurrences and identical duplicates. Three focused
Node tests cover uniqueness, order independence and normalization collisions.
The raw directory and collision details remain private in
work/north_carolina_scope/directory-audit.json. No public snapshot was regenerated
or promoted during this audit; previously published positions remain pending
correction through the validated refresh pipeline. News fuzzy matching and the
global date-based archive/news overlap heuristic still require separate repair
or exclusion before NC acceptance. NC remains unaccepted and the October 13
10:38 ET release deadline is unchanged.

## October 8 mapped-activity correction (13:45 ET)

Excluded 107 archive records with ambiguous name/city branches and both existing
news records from the retained NC snapshot, leaving 17,874 records. These are
retained source records, not a new distinct-ticket total or full fresh import.
All surviving records and source dates are unchanged. The public activity
publisher validated 23,937 records; 35 excluded records were within its 2026
window. All non-NC activity remains unchanged.

Removed news supplementation from the importer: fuzzy branch scoring and a
publication-date cutoff do not establish identity or prevent archive overlap.
News remains an official source route, with no mapped-record promotion. Four
Node tests now run under the existing CI test glob, including an importer fixture
that excludes ambiguous branches, rejects any news request and preserves the
output bytes on request failure. Private before/removed evidence is retained in
work/north_carolina_scope. This fixes the known joins without claiming the
remaining pagination, date/unit, directory or full NC acceptance audits are done.
Publication verification follows the correction commit; push alone is not proof.

Correction deployment verified: release `d892565`, publisher run `37818483881`
completed successfully. The public activity.json bytes match the locally
validated corrected file exactly (private checksum evidence recorded). Known
ambiguous archive records and unverified news records are absent from the public
feed. This closes the correction publication checkpoint, not NC acceptance or a
native remote-adoption check. No simulator/user-review state was changed.

## October 8 strict Scratch importer (14:42 ET)

Implemented a separate literal catalog parser and atomic importer. A fresh
private fetch validated 83 listed games / 896 prize tiers across $1, $2, $3, $5,
$10, $20, $30 and $50 price groups, with source date October 7. Source labels,
printed odds, total/remaining counts, game status and official detail links are
retained. No subtraction into claims, cash-option inference or retailer stock.

Four focused Python tests pass, including malformed columns/counts/dates/URLs,
duplicate identity, request-failure byte preservation, unchanged-date reuse,
source-date regression, identity/tier changes, future dates and literal reorder
increases. The importer rejects unexpectedly small catalogs and material drops.
Private snapshot: work/north_carolina_scope/scratch-catalog.json. This is parser
validation only: no public catalog promotion, scheduled refresh wiring, app
loader/UI replacement or NC acceptance yet. Next integrate the catalog schema
and strict draw reports; existing static NC UI is still the older snapshot.
Release deadline remains October 13 at 10:38 ET. No simulator or Gmail changes.

## October 8 bundled literal catalog and Flutter loader (15:45 ET)

Added the validated 83-game / 896-tier October 7 source-date catalog as an app
asset, plus a dedicated strict cache/remote/bundle loader. Validation retains
literal prize/odds/status/definition fields and rejects malformed counts, dates,
URLs, duplicate games/tiers, identity/tier changes and material catalog drops.
Cold-cache remote responses are checked against the reviewed bundle. Failed
requests or invalid remote responses retain the prior validated snapshot and
its dates; valid remote data survives a cache-write failure. Reorder increases
remain literal inventory changes, never calculated claims.

Four Flutter tests pass, including eleven remote-defect variants, offline
fallback, cold-cache continuity, reorder changes and persistence failure.
Two-file analysis is clean. No full build, simulator interruption or native
acceptance was performed. The new loader is not yet connected to the existing
NC Scratch UI; remote endpoint staging and scheduled transaction remain pending.
No refreshed public catalog endpoint or user-visible replacement is claimed.
Next connect the literal UI and validate compact/wide behavior, then implement
strict draw reports and refresh publication. NC deadline remains unchanged.

## October 8 literal Scratch inventory UI (16:45 ET)

The NC Scratch menu now opens the dated 83-game catalog with name/number search,
ticket-price filter, game selection and all literal prize/printed-odds/total/
remaining rows. Source date, retrieval time, reorder definitions, coverage limits
and official game/list routes remain visible. Existing favorite-game keys are
preserved, and map-context selection explicitly filters retained high-prize
claims; inventory counts do not create map positions. Removed the old static
remaining-prize list from the desktop NC panel. Both the compact map Scratch
action and state source screen reach the new inventory sheet.

Three widget tests pass: all 83 selections render and reach the footer at
390×844 and 1400×1000, plus search/price empty-result recovery. Four-file analysis
has only the existing live-map line 288 informational brace notice. No full
build, simulator navigation, native/source-return acceptance or remote endpoint
publication was claimed. Scheduled catalog integration and draw reports remain
pending; October 13 release deadline unchanged. User simulator review untouched.

## October 8 Cash Pop report parser (17:45 ET)

Implemented strict Cash Pop aggregate-session parsing with all five official
session names and printed times. Fresh official history validates two latest
reports per session (ten reports, October 6–8). Morning Buzz October 8 prints
633 winners / $21,908; October 7 prints 741 / $30,259. These remain private
source observations, not promoted app totals. Each report preserves the Pop,
source winner count, payout label and exact payout cents; no tier counts,
distinct-person totals, retailer joins or map locations are fabricated.

Four Python tests pass: bounded latest selection from unsorted rows, malformed
fields/dates/counts/columns/session times, duplicates/missing sessions, zero and
fractional payout handling. Every supplied history row is validated before
selecting the recent window. Unrelated odds/promotion tables are excluded by the
specific history structure. Private capture/results are under
work/north_carolina_scope/cash-pop-fresh.html and cash-pop-reports.json.
Remaining seven draw families, combined atomic refresh and app report UI are
still pending. No public report output, native verification, Gmail or deadline
change; North Carolina remains unaccepted.

### October 8, 18:46 ET — Pick 3/4 combined summaries parsed privately

The strict draw parser now reads Pick 3 and Pick 4 dated combined summaries,
with official Daytime/Evening identities, ordered digits (including leading
zero), Fireball digit, literal summary text and exact payout cents. It validates
source route/game, complete document, unique fields, weekday/date, session,
digit count/range and winner/payout consistency before selecting two reports
per session. Duplicate identities and missing session coverage fail closed.

Eight fresh private detail captures yielded eight reports: Daytime October 8/7
and Evening October 7/6 for both games. October 8 Daytime prints Pick 3
408 winners / $65,425 and Pick 4 148 winners / $51,444. These remain combined
source summaries, with no inferred base/Fireball split or tier winner counts.
All eight draw-parser tests passed (four Cash Pop plus four Pick summary tests).

This is parser evidence only: literal base/Fireball payout schedule extraction,
five other draw families, atomic publication, report UI and native acceptance
remain pending. No public report feed was published. Release deadline remains
October 13 at 10:38 ET; North Carolina is not accepted.

### October 8, 19:46 ET — Pick payout schedules retained literally

The Pick report path now requires both the base and Fireball payout schedules
in addition to the combined summary. Explicit rowspans are expanded within each
source table body, preserving match labels, both wager columns, combo play-cost
labels, N/A cells and Fireball qualifications. The parser rejects missing rows,
changed captions/headers/play groups, invalid spans and malformed payout labels;
it does not turn schedule rows into observed winner counts or paid totals.

All eight previously captured dated reports validate with 16 schedules and 128
schedule rows. Results remain private in
`work/north_carolina_scope/pick-reports-with-schedules.json`; the validation time
is distinct from source retrieval time. Eleven draw-parser tests pass, including
rowspan alignment, separated combination digits, malformed old/unselected
schedules and source qualification retention. Changed source layouts fail
closed pending review rather than being guessed.

Five other draw families, combined atomic refresh/publication, report UI and
native acceptance remain pending. No public report feed or acceptance claim;
October 13 at 10:38 ET release deadline unchanged. The user's current simulator
review was not interrupted.

### October 8, 20:47 ET — Cash 5 base and Double Play parser

Implemented strict dated Cash 5 reports containing separate base and Double
Play numbers and prize-distribution tables. Fresh detail URLs selected from the
official history validate October 7 and October 6: two reports, four variant
tables and sixteen tier rows. Source route/date/weekday, logo identity, table
headers, ordered tier labels, unique 1–43 numbers and nonnegative printed Wins
are checked. Missing or mismatched fields fail closed before recent selection.
The official how-to-play page confirms the 1–43 range for both variants.

October 7 base five-of-five is labeled $171,000* with zero Wins and a rollover /
advertised-jackpot-estimate footnote; October 6 is $142,000*, also zero. Both
Double Play tables print $50,000 with zero top-tier Wins. Literal labels and
footnotes are retained without deriving amounts paid or distinct people.
Private captures/results are under `work/north_carolina_scope/cash5-*`.

Fifteen draw-parser tests pass, including four Cash 5 tests for variant identity,
malformed dates/tiers/units/rollover, duplicate and insufficient reports, table
swaps and validation of old rows before bounding. Four other draw families,
atomic refresh/publication, report UI and native verification remain pending.
No public report feed, simulator changes or acceptance claim; deadline unchanged.

### October 8, 21:46 ET — Millionaire for Life dated reports

Added strict Millionaire for Life parsing for the nine North Carolina tiers.
Two fresh dated details (October 7/6) validate against the requested source date,
weekday, five unique 1–58 numbers and Millionaire Ball 1–5. Official how-to-play
text confirms those ranges. Match identities use the source's explicit
accessibility labels rather than counting decorative ball glyphs. Column and
field alignment, tier completeness and nonnegative Wins are validated.

Both annual-for-life prize labels and the North Carolina-only qualification are
retained literally, without cash conversion or paid-total calculation. Both
captures report zero Wins in the top two tiers. Private captures/results are
`work/north_carolina_scope/mfl-*` and `millionaire-reports.json`. Eighteen parser
tests pass, including three new tests covering annuity/scope retention, malformed
source rejection and complete validation before latest-two selection.

Powerball, Mega Millions and Xs and Os remain, followed by atomic refresh,
publication, report UI and native acceptance. No public report output or mobile
restart; North Carolina remains unaccepted with its existing release deadline.

### October 8, 22:46 ET — Powerball Xs and Os report parser

Two fresh official dated details, October 4 and September 27, validate five
tiers each. The parser checks requested and printed dates, weekday, eight
unique team labels, explicit match identities, table/field alignment and
nonnegative integer Wins. Literal prizes and the complete North Carolina-only,
shared-jackpot and possible pari-mutuel qualification are retained. Top Match 8
prints $1,220,000 and $1,000,000 respectively, both with zero Wins; neither
label is treated as an amount paid. Private output is
`work/north_carolina_scope/xo-reports.json`.

Twenty-one draw-parser tests pass, including three Xs and Os cases covering
source qualifications, malformed source rejection and complete validation
before recent selection. Powerball and Mega Millions are the remaining report
families; combined atomic refresh/publication, report UI and native acceptance
still follow. No public report feed, mobile interruption or acceptance claim.
Release deadline remains October 13 at 10:38 ET.

### October 8, 23:47 ET — Powerball variants parsed privately

Two fresh dated Powerball details (October 7/5) validate separate base, Power
Play and Double Play data: 9 / 8 / 9 tier entries per report. No separate Power
Play jackpot winner count is manufactured. Requested/base/Double Play dates,
weekday, numbers, explicit fields, displayed match symbols, columns, scope and
nonnegative Wins are checked. Prize labels remain literal without paid-total or
cash-option conversion. Twenty-four draw-parser tests pass.

Both source pages have a specific Double Play labeling inconsistency: the row
showing four white balls without a Powerball has accessibility label `4+PB`.
The parser verifies the displayed symbols and the exact row fields, preserves
both labels, and emits a source warning. Other disagreements fail closed. This
warning must remain visible in the report UI; counts are not moved between rows.
The fixture captures only public draw fields/tables, not private correspondence.

Private results are `work/north_carolina_scope/powerball-reports.json`. Mega
Millions is the remaining parser family. Combined refresh/publication, report
UI, archive/directory audit and native acceptance remain pending. No public
report promotion or simulator interruption; release deadline unchanged.

### October 9, 00:46 ET — Mega Millions parser; eight families covered privately

Fresh October 6/2 details validate 41 entries each: one jackpot plus five
printed multiplier entries for each of eight lower tiers. The parser preserves
the source heading Megaplier and X10/X5/X4/X3/X2 labels, checking line-by-line
prize/Wins alignment. Empty or missing middle values cannot shift a multiplier's
counts into another column. Jackpot multiplier stays absent, not invented.

Both pages display one white ball plus Mega Ball on the row whose accessibility
label says `2`. As with the Powerball discrepancy, visual identity and exact
fields are validated independently; both identities and an explicit warning
are retained. The report UI must display this warning. Unknown disagreements
fail closed. No amounts paid, cash options or distinct-person totals are derived.

All eight scoped families now have private parser evidence, totaling 28 bounded
reports across 14 game/session groups. Twenty-seven draw-parser tests pass.
Private results are `work/north_carolina_scope/mega-reports.json`; this is not
an integrated feed or acceptance. Next: combined atomic refresh/schema,
publication, app report loader/UI, remaining archive/directory audit and native
acceptance. Deadline remains October 13 at 10:38 ET; simulator review untouched.

### October 9, 01:47 ET — Atomic report collection refresh

Added an executable report importer that fetches official histories and bounded
details for all eight families, then validates exactly two reports in each of
14 game/session groups before replacing its output. A fresh private network run
produced 28 reports, dated September 27–October 8. History date spaces and
duplicate links are normalized; invalid detail routes and incomplete histories
fail closed. Pick histories use a bounded eight-detail window to find both
sessions. Every fetched detail passes its strict family parser.

The collection rejects duplicate identities, missing groups and regression of
either date in a previously saved group. Unchanged content retains its prior
bytes/timestamp. Late fetch or validation failure leaves the saved output
untouched; replacement uses a temporary file. Three new refresh tests plus all
existing NC Python tests pass (34 total, including four Scratch tests).
Source warnings remain attached to Powerball/Mega Millions reports.

Private result: `work/north_carolina_scope/draw-reports.json`. Schema version 1
is now defined for the report collection; this does not yet register an app
asset or public endpoint. Next: shared scheduled staging with the catalog,
Flutter report validation/loader/UI, publication and native verification, plus
remaining archive/directory audit. Deadline unchanged; North Carolina is not
accepted. User simulator review was not interrupted.

### October 9, 02:48 ET — Three-output scheduled transaction wired

The North Carolina refresh job now owns the retained winner-activity snapshot,
literal Scratch catalog and bounded draw reports together. Failure at any of
its three importers restores all three prior files and dates. A new test injects
failure at each step and verifies exact restoration; all ten transaction tests
and all 34 NC Python tests pass. The validated 28-report private collection is
now a tracked baseline, retaining all four Powerball/Mega Millions source warnings.

Publication wiring stages separate NC catalog/report endpoints and includes both
generated and public files in the bot commit. This does not merge reports into
map activity or invent retailer positions. Live publication verification remains
pending at this checkpoint, as do the first scheduled three-output refresh,
Flutter report loader/UI, archive/directory audit and native acceptance.
North Carolina is not accepted; October 13 at 10:38 ET remains the deadline.

Publication verification: publisher 37895408995 succeeded for d36879a. Both
public NC draw-report and Scratch-catalog endpoints independently match the
validated baseline bytes exactly. This closes initial endpoint publication only;
it does not establish a successful scheduled refresh or native remote adoption.
The app report loader/UI and remaining acceptance gates are still pending.

### October 9, 03:49 ET — App report loader and validation

Registered the 28-report bundle and added a cache/remote/bundle loader. App-side
validation checks all 14 groups, dates and official routes, variant and tier
identities, numeric ranges, multiplier order, literal payouts versus exact cents,
Pick digits/schedule structure and retained source qualifications. Known PB/MM
label disagreements require nonempty source warnings; unknown label mismatches
fail. Both dates in each group and the retrieval timestamp cannot regress.
Invalid responses retain the cached/bundled data without rewriting its dates.
A storage-write failure does not discard an otherwise valid response.

Five focused Flutter tests pass, including eleven malformed payload variants,
group-date regression, cold-bundle continuity and cache failure preservation.
Both new service files analyze cleanly. Report UI wiring and warning display are
still pending; no full build, native adoption or acceptance is claimed. The
simulator review remains untouched and the release deadline is unchanged.

### October 9, 04:49 ET — Bounded report UI connected

The North Carolina source page now opens all 28 reports across eight families
and 14 groups. Each selectable report retains its draw date/session, retrieval
time, source coverage and official report link. Base/Power Play/Double Play
remain separate; Mega Millions retains printed multipliers; Pick 3/4 retain
combined summaries and both literal payout schedules, including wager labels,
N/A, combo costs and Fireball qualifications. Cash Pop remains a session summary.
PB/MM source warnings appear before prize rows and both conflicting labels are
visible in affected rows. Annual-for-life and advertised prizes stay literal.

Three widget tests pass: all 28 selections at 390×844 and 1400×1000, footer
reachability, and warning retention plus scroll reset when selection changes.
The new sheet and source page analyze cleanly. This is automated UI evidence,
not a full build, native source-return check or native remote adoption. Remaining
archive/directory audit, scheduled-refresh evidence and integrated acceptance
remain open. Deadline unchanged; user simulator review remains untouched.

### October 9, 05:51 ET — Archive pagination and claim-date audit

The official archive labels the date Claimed, covers prizes of $5,000 and up,
and says it updates weekly; listed prize values can differ from net claim
payments. A date-only noon-UTC transport value is not a draw or claim time.

Fixed pagination to inspect unfiltered source dates and explicit next-page
links rather than ending on an empty retailer-filtered page. Every page must
identify the requested page, have distinct winner links and matching valid
claim dates; dates must descend across pages. Repeated IDs, invalid calendar
dates, unexpected next routes, empty/error pages and exhaustion of the 160-page
safety bound now fail closed. The year boundary is applied only after checking
all page dates. Unmatched locations cannot silently truncate later pages.

Six Node tests pass, including traversal past an unmatched first page and saved
output preservation on failure. A fresh private full import succeeds with
17,874 records and 26 unmatched retailer names. Its activity rows and both
source date fields exactly match the retained public baseline; no new mapped
records or date changes are promoted. Full archive row-format/shared-prize unit
audit and integrated native acceptance remain open; deadline unchanged.

### October 9, 06:51 ET — Archive row accounting and shared-prize exclusions

The importer now accounts for every linked winner row before location filtering.
Unknown row markup, malformed prize notation, unsafe numeric amounts or prizes
below the archive's stated $5,000 threshold fail validation rather than silently
dropping a row. Literal shared-prize asterisks (plain or superscript) are parsed
explicitly and excluded from mapped records; a shared amount is not converted
into one independently won prize. Winner names are not exported.

Seven Node tests pass, including malformed-row rejection and explicit exclusion
of a shared-prize row even when its retailer matches. A fresh private full run
again produces 17,874 records/26 unmatched retailer names, with every activity
and both source-date fields identical to the retained baseline. No changed
public rows or dates are promoted. Each retained row represents a published
archive claim record, not certified unique tickets or people; listed amounts
are not verified net payments. Native acceptance and final directory-coordinate
validation remain pending. Deadline unchanged; simulator review untouched.

### October 9, 07:51 ET — Official directory structure and position guards

The official directory parser now validates every eight-field row, required
name/address/city/county text, ZIP format and finite coordinates inside a broad
North Carolina envelope. Coordinates remain verbatim from the official source;
this is a malformed/swapped-position guard, not independent street-address or
boundary certification. Invalid rows stop the import instead of being discarded
before collision detection, which could otherwise make another branch appear
to match uniquely. All repeated name/city keys remain unavailable.

The retained official capture has 7,528 eight-field rows, no missing required
text and no points outside the broad envelope. Eight Node tests pass, including
six malformed branch variants, duplicated branches and exact coordinate
preservation. A fresh private full import succeeds with 17,874 mapped archive
records and 26 unmatched names; every activity and both source dates match the
retained baseline exactly. No records, positions or dates are changed publicly.

This closes the structural directory guard work. Remaining integrated gates
include scheduled three-output evidence, native report/catalog interaction,
source-return and retained-data behavior. No native acceptance or simulator
interruption; October 13 at 10:38 ET remains the release deadline.

### October 9, 08:52 ET — Current iOS simulator build prepared

The ordinary iOS simulator debug build at 5b2de04 succeeds (Xcode phase 11.3s),
including the NC catalog, report bundle/loader/UI and source warnings. Output is
`build/ios/iphonesimulator/Runner.app`; the build log remains private under
`work/north_carolina_scope/ios-build-current.log`. PNY is mounted and build output
uses the existing external path; internal free space was 16 GiB before the build.

The build was not installed or launched: the user's running 1b201c5 review is
unchanged. No native report/catalog/source-return or remote-adoption pass is
claimed. Do not repeat this compile without code/data changes; use this artifact
for the pending native checks when the review allows. Latest observed scheduled
run 37892273793 predates three-output wiring; its success does not close that
checkpoint. NC remains unaccepted with the same October 13 deadline.

### October 9, 09:54 ET — First scheduled three-output publication verified

Scheduled publisher 37936115049 (13:20:15 UTC, code b406a61) completed
successfully and produced bot commit f5bf544. The NC status is `updated` and
lists all three transaction outputs. Archive activity and its dates remain
unchanged at 17,874 records; the Scratch catalog still has 83 games/896 tiers,
now through October 8, retrieved 13:27:25.588809 UTC. The 28 reports span
September 27–October 9, retrieved 13:27:25.720389 UTC, retaining all four
Powerball/Mega Millions source warnings.

Public report, catalog, refresh-status and combined activity bytes each match
the committed output exactly. Private hashes and downloaded bytes are under
`work/north_carolina_scope/scheduled-37936115049`. This closes the scheduled
transaction/publication checkpoint, not native remote adoption.

The new data exposed two tests tied to the old catalog date. They now verify
that the displayed date follows the supplied catalog and that offline loading
retains the entire supplied bundle. All 15 report/catalog loader and widget
tests pass across the targeted runs. No product code changed. The prepared
08:52 build remains useful for verifying newer remote adoption against its
older bundle; no rebuild or simulator interruption occurred. Native flows,
source-return, retained-data behavior and supported-release acceptance remain
open; the October 13 at 10:38 ET deadline is unchanged.
