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
