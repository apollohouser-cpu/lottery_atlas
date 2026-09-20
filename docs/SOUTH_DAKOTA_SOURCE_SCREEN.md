# South Dakota source screen — September 15, 2026

The South Dakota Lottery's official [Winning Players](https://lottery.sd.gov/winning-players/)
page publishes selected winners with claim date, game, prize, selling retailer
and city. The page describes these as players who won top prizes, so the list
does not prove complete all-tier coverage. Its records are useful verified
retailer-linked activity only when labeled as a selected-winner subset.

The official [Locations](https://lottery.sd.gov/locations/) page provides a
retailer search and can display recent published winner activity at individual
locations. An older official retailer PDF is also indexed publicly, but its
current completeness and stable update cadence have not been established.
Neither source proves a complete current retailer directory or a join for every
validated winning ticket.

An August 1–31, 2026 records and routing request was emailed September 15 to
the Lottery address published on both the Lottery and Department of Revenue
contact pages. It requests existing all-tier Lotto and Scratch winning-ticket
records, a complete active-retailer directory, winner-to-retailer joins, data
definitions, cadence and corrections. The request excludes claimant personal
information and asks staff to route it to the correct records custodian if
needed. Gmail confirmed “Message sent.” Requester contact information was
supplied directly and is not stored in this repository.

South Dakota remains suitable only for clearly labeled selected-winner
activity until responsive records establish complete coverage. It is not ready
for full-state testing.

## September 20, 2026 official catalog/API audit

The [Scratch Games page](https://lottery.sd.gov/scratch-games/) embeds a
Next.js `__NEXT_DATA__` payload. Its `post.blocks` Scratch-filter attributes
contain 100 game entries: 32 marked active, 64 closed and four upcoming;
additional featured/second-chance/closing tags can overlap these statuses.
The initial HTML has an empty rendered game grid, but the embedded catalog
is present. Do not infer an empty catalog from server-rendered text alone.
The 100-entry listing has no verified completeness/pagination metadata in
this audit, so it is a published-list subset, not proof of every state game.

Public site JavaScript calls
`/api/igt/games/v1/instant-games/games/{igtIdentifier}`. All 32 explicitly
active entries were retrieved successfully and agree with that endpoint's
`ACTIVE` validation status and explicit listing ticket prices. They contain
268 prize-tier rows. The API expresses ticket and cash prize amounts in cents;
the site's display divides by 100. Its remaining-count calculation is
`winningTickets - paidTickets`, with top prize selected from prize tiers.
Every audited tier has integer nonnegative counts and paid <= winning, and
every game has unique tier numbers. Preserve the components alongside any
derived remaining count. These are cumulative inventory/paid quantities,
not claims assigned to the requested 2026 period or retailer-level activity.

The endpoint supplies distribution/disable dates but no inventory verification
timestamp in the inspected responses. Do not convert a far-future operational
date into a verified consumer claim deadline. Publication cadence is unconfirmed;
retrieval time must stay separate from source verification time. Before an
import is enabled, add tests for cents conversion, explicit active status,
missing/negative/impossible counts, duplicate tiers, listing joins and the
100-entry coverage limit. No South Dakota public feed was changed in this pass.

Reproducible read-only audit materials are in ignored
`work/south_dakota_catalog/`: source HTML/JavaScript, `active_listing.json`,
32 official inventory responses, `audit.py` and `inventory_audit.json`.
The September 15 records request remains pending; no duplicate was sent.

### Validated subset import

A fresh official fetch validated 32 explicitly active games and 268 prize tiers.
The importer verifies Scratch type, unique identifiers, active-status agreement,
explicit listing/API ticket prices, cents conversion, unique tier numbers and
nonnegative integer inventory with paid <= original winning inventory. It finds
the maximum prize rather than relying on API tier order. Ambiguous top tiers,
missing fields and contradictory status stop publication before file replacement.

The combined feed and offline bundle now carry this subset. Every game discloses
published-subset scope, cumulative inventory semantics and unknown verification
time/store availability. `sourceDate` remains null; `updatedAt` is retrieval/change
time. Distribution and disable dates are deliberately not mapped to claim dates.
The six-hour refresh checks these same constraints. Five importer regression tests
and an offline app-loading test cover the core boundaries. This is catalog-ready
partial coverage, not all-state claims coverage or a completed retailer heat map.
