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
- [ ] Winner-source date/unit/overlap and retailer-join audit.
- [ ] Strict current Scratch catalog and available draw-report imports.
- [ ] Validated directory coverage and coordinates, or explicit supported limits.
- [ ] Atomic refresh, regression/failure preservation and public byte verification.
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
