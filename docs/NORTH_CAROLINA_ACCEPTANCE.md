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
