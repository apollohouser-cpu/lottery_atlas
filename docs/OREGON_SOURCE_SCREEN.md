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

On September 13, 2026, a data inquiry was sent to
`publicaffairs.lottery@lottery.oregon.gov`, the contact listed on the
[Lottery's official legal page](https://www.oregonlottery.org/about/legal/).
It asks for existing draw and Scratch-it winning-ticket/claim counts,
retailer-linked winner records, count definitions, refresh cadence, and
confirmation of retailer API completeness. Gmail confirmed “Message sent.”
The [official records request form](https://www.oregonlottery.org/public-information/request-form/)
is available if the Lottery routes the inquiry to that process. This request
does not change the current source gate.

Update September 16: Jessica Nelson, Oregon Lottery Records Management
Consultant, replied that the Lottery does not offer API data access and
directed this inquiry to its [official public-records form](https://www.oregonlottery.org/public-information/request-form/).
That statement concerns requested data access; the already observed public
retailer and Scratch-it endpoints still require their own provenance and
completeness checks. The formal 2026 year-to-date request was submitted on
September 16 through the linked Wufoo form. The confirmation said “Public
Records Request received.” It asks for existing all-tier draw and Scratch-it
counts, retailer roster and selling-retailer joins, with a recent-month sample
accepted only as a first format check. No fees were authorized. Responsive
records and a repeatable update route remain pending.

An Oregon Lottery confirmation email also arrived at 7:26 p.m. ET September
16 and explicitly confirmed receipt of the public-records request.

## September 20 catalog refresh

The official public Scratch-it API returned 467 records and `NextItems: 0`;
51 records fall within their published availability dates as of retrieval.
`tooling/import_oregon_scratch_catalog.mjs` now validates pagination, unique game
numbers, calendar dates, positive integer prices/prizes and nonnegative integer
unclaimed top-prize counts. Missing counts are rejected rather than coerced to
zero. Ended and future games are excluded, and redemption deadlines are retained
where published. Five regression tests cover source semantics, date boundaries,
unknown versus zero counts, duplicate/truncated responses and redemption dates.

The [official Scratch-it list](https://www.oregonlottery.org/scratch-its/list/)
says prize/ticket information updates once daily and defines top prizes
unclaimed as not yet redeemed, which does not establish store stock. The new
catalog notes preserve that definition, daily cadence and retrieval date;
a separate source publication timestamp is not supplied by this response and
is not invented. The six-hour publisher now checks this catalog and includes
its validated output in the combined state catalog feed. The bundled snapshot
is refreshed for offline use.

This adds a dated game inventory only. It does not establish complete statewide
winning-ticket counts or authorize Oregon retailer heat points. The existing
public-records request and the retailer/winner-location coverage requirements
remain pending. Catalog testing is a separate milestone from full-state
completion; deployment verification is reported in the task.
