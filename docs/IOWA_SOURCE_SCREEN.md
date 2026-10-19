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
