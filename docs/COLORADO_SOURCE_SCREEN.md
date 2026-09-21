# Colorado source screen — September 16, 2026

Colorado Lottery publishes several useful official, but differently scoped,
sources:

- [Who's Winning](https://www.coloradolottery.com/en/player-tools/whos-winning/)
  lists selected winners by game, amount, city, store and date, and offers a
  download. This is a winner listing, not an established all-tier count of
  winning tickets sold in Colorado.
- [Winning Stores](https://www.coloradolottery.com/en/player-tools/winning-stores/)
  lists stores with addresses, number of winners sold and amount won for the
  selected game/date range. Its coverage is tied to the site's winner listing;
  do not interpret these stores or counts as a complete retailer ranking.
- [Scratch Insider](https://www.coloradolottery.com/en/player-tools/scratch-insider/)
  lists game number, start date, total top prizes and top prizes remaining.
  [Individual Scratch game pages](https://www.coloradolottery.com/en/games/scratch/game/50x-2922/)
  show prize amounts and printed winning-ticket inventories by tier, while the
  [Scratch catalog](https://www.coloradolottery.com/en/games/scratch/) shows
  current top prizes remaining. Printed inventory and remaining top prizes do
  not establish all-tier claims or validations, and reorders can change a
  game's total printed inventory.

The screened pages did not establish a complete, dated all-tier draw count,
Scratch validations by game and tier, an active statewide retailer master
directory, or a verified join of every winning ticket to its selling retailer.
Colorado is therefore not ready for a complete state total or statewide heat
ranking. The published winner/store subsets can be shown only with their own
game, period, source date and coverage notice. A supported recurring export
and correction cadence also remain to be verified.

## September 21 report pagination repair

Publisher 35641283284 passed the Nebraska repair and then stopped because only
12 Colorado locations matched. The official winner and winning-store reports
now default to 100 rows per page. The importer now uses the published 1,000-row
page-size option and follows official Next links while preserving the source's
`queried_at` snapshot. It rejects changed totals/snapshots, unexpected report
URLs, repeated pages, pagination loops, and incomplete final row counts.

A complete traversal exposed another source limitation: the current Scratch
since-start report advertises 30,644 rows but ends February 22, 2022. Its
180-day option supplies current 2026 records. Scratch imports now use that
published recent report, retaining older previously verified Scratch records
only before the earliest dated record returned in the recent window. Each
retained record carries its original verification timestamp and a visible
historical-snapshot source label. Those timestamps never advance merely because
the publisher runs. This is a combination of verified historical snapshots and
current published subsets, not complete statewide winning-ticket coverage.

The fresh repaired import preserves exactly the same 1,126 activity IDs as the
last verified feed: 228 older Scratch records are retained with historical
provenance, and recent Scratch records start March 25, 2026. No locations were
inferred. Existing count/month validation remains enabled; 6,980 unmatched rows
are excluded. Source responses and comparison output are kept under ignored
`work/colorado_debug/`. Six regression tests cover pagination and historical
provenance. Live publication is pending a successful replacement workflow.

Validation passed 45 Node tests, 107 Python tests, 64 Flutter tests and five
bounded HTTP checks. Analysis reported only the 12 existing informational
notices; the macOS debug build passed. The activity publisher validated 23,157
records across 19 states. This is the current approved-source subset, not an
all-tier statewide total or a new agency data delivery.

Deployment verified September 21: workflow 35648049856 succeeded, and the live
activity feed exactly matched the repository output, including the preserved
historical Scratch labels. New Hampshire's catalog also published successfully
in that run.
