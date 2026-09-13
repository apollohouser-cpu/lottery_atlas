# Oregon source screen — September 12, 2026

Oregon is **not yet approved for the launch heat map**. Keep the existing Oregon
importers and initial catalog; do not add Oregon to the approved activity feed
until the winner-location source gate passes.

- The official retailer API used by `tooling/import_oregon_retailer_directory.mjs`
  returned 3,761 active retailer rows with addresses and published coordinates;
  the importer reported zero unresolved coordinate rows. The response count
  alone does not independently establish that the API returned every active
  retailer statewide.
- The official Scratch-it API used by
  `tooling/import_oregon_scratch_catalog.mjs` returned 55 currently for-sale
  games with price, top prize, and remaining top-prize count.
- The [official winner list](https://www.oregonlottery.org/winners/list/) says
  that its statewide list is currently unavailable. The visible winner stories
  do not constitute a comprehensive retailer-level winner activity feed from
  January 1, 2026 onward. Oregon Lottery's
  [winner-anonymity policy](https://www.oregonlottery.org/winner-anonymity/)
  permits release of the selling retailer, but does not itself supply the
  required historical feed.

Next step: obtain an official comprehensive winner export with game, prize,
win date, selling retailer identifier or exact address, and source provenance.
Confirm that the retailer API response is a complete statewide active roster.
Then normalize and validate the records before enabling Oregon in the app.
