# Iowa source screen — September 12, 2026

Iowa has useful official public data, but **is not ready for the launch heat
map** because the available winner report stops short of the current period
and its retailer entries cannot yet be matched to exact official addresses.
Keep the existing Iowa schedules, source links, historical winner record, and
starter Scratch catalog. The weekly retailer cadence is now permitted with an
explicit disclaimer; it is no longer by itself a reason to defer Iowa.

- The [Iowa Lottery remaining-prizes table](https://ialottery.com/Pages/Games/RemainingPrizes.aspx)
  exposes game, cost, prize, and unclaimed counts. At screening it reported
  data through September 9, 2026, already outside the 24-hour window.
- The [official Iowa Lottery Retailer List](https://data.iowa.gov/catalog/dataset/675)
  describes itself as active licensed retailers, with 2,640 rows and a stated
  **weekly** update frequency. Its displayed last update was September 6,
  2026. A six-hour poll cannot make this weekly source newer; the app must
  describe the directory as weekly data.
- The [Iowa Lottery big-prize winner report](https://ialottery.com/PDF/winnersforwebsite.pdf)
  includes game, prize, selling retailer, and claim date for prizes greater
  than $600, but the available report covered June 30, 2025 through June 30,
  2026 when screened. It omits subsequent months and does not provide a
  up-to-date feed or uniquely identified retailer addresses.

To resume, obtain an up-to-date comprehensive retailer-level winner source
and exact matchable retailer locations. Preserve the actual publication dates
of the directory, Scratch catalog, and winner feed and disclose each source's
cadence separately. Winner records must be matchable without heuristic joins.

## September 20 remaining-prize and game-status audit

The official report now states **remaining prizes through end of day September
18, 2026**. All 513 published rows were parsed and validated: 368 Scratch tier
rows across 71 games, 137 InstaPlay tier rows across 24 games, and eight PullTab
rows across eight games. Game type remains explicit; the collections must not
be merged into a Scratch catalog. Each row has a game number, consistent game
name/price, a prize amount of at least $50, and nonnegative integer claimed and
unclaimed counts. Duplicate prize amounts within a game are rejected.

The report expressly covers **prizes of $50 or more**. Its cumulative claimed
column is not a January-to-date claim history and must not become an all-tier
winning-ticket total. Preserve the actual September 18 source date separately
from retrieval. This dated snapshot can be useful despite its publication lag;
the earlier screen's 24-hour observation is not a standalone exclusion rule.

All 71 Scratch game detail pages were checked at their official
`Pages/Games-Scratch/ScratchGamesDetail.aspx?g=GAME_NUMBER` routes. Each advertised
top prize matches the highest tier in the report. Each publishes a start date;
none of these 71 currently prints an End Distribution, Official Game End or
Last Day To Redeem Prizes date. These fields are distinct and must be retained
separately when present, never inferred from one another. As an excluded-game
example, [Beat The Heat (712)](https://www.ialottery.com/Pages/Games-Scratch/ScratchGamesDetail.aspx?g=712)
prints an End Distribution date of May 5, 2026, with the other two dates blank;
it does not appear among the audited 71 report games.

The dated bundled catalog has 67 games. Five of the 71 current report IDs are
new to that snapshot. The next import should replace the scoped report catalog,
not append new rows indefinitely or carry missing games forward as current.
No store availability or winner-location evidence is inferred from these pages.
A formal source update cadence still needs confirmation.

The downloaded report, 71 detail pages, SHA-256 provenance, normalized audit and
status reconciliation are retained under `work/iowa_catalog/`. The audit scripts
validate table identity, game type, numerical counts, unique tiers, detail dates
and top-prize agreement. No public feed or application code changed in this run.
Next step: turn the validated extraction into a tested importer, retain the
$50 threshold and cumulative inventory notes in the app, and publish the fresh
catalog after normal checks. Iowa case #26-4068 remains pending; no new agency
reply arrived. Iowa is not yet ready for retailer heat-map testing.

## September 20 tested importer and fresh catalog

`tooling/import_iowa_scratch_catalog.py` now performs a fresh report retrieval,
validates the exact source date and table schema, selects Scratch rows by their
explicit game type, and verifies every game's advertised top prize and separate
date fields against its official detail page. Six regression tests cover
highest-tier counts, cross-type exclusion, malformed/duplicate counts, distinct
end dates, top-prize mismatches and missing source metadata.

The fresh import validated 71 Scratch games with the report's actual source
date of **September 18, 2026**. The generated catalog and refreshed bundled
snapshot preserve all 368 published $50-plus tier rows, cumulative claimed and
unclaimed measures, and a visible scope/date note. No all-tier or 2026 claim
total is inferred. A game remains a record in this dated report even if a later
detail page lists an end or redemption date; those dates are shown explicitly,
not interpreted as evidence of current store inventory.

The six-hour publisher now checks Iowa and includes validated output in the
combined catalog feed. All detail pages must pass before the output is replaced;
source/schema failures preserve the previous file and stop the publishing run.
The poll cadence is distinct from the source's unconfirmed publication cadence.
Catalog readiness is reported after live deployment verification. Iowa remains
incomplete for retailer-linked winner coverage under request #26-4068.

## October 18, 21:42 ET — sole active state activation

Iowa is now the sole active state under IOWA_ACCEPTANCE.md: scope due October19 21:42ET, supported release due October23 21:42ET, fresh120-hour substantial integration budget. Existing retailer heat-map gaps remain explicit; they do not block supported results and inventory without joins.

Fresh home and six official HTML pages are private in work/iowa_scope with URL/retrieval/hash provenance. Home exposes PB/Double Play, MM, Lotto America, MFL, XsOs, Pick3/Pick4 midday-evening, Scratch, InstaPlay and Pull-Tabs. A legacy Lucky for Life image needs historical-status resolution. Public results are server-rendered with ASP.NET search controls; Pick3MPrizes.aspx, Pick3Prizes.aspx and PowerballPrizes.aspx are observed report links to inspect next. Date/session/variant/geographic units and all product options remain unclosed. No public output changed.

## October 18, 22:47 ET — actual report and session audit

Captured all home-linked draw family/detail/result pages plus nine linked prize-report routes privately with retrieval/hash provenance in work/iowa_scope. Seven home-linked InstaPlay detail pages are samples, not a complete inventory. Actual result/report content is server-rendered HTML; no separate API is required or assumed at this stage.

Powerball, Mega Millions, Lotto America, Millionaire for Life and Xs & Os prize pages explicitly describe winners for tickets purchased in Iowa. Preserve that source label rather than unique people/paid claims. Powerball has distinct Regular and Double Play report tables. Latest PB/MM/Lotto America report jackpot fields contain $0 while earlier dated rows have positive amounts: treat these as unresolved missing/placeholder jackpot data, never a zero-dollar advertised prize. MM includes obsolete historical headers/structures and blank modern MP cells; select the correct dated structure and do not invent a draw-wide built-in multiplier.

Pick 3 and Pick 4 midday winning-number pages already show October 18, but their prize reports currently end October 17. Join only exact dates plus sessions; do not attach October17 counts to October18 numbers or mark absent reports as zero. These report pages do not provide the same explicit geographic/unit description seen on the multi-state pages; retain a count-unit validation gate before integration. Pick4 leading zeros are literal digits. Pick3 reports have nine wager columns and Pick4 fifteen, including distinct straight/box exact/any combinations; do not collapse or sum overlapping categories.

Xs & Os dated results contain eight image sources (e.g. ARI.png and DEN.png) with positional alt text, not team names. A reviewed official mapping is needed; never interpret positional labels as teams. Its last visible result is October11 while other games are newer; no common latest date is imposed. Number pages and report pages have different history windows. Retain raw calendar dates and explicit session, without fabricating UTC timestamps.

Next close the remaining full scope: exact literal schedules/options, Lucky for Life retirement/history, complete instant-product dispositions/current dated inventory, official retailer/winner/claim/club routes; then strict bounded parser and date/variant/unit tests. No public feed/build/UI/Gmail or acceptance change; original deadlines remain.

## October 18, 23:44 ET — historical status and fresh inventory audit

The official [Lucky for Life results page](https://www.ialottery.com/Pages/Games-Online/LuckyForLifeWin.aspx) explicitly identifies February21,2026 as the final drawing and August20 as its final claim deadline. Keep it historical only; the legacy home image is not a current product. Raw HTML and provenance retained privately.

Fresh existing strict importer run against the October17 source report validated 50 Scratch games and all266 published $50-plus rows, including each official detail page's top prize and separate status dates. Output is private work/iowa_scope/fresh-scratch-catalog.json, not published. The same raw report contains25 InstaPlay games/142 rows and8 PullTab games/8 rows; these counts are a private table inventory, not accepted product collectors. Each type remains separate, thresholded and cumulative. Source publication date remains distinct from retrieval; low-tier completeness, claims and store stock are not implied.

Most current prize schedules are image assets, not HTML tables. Captured seven official chart assets with URL/hash provenance. Direct visual review transcribed Pick3's nine and Pick4's fifteen literal rows into private reviewed-pick-schedules.json, preserving all six wager columns ($0.50,$1,$2,$3,$4,$5), printed odds and N/A straight/box half-dollar cells. These are prize schedules, never actual winner counts. Other family chart transcription and strict tests remain open; MFL also has separate annuity/cash sharing tables. The existing source-page labels alone cannot substitute for these physical schedules.

The intended bounded result scope is two latest completed results per group: PB Regular/Double Play, MM, Lotto America, MFL, XsOs, Pick3 midday/evening and Pick4 midday/evening (ten groups/seven families). Counts require exact date/session/variant correspondence and proven source units; missing or unresolved reports remain explicit gaps. Final scope closure still requires remaining instant-product and official-route dispositions plus schedule/source contracts. No build, public feed, UI, acceptance or deadline change.

## October 19, 00:46 ET — supported scope closed early

Scope is closed before October19 21:42ET. Implementation and acceptance remain open; release deadline stays October23 21:42ET, no extension.

| Product or feature | Supported release contract and boundary |
| --- | --- |
| Powerball / Double Play | Two latest completed dates per variant, exact dated Iowa-ticket report joins; Power Play literal schedule separate from Double Play. No inferred missing jackpot or unique-person counts. |
| Mega Millions | Two latest completed dates and exact dated Iowa-ticket reports; current built-in per-play multiplier chart, historical structures excluded from current payouts. |
| Lotto America | Two latest completed dates/reports plus All Star Bonus literal schedule and source qualifications. |
| Millionaire for Life | Two latest completed dates/reports; literal annuity amounts, sharing/cash-option tables and qualifications retained. |
| Powerball Xs & Os | Two latest completed dates with eight reviewed team identities and dated Iowa reports; source team mapping validation required before publication. |
| Pick3 / Pick4 | Two dates in each midday/evening session, literal digits including zeros; all wager/straight-box/pair schedules and combinations. Unproven count units remain explicit unavailable report counts; no zero substitution or cross-date pairing. |
| Scratch | Full dated $50-plus inventory report subset, all published rows, status dates, search/filter/detail/source return. Fresh private baseline50games266rows sourceOctober17. Below-$50 counts and store inventory unavailable, official detail route retained. |
| InstaPlay / PullTabs | Separate typed dated $50-plus report inventories planned (private baseline25games142rows and8games8rows), with official game routes. Never merge with Scratch. Detail-level odds/progressive jackpots remain official-source routes rather than inferred dated draw reports or stock. |
| Lucky for Life | Historical-only official route; finalFebruary21 drawing and finalclaimAugust20. No current/next draw. |
| History | Bounded two-result selections; official historical search remains accessible. No ten-year completeness or automatically focused external date claim. |
| Retailers / selected winners | Official lottery navigation and existing weekly directory route; no unaudited directory import, coordinates or heuristic retailer joins. Selected-winner news is not comprehensive claims. |
| VIP Club / promotions / mobile / claiming | Official information routes only; no account entry, purchase, ticket validation, claim submission or attestation. |

Public GET report routes and result tables are already captured; date controls are ASP.NET forms. Expected draw contract is20results/sevenfamilies/ten groups. Calendar dates are literal source dates with session identity, not invented midnight UTC events. Publish only validated complete source units; source failures retain prior bytes/dates.

All eight image schedules now visually reviewed and transcribed into tooling/iowa_schedule_specs.json (74 physical rows, exact printed prize strings and rounded odds). Each records its image hash; a changed chart must fail closed pending review. Pick3nine/Pick4fifteen rows preserve all six wager columns and N/A cells. PB/DP/MM/LA/MFL/XsOs charts preserve different options and annuity semantics. Lotto America image odds have different rounding from the HTML report: retain source-specific values. Separate HTML footnotes, sharing tables and combinations still require collector extraction and tests; this scope closure does not claim implementation complete.

Official route captures include [InstaPlay](https://www.ialottery.com/Pages/Games-Instaplay/Instaplay.aspx), [PullTabs](https://www.ialottery.com/Pages/Games-Pulltab/PulltabGamesListing.aspx), [claiming](https://ialottery.com/pages/games/claimingprizes.aspx), [VIP rules](https://www.ialottery.com/Pages/VIPClub/VIPClubRules.aspx) and [selected winners](https://www.ialottery.com/Pages/Pressroom/Winners_Main_Dynamic.aspx). Raw pages/hashes remain private. Next implement strict bounded result/report parsers and image-hash/schedule validation, then coupled atomic inventory/draw collection, app and native acceptance. No public feed or native build changed.

## October 19, 01:48 ET — strict numeric parser and chart gates

Implemented tooling/iowa_draw_results.py for nine numeric groups/18 bounded results, with source table/variant identity (including duplicate Powerball table IDs), literal Pick sessions/zeros, valid ordered unique dates, game-specific ball ranges, no duplicate main balls and allowed multipliers. All visible rows are validated before taking the latest two. Only the exact empty source footer is excluded. XsOs remains deliberately unsupported pending reviewed team mapping; this does not satisfy the final20-result contract. No winner counts, jackpots or invented timestamps are produced.

Actual linked winning-number pages PowerballWin.aspx, LottoAmericaWin.aspx and MillionaireForLifeWin.aspx were captured separately from their interactive Check pages. All nine captured numeric groups parse successfully. tooling/iowa_schedules.py accepts the eight reviewed charts only on exact hash agreement and returns independent literal rows; any changed image fails closed for review. All eight captured hashes verified. Thirteen regression tests pass, covering malformed ranges/dates/digits/multipliers, ambiguity, mixed variants, full-table validation and chart-change rejection.

Next reviewed XsOs team mapping and exact dated report parsing, plus HTML schedule qualifications/sharing/combinations. Coupled atomic collector, typed instant inventories, public feed/app/native remain open. No public feed/build/UI/acceptance/deadline change.

## October 19, 02:46 ET — exact dated report parser

Implemented tooling/iowa_draw_reports.py for six source-qualified report groups: Powerball, Double Play, Mega Millions, Lotto America, Millionaire for Life and XsOs. Parser requires the explicit Iowa-ticket qualifier and exact physical header contract, validates every visible date/count/option field, and rejects duplicate/out-of-order/future dates or changed schema. Current MM deliberately selects Rules rather than obsolete Rules2; nonblank modern shared-Megaplier values fail closed.

Source $0 jackpot text is preserved with null advertisedJackpotDollars and an explicit placeholder limitation. It never becomes a zero-dollar prize. Count labels remain source winners for Iowa-purchased tickets, not unique people or paid claims. Exact date+group joins reject mismatched variants/multipliers; absent dates produce an unavailable report rather than zero counts. Unproven Pick3/Pick4 count units remain excluded.

All six captured source groups passed (13/13/9/13/30/4 visible dated rows respectively); these are validation windows, not a public history expansion. Twenty-one combined Iowa numeric/schedule/report tests pass, including malformed counts/money, geography/schema changes, placeholder semantics and cross-date/variant protections. Next XsOs image-to-team validation, HTML qualifications/sharing/combinations and atomic collector with typed inventories. No public feed, native build, UI or acceptance change; deadline unchanged.

## October 19, 03:46 ET — bounded XsOs source-code results

Added tooling/iowa_team_results.py. XsOs output preserves official image filename abbreviations and image URLs as source team codes; it does not turn generic positional alt text into team names or guess expanded names. Parser requires the exact result-table identity/header, eight distinct allowed source codes at the expected official relative image paths, positional alt sequence, ordered unique valid dates, and the exact empty footer. Unknown/duplicate/external-path/missing image identities fail closed. Expanded-name presentation remains unclaimed; the app must label these as source abbreviations unless separately reviewed.

All four captured source rows validate, yielding the two bounded selections for October11 and October4. Combined private captured-source staging now produces20results/ten groups/seven families,12 exact joined source-qualified reports, and eight explicit Pick count-unit gaps. This is private parsed-draw-report-stage.json, not a deployed feed or an atomic live collector. Twenty-five combined parser/chart/report/team regression tests pass.

Next HTML schedule footnotes, annuity sharing and Pick combinations extraction/validation, then atomic live collector and separate typed instant inventories. Existing image hash gates remain required. No public feed/build/UI/acceptance or deadline change.

## October 19, 04:47 ET — HTML annuity and combination contracts

Added strict reviewed HTML schedule contracts for Millionaire for Life and both Pick combination pages. MFL preserves both physical sharing/cash-option tables (three top-prize rows and two tier-2 rows), minimum annuity and 20-year qualifications, Section 6.C. reference, 60-day election and equal-sharing limitation. Pick3 preserves all five combination examples and Pick4 all seven, including exact/any order, repeated-number cases and front/back pairs. Literal text and table cells are retained, not calculated payouts or winner counts.

The parser isolates the single primary-content container and compares normalized headings, paragraphs and table cells against reviewed source contracts. Changed/missing qualifications, table values, game identity or duplicate containers fail closed; harmless whitespace/inline markup is normalized. All three captured pages validate. Thirty combined Iowa regression tests pass, including changed cash/sharing terms, missing text, altered combinations and wrong-game rejection.

Remaining other-family HTML footnotes still require extraction before the atomic live collector. Typed instant inventories, public feed, app/native and acceptance remain open. No public feed/build/UI or deadline change.

## October 19, 05:45 ET — remaining draw HTML qualifications

Extended the reviewed HTML contracts to Powerball (including the distinct Double Play section), Mega Millions, Lotto America, XsOs and Pick3/Pick4 rules. Nested source rule containers are explicitly recognized; Pick play-type lists are preserved. All nine captured HTML contracts now validate, alongside the separately required eight image hash gates. Preserved qualifications include Power Play exclusion from Double Play, the 10X eligibility limit, MM per-play random multipliers and pari-mutuel conditions, All Star Bonus jackpot exclusion, XsOs cash-only/random-draw limitations, and both Pick session cutoffs/90-day claiming text. These are literal source rules, not additional dated counts or inferred prize calculations. Shared Powerball page content must remain visibly separated from Double Play in the app.

Thirty-three combined Iowa tests pass. Added regressions reject changed option applicability, multiplier semantics, cash/annuity terms, claim periods/cutoffs, removed Pick lists and unknown nested rule-container identities. No public feed/build/UI/acceptance or deadline change. Next atomic live draw collection with all result/report/chart/HTML contracts, then typed instant inventories and app/native integration.

## October 19, 06:49 ET — atomic live draw staging

Added collect_iowa_draws.py, a private atomic collector spanning 31 deduplicated public source requests: all numeric/XsOs results, six qualified dated report groups, eight exact-hash image charts and nine reviewed HTML rule pages. It derives the validation calendar in America/Chicago from an aware retrieval timestamp. Fresh live collection retrieved October19 10:48:30UTC passed:20 bounded results/ten groups,12 exact joined reports and eight explicit Pick count gaps, eight charts and nine rule pages. Private output is work/iowa_scope/collection-stage.json; this is not a public feed or app release.

Source bytes have per-URL SHA256 provenance. All parsing completes before a same-directory temporary write/fsync/atomic replacement. Retained date/group/time regressions and overlapping dated result/report corrections fail closed for review; changed schedules require review. Thirty-nine combined Iowa tests pass, including every one of the31 request failures preserving previous bytes, parser failures, replace failure/temporary cleanup, correction/regression rejection, Chicago calendar handling and normal successful refresh. Captured-source collection also passed before the live run.

Next separate typed Scratch/InstaPlay/PullTab inventories and coupled publication, then app/native integration. No public feed/build/UI/acceptance or deadline change.

## October 19, 07:47 ET — separate typed instant inventories

Added strict all-row parsing for separate Scratch, InstaPlay and PullTab $50-plus cumulative claimed/unclaimed report subsets. Identity is product type plus game ID; repeated IDs across products cannot merge. Every source row is validated, with unknown products, malformed counts/prices, duplicate tiers, conflicting identities, changed columns, missing subsets and future source dates rejected. No report maximum is promoted to a progressive jackpot or advertised top prize. Below-$50 tiers, store stock and dated claims remain explicitly unavailable. Existing Scratch detail/status verification remains separate and unchanged.

Fresh public report retains source date October17 but now lists50Scratch/266rows,25InstaPlay/142rows and9PullTab/9rows. Newly observed PullTab WHAT A GEM! (4) adds one literal $1,999 row; prior private capture had8PullTabs. This is a same-source-date inventory change, not evidence of a new verification date. Private typed-inventory-stage.json retains all three subsets. Forty-nine Iowa tests pass, including existing Scratch tests and four new typed-inventory regressions.

Next couple typed inventory and validated draw collection with source-date/correction retention, then publish/integrate app/native. No public feed/build/UI/acceptance or deadline change.

## October 19, 08:51 ET — coupled coverage staging

Implemented collect_iowa_coverage.py: one atomic snapshot couples the strict draw collection, all three typed instant inventories and the existing verified Scratch detail/status catalog. The same fetched report bytes feed both inventory parsers; all50 Scratch details must validate and their identities/tiers must exactly match the typed Scratch subset before replacement. Draw staging remains private until the complete snapshot succeeds. Source date regressions, same-date inventory/detail corrections, disappearing identities/tiers and reversed cumulative counts fail closed for review.

Fresh live staging retrieved12:51:07UTC passed82 deduplicated public requests:20 bounded draw results,50 verified Scratch games and84 typed games total (50Scratch/25InstaPlay/9PullTab). Report source date remainsOctober17. Per-source hashes are included in private work/iowa_scope/coupled-stage.json. Fifty-three Iowa tests pass; new transaction tests verify a detail failure after successful draw collection cannot expose partial updates, replace failures preserve bytes and remove staging files, source-date/tier mismatches reject the snapshot, and normal dated progression remains possible.

Next public snapshot/workflow integration and app presentation/loaders, then native acceptance. No public feed/build/UI/acceptance or deadline change; Iowa remains sole active.

## October 19, 09:55 ET — public baseline and scheduled transaction wiring

Staged the validated coupled schema1 Iowa baseline in data/iowa_coverage.generated.json and docs/iowa_coverage.json. It contains only audited public-source results, schedules, typed inventories and source provenance; no private agency records or retailer joins. Added a verified Scratch projection exporter, preserving the prior retrieval timestamp when the legacy Scratch catalog is unchanged. Scheduled Iowa refresh now couples both generated outputs under the existing state rollback transaction; a collector or projection failure retains both previous files and dates. The publishing workflow stages and tracks the new public snapshot.

Fifty-five Iowa tests and13 state-transaction tests pass. Projection tests cover unchanged timestamp preservation and mismatched source/tier rejection. Deployment/live-byte confirmation remains next, followed by app integration and native checks. No new native build or acceptance; deadline unchanged.

## October 19, 10:55 ET — deployment failure corrected and live baseline verified

Publisher39264423117 failed in Python tests: Ubuntu's standard-library test package shadowed the repository namespace used by one new Iowa test fixture import. No source validator or production data failed. Removed that cross-test namespace dependency in44a1af1; all412 local Python tests pass, and recovery run39273203615 validate-and-build passed. The public iowa_coverage.json now matches the tracked baseline byte-for-byte. Existing published accepted-state data was retained during the failed run.

Deployment/live baseline verification is closed. Next Iowa Dart loader/presentation integration and native acceptance. No native build or acceptance change; deadline unchanged.

## October 19, 11:53 ET — initial Dart coverage loader

Added the bundled Iowa snapshot and an injectable persistent loader with exact source-rule/chart contracts, ten result groups/two dates, numeric domains/Pick zeros, XsOs source-code identities, date/report joins, source-qualified counts and zero-jackpot-placeholder checks. Failure or malformed remote data retains the validated cache; newer retrieval of valid unchanged contents persists. Cold-start timezone initialization is explicit. Four Flutter tests pass and all three new production Dart files analyze cleanly.

This is an initial loader checkpoint, not completed app integration. Instant inventories currently require the reviewed baseline exactly, conservatively retaining it on changes; implement full dated inventory validation/continuity before UI rollout. Visible draw/typed-inventory presentation, complete regression matrix and native checks remain open. No new native build/acceptance or deadline change.

## October 19, 12:55 ET — dated inventory validation in Dart

Replaced the temporary exact-baseline inventory restriction with typed schema/date/count validation and retained-snapshot continuity. Scratch/InstaPlay/PullTab identities remain separate; duplicate IDs within a type, missing product subsets, invalid tiers/counts, changed official routes and future source dates reject. Scratch detail projection must exactly match typed tiers and identities, with verified top-prize values, status date ordering and literal inventory limitations. No InstaPlay report maximum is interpreted as a progressive jackpot.

Newer source-date inventory progression can validate; same-date corrections, source-date regression, identity/tier loss and reversed cumulative counts fail closed. Seven Flutter tests pass, including dated progression, product boundaries, malformed data, same-date/reversed-count rejection and existing loader retention/adoption. Changed production Dart files analyze cleanly. Next visible draw and typed inventory screens/integration, then native tests. No new native build/acceptance or deadline change.

## October 19, 13:57 ET — visible Iowa draw integration

Added Iowa results/schedules entry on the state source screen using the validated coupled loader. The sheet offers all20 bounded selections across ten groups, preserves Pick digits and literal XsOs abbreviations, source-qualified report counts or explicit gaps, placeholder-jackpot limitations and all74 image-chart rows. HTML rule paragraphs, annuity tables and Pick combinations are displayed as individually readable fields, with external source buttons. Double Play uses its own chart/report and explicitly labels the following shared Powerball source-page rules; regular jackpot/Power Play/annuity terms are not described as Double Play prizes.

Nine Iowa Flutter tests pass, including all20 selections at2x text and traversal to the Double Play shared-page warning. A chart-note string/list rendering mismatch found by tests was corrected before commit. New sheet analyzes cleanly. Typed instant inventory UI and native all-selection/source-return/layout/cache-retention acceptance remain next; no new native build/acceptance or deadline change.

## October 19, 14:56 ET — typed inventory UI and ordinary iOS build

Integrated separate Scratch/InstaPlay/PullTab inventory selection, name/number search, price filter/reset, literal cumulative claimed/unclaimed tier details and official source links. Scratch details preserve status dates and source notes; other products explicitly exclude full schedules/current progressive jackpots. Report source date stays October17. Search/detail return preserves the filter in widget tests.

Eleven Iowa Flutter tests pass, including all three product inventories at2x text and a PullTab search/detail/return/reset flow. Both Iowa sheets and the state source screen analyze cleanly. Ordinary main.dart iOS debug7dda240 built, installed and launched on the original iPhone17e simulator (process40813); no temporary probe used. Android remains stopped. Successful launch is not native visual acceptance: all native selection/date/source returns, long schedules, filters/details/layouts and production-loader failure/ordinary restoration checks remain open. No acceptance/deadline change.

## October 19, 17:05 ET — UTF-8 name correction and native recovery

Fixed both report parsers to decode official UTF-8 bytes strictly before HTML
parsing. Reviewed five exact name corrections against captured source bytes:
Scratch693/773 and InstaPlay172/177/178. Updated only those names in the coupled
baseline, Scratch projection and Dart contract; counts, dates, retrieval times
and source hashes are unchanged. The Dart decoder migrates only those exact
legacy spellings for those product/ID pairs before full validation. Same-date
count corrections, other identity changes and all continuity checks still reject.

56 Iowa Python tests and12 Flutter tests pass (the initial Flutter invocation
included a nonexistent inventory test filename; corrected-path inventory tests
passed). Changed Dart analyzes cleanly. Release04f8ef3 pushed; publisher39324356638
succeeded and live coupled JSON matches corrected bytes. Ordinary iOS rebuilt,
installed and cold-launched with existing cache retained. Native Scratch list and
detail show SCRABBLE™ and UNO™ correctly. SCRABBLE official detail URL with game693
opened in Safari; OS return retained detail and literal tiers. No probe used.

Encoding defect is closed. Remaining native source returns for draw families,
long schedules, inventory price/reset/product-source flows, layouts, newer remote
adoption and controlled production-loader request-failure retention remain open.
Iowa not accepted; release deadline unchanged. Ordinary app is on Scratch693 detail,
Android stopped. Private correction audit: work/iowa_scope/encoding-correction.json.

## October 19, 18:12 ET — native draw source returns

Verified native header source buttons for all ten groups, including separate
Pick midday/evening routes and Powerball/Double Play shared winning-number page.
Safari address editing exposed the exact official Win.aspx URL in each case;
OS return retained the selected group/date. This is source navigation, not an
automatically focused date query. Powerball return also retained partial scroll.
Scratch $1 filter showed5of50 games; Reset restored All prices and50of50.

Long rules remain open: only partial Powerball chart traversal occurred. Native
wheel scrolling did not advance this view; bounded touch drags advanced it.
Do not infer complete schedule traversal from widget tests or partial output.
Remaining product-source flows, layout variants, newer remote adoption and
controlled production-loader failure retention/restoration still require checks.
No code/build/acceptance/deadline change. Ordinary iOS04f8ef3 is at Pick4 Evening
summary; Android stopped. Private evidence: work/iowa_scope/native-source-returns.json.

## October 19, 19:14 ET — inventory short-height layout

Native landscape inspection of ordinary iOS04f8ef3 showed the inventory controls
consuming almost the entire sheet height, leaving the games below the viewport.
Moved inventory controls and game rows into one scrollable list so controls can
scroll away on short screens. Added a real844×390,2x-text widget regression that
scrolls to WHAT A GEM!, opens details, and checks for layout exceptions. All13
Iowa Flutter tests pass; changed production Dart analyzes cleanly.

Long-rule traversal is still open: Pick4 Evening was only partly traversed;
native scroll/drag attempts were inconsistent. AX nodes outside the visible
viewport are not evidence of completed visual traversal. Landscape draw heading
and selection were readable, but this does not close all layout checks.
Remaining native product-source flows, long schedules, enlarged-text/layout
verification, newer remote adoption and controlled request-failure retention
remain open. No acceptance or deadline change. No source data changed.

Release38bcc62 pushed after clean rebase over scheduled feed241026d. Ordinary
main.dart iOS build succeeded, installed, and cold-launched (PID55792); native
home map appeared. No probe or source-data mutation. Simulator remains landscape;
Android stopped. The updated inventory's native scrolling still needs verification;
widget coverage and successful launch do not close that gate. Build log is private
work/iowa_scope/landscape-ios-build.log.

## October 19, 20:12 ET — native production-loader request failure

A private native target used the production IowaCoverageLoader with only its
fetchRemote callback replaced by a controlled SocketException. It loaded the
existing real SharedPreferences cache, returned the fully validated cached
coverage, and left the persisted string byte-identical. Independent host-side
comparison also matched the pre-run bytes (SHA256
 da13440f6b13976b67cefd68b1f4448ca11d1ad1d3daab13bac50a74dd6a2aa7).
This closes the controlled request-failure retention check, not device-offline
behavior. The cached retrieval date remains2026-10-19T12:51:07.209463+00:00;
no newer-source verification or date was invented. Evidence is private
work/iowa_scope/native-failure-retention.json.

The private target displayed the actual inventory widget at2x text in landscape;
heading and controls were readable. Scroll gestures still did not reliably
advance the Simulator, so full layout/long-rule traversal is not claimed.
Newer remote adoption, long schedules, remaining product-source returns and
integrated layout acceptance remain open. Iowa is not accepted; deadline unchanged.
The tracked main.dart was never modified; private target is excluded from Git.

Ordinary lib/main.dart rebuilt successfully, installed and cold-launched after
the private target (PID59799); native home map verified. Simulator remains
landscape, Android stopped. Restore log:
work/iowa_scope/retention-ordinary-restore.log. No probe is tracked or installed.

## October 19, 21:10 ET — refresh isolated for official source corrections

A fresh coupled collection for the pending newer-remote adoption check failed
closed on dated-result/report continuity. The staged retained snapshot remains
byte-identical to the published baseline; no date was advanced or partial update
published. Fresh private draw-only review identified four changed retained rows:
Pick3 midday October18 changed2-3-7 to2-8-7; PB October17 jackpot placeholder became
$586,400,000; MM October16 became$403,000,000; LA October17 became$2,250,000.
Those three report tier counts did not change. Original captured Pick3MWin HTML
contains2-3-7; freshly fetched official same-route HTML contains2-8-7 for the exact
same date. Neither value is inferred. The published baseline still contains the
older values and must not be described as current for these four rows.

Review evidence is private work/iowa_scope/adoption-correction-review.json and
pick3-midday-correction-20261019.html. Next review and implement a narrowly bounded
correction migration in collector/app continuity, with regressions, before new
publication/adoption. Do not weaken general continuity or change the deadline.
Iowa remains unaccepted. User notified of this source change and refresh isolation.

Separately, native PullTab WHAT A GEM! official product link opened exact route
https://www.ialottery.com/Pages/Games-Pulltab/PulltabGamesListing.aspx ; Safari
address verified and OS return retained game4 detail and its literal tiers.
Simulator now upright in that ordinary detail; Android stopped. Other native
long-rule/layout/source/adoption gates remain open; request-failure gate stays closed.

## October 19, 22:12 ET — reviewed corrections and refreshed coupled snapshot

Reviewed fresh literal official prize-report rows for PB October17 ($586,400,000),
MM October16 ($403,000,000), LA October17 ($2,250,000), and the Pick3 midday
October18 correction to2-8-7. Added an exact before/after full-row allowlist in
Python collector and Dart continuity. Only those four forward transitions pass;
reverse changes, extra count/digit changes and every unlisted correction still
fail closed. Cached old records are not silently relabeled with newer source dates.

A fresh complete coupled collection then passed:20results/10groups and84typedgames
(50Scratch/266tiers,25InstaPlay/142tiers,9PullTab/9tiers), now official inventory
sourceOctober18, retrieved2026-10-20T02:08:48.247238+00:00. Scratch detail verification
and typed projection passed together. Updated coupled data/docs and Scratch
projection; no private agency material included.57Iowa Python and14Flutter tests
pass; changed production Dart analyzes cleanly. Regression dates now derive from
fixture dates rather than expiring fixed timestamps. Deployment/livebytes and
ordinary native newer-adoption verification remain next; Iowa not accepted,
release deadline unchanged. Prior native failure-retention gate remains closed.

Correction release7eeec8b pushed; publisher39357467529 observed in progress.
Ordinary main.dart iOS build succeeded, installed/cold-launched (PID67179), home
map verified upright. Existing native cache retained for the next real remote
adoption check. No probe. Build log: work/iowa_scope/reviewed-correction-ios-build.log.
Deployment/livebytes and native adoption are not yet claimed.

## October 19, 23:16 ET — live correction recovery and native adoption verified

Public iowa_coverage.json is byte-identical to the current published repository
snapshot. Ordinary iOS 7eeec8b adopted that real newer remote snapshot with the
existing cache retained: retrieved 2026-10-20T02:08:48.247238+00:00. Native draw
presentation showed Powerball October17 jackpot $586,400,000 and Pick3 midday
October18 numbers 2 · 8 · 7 with the explicit unavailable-count qualification.
Read-only host inspection confirmed the persisted iowa_coverage_v1 cache is
byte-identical to the live feed (SHA256
bdbcb8a0cf480b29b6af1c90a2a1c7192b56d55b60d55218c06896a1870a51dc).
Private evidence: work/iowa_scope/correction-native-adoption.json and preserved
live/cache bytes. No injected response, cache rewrite, or probe was used.

Deployment recovery and real newer-remote adoption gates are closed. The prior
controlled request-failure retention gate remains closed. Remaining native
long-schedule, enlarged/landscape and outstanding instant source-return flows
still require verification; Iowa is not accepted. Release deadline remains
October23 at21:42ET, with no extension. Ordinary app remains upright on the
corrected Pick3 midday result; Android remains stopped.
