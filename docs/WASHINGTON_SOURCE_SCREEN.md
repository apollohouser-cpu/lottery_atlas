# Washington source screen — September 15, 2026

Washington's Lottery publishes an unusually detailed [Scratch prizes report](https://www.walottery.com/Scratch/TopPrizesRemaining.aspx).
For each current game and prize tier it shows total prizes, prizes paid and
prizes remaining, with a page update timestamp. The pages reviewed September
15 had September 14 source timestamps. These figures can support a current
active-game Scratch snapshot and paid-prize count, but they are cumulative
inventory measures rather than an August-only claim history and contain no
selling-retailer join. Closed games also require separate treatment before any
statewide all-game total is claimed.

The official [unclaimed top-prizes page](https://www.walottery.com/winningnumbers/unclaimedtopprizes.aspx)
provides selected draw-game prize, drawing-date and city information, while
press releases sometimes identify exact selling retailers for large wins.
These are useful verified subsets but do not establish every draw-game winning
ticket or a complete retailer heat map.

The Lottery's official [contact page](https://walottery.com/Contact/) names its
Public Records Coordinator, Public Records Officer and records-request form. A
focused Washington Public Records Act request was emailed September 15 to the
published coordinator address. It requests existing August 1–31, 2026 all-tier
draw and Scratch records, a complete active-retailer directory, winning-ticket
retailer joins, definitions, cadence and corrections. Gmail confirmed “Message
sent.” Requester contact information was supplied directly and is not stored in
this repository.

On September 17, public records coordinator Tiffany Pringle confirmed receipt
of the September 15 request, forwarded it to the IS Department, and estimated
a response by **October 15, 2026**. She will forward an earlier response or
advise if more time is needed. This acknowledgment contains no data yet.

The existing bundled Washington Scratch catalog is a dated August 30 snapshot.
The detailed official report is a candidate for a six-hour importer, but
Washington is not ready for map testing until exact current retailer records
and qualifying winner joins are available. Any Scratch view must continue to
show its source date and cumulative paid/remaining scope.

## September 19 full price-category audit

All seven price-category links exposed by the official report were retrieved
($1, $2, $3, $5, $10, $20 and $30). The pages share the printed source timestamp
**9/19/2026 12:30:07 AM**; the page does not state its timezone. There are
**57 unique game IDs and 606 prize tiers**. Every tier contains nonnegative
integer counts and reconciles `total prizes = prizes paid + prizes remaining`.
This is complete coverage of those seven published report pages, not proof of
all historical games or 2026 winning-ticket counts. The report includes 26
games with a last redemption date, so it must not be labeled an exclusively
active-for-sale catalog.

The source audit and exact downloaded HTML pages are retained locally under
`work/washington_scratch/`; `audit.py` discovers the category links and validates
unique IDs and all tier reconciliations, and `audit.json` retains source URLs,
printed timestamps, SHA-256 checksums, redemption dates and exact prize labels.
No new Washington counts or locations have entered the public feeds.

The audit identified corrections needed in the existing August 30 catalog:

- Game 1780's top tier is `$40,000/yr/25 years`. The stored value `4000025`
  incorrectly concatenates digits from the annuity label. Preserve the exact
  label and handle any numeric amount explicitly; do not strip non-digits.
- Game 1942's top tier is `LIFE`, above a $1,000 cash tier.
- Game 2004's top tier is `BRONCO`, above a $25,000 cash tier.

The latter two records currently omit the special prize label and need their
remaining-prize counts tied to the correctly identified top tier. Refresh all
fields under a new source date rather than combining current counts with the
old snapshot date. The existing model supports `topPrizeLabel`; amount filters
use a separately defined cash amount. Confirm the game details for lifetime
and vehicle terms before choosing fuller display labels. The next implementation
step is a tested Washington importer that preserves these special labels,
redemption status and report scope, then replaces the dated catalog through
the normal feed publisher. Washington is still not ready for retailer heat-map
testing.

The Lottery's [Scratch disclaimers](https://www.walottery.com/Scratch/Disclaimers.aspx)
explain that closing games can retain unclaimed prizes and that actual prize
availability depends on printing, testing, distribution, sales and claims.
Inventory arithmetic alone does not establish a dated claim history or store
availability. The October 15 agency response estimate remains pending; no new
reply was received during this check.

## September 19 catalog implementation

`tooling/import_washington_scratch_catalog.py` now validates and imports all
seven report categories. Five regression tests cover annuity parsing, special
prize counts, malformed inventory, missing categories, mixed timestamps and
cross-category duplicates. The generated catalog and refreshed bundled snapshot
contain 57 games and all 606 tier inventories with the September 19 source date.
Game 1780 preserves `$40,000/yr/25 years` and uses the explicit $1,000,000
nominal annuity total for amount filtering. LIFE and BRONCO retain their exact
published labels; their numeric amount filter uses the highest separately
listed cash tier, not an invented valuation. Remaining counts refer to each
advertised top tier. The three corrected counts are respectively 0, 1 and 2.

Each game carries a visible source-date/availability note and any published
redemption deadline. The model preserves these notes when caching. The workflow
checks Washington every six hours and includes its catalog in the combined live
feed; it refuses an incomplete or internally inconsistent replacement. Output
`updatedAt` records retrieval/change time, separately from the printed source
timestamp and date (whose timezone remains unstated). Closing games are retained
with their deadline rather than treated as proof of current sales. This is a
catalog refresh only; no Washington winner totals or retailer heat points are
created. Deployment validation is recorded in the task status.
