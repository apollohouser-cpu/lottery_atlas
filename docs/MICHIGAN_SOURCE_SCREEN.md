# Michigan source screen — September 17, 2026

Michigan's [official instant-game FAQ](https://help.michiganlottery.com/support/solutions/articles/158000441491-in-store-instant-game-tickets-faq) links to current games, prizes remaining and the retailer finder. Individual [official game pages](https://api.michiganlottery.com/games/0649-instore-instant-win-big) show prize-tier start and remaining inventory with a dated update. The Lottery explicitly says remaining prizes include tickets that may or may not have been sold, so subtracting remaining from starting inventory does not establish validated winning tickets in 2026. The retailer finder identifies where games may be sold, not where each winning ticket was sold.

This screen has not established a complete 2026 year-to-date all-tier winning-ticket count, a current downloadable statewide retailer directory, or comprehensive selling-retailer joins. Michigan remains source-linked, not ready for a complete statewide ranking or retailer heat map. A dated instant-game inventory can be added as a separately labeled snapshot after an importer validates its coverage and update cadence.

The [Bureau of State Lottery FOIA process](https://www.michigan.gov/cg/panel-contact/foia) identifies `MSL-FOIA@michigan.gov` for written requests and requires requester name, phone, mailing address and email. Request existing January 1, 2026 to latest available all-tier draw and instant-game validation/claim records, retailer directory and selling-retailer joins, definitions and update cadence; accept a recent-month sample for format, but do not mistake it for year-to-date coverage. Ask for a fee estimate before paid work.

The written FOIA request was emailed to that address September 16 with the
required requester details, an electronic-delivery preference, and an estimate
request before any paid work. Gmail confirmed “Message sent.” In a September 17
extension letter, the Bureau deemed the request received that day and extended
its response deadline to **October 8, 2026**, citing staff availability and
coordination among divisions. No responsive data or fee estimate has arrived.
Private contact details are not stored in this repository.

## September 20 importer recheck

The existing prizes-remaining GraphQL query returned 49 rows with no reported
GraphQL errors. The current importer retained only 39 because it infers ticket
price from the game title; ten rows have no match for that expression. Examples
include `CASH-A-PILLAR $.50`, `JACKPOT 2S`, `TACO BOUT WINNING ($.50)` and
`LET FREEDOM RING`. The importer stopped at its minimum-size guard and no
catalog was written or published. The raw official response is retained locally
in `work/michigan_prizes_source.json` for further source validation.

Do not lower that guard or describe the retained rows as a complete catalog.
Title parsing does not prove ticket price, and fractional-price entries also
need an explicit game-type decision and compatible app representation. Before
activation, obtain explicit official ticket prices and verify whether this
query covers Scratch games, Pull-tabs, or a mixed retail collection; join by
confirmed official game IDs and validate every included row. The existing
importer is not wired into the production publisher. The FOIA extension remains
pending and no new agency reply arrived during this check.

## September 20 source correction and verified catalog join

Inspection of the JavaScript loaded by the official page established the exact
source enum: `PrizesRemainingGameTypeIdentifier.INSTANT` is uppercase `INSTANT`.
The former lowercase `instant` query returned a different collection: 46 of its
49 inventory rows join to CMS records explicitly classified as Pull Tabs, with
three unmatched IDs. This explains the misleading fractional-price entries.
The importer now uses the same uppercase enum as the official instant-game page.

The official `getCMSGames` query supplies explicit `igtId`, game category,
`displayedTicketPrice`, `displayedTopPrize`, store availability and web-listing
flags. The new importer selects the 106 listed, in-store records classified
`RETAIL_INSTANT_GAMES_CATEGORY` and joins each to the uppercase instant-prize
query by IGT ID. All 106 join uniquely, their displayed top prizes reconcile
with the highest inventory tier, and all counts pass nonnegative integer and
remaining-versus-starting checks. Ticket price comes from its explicit field,
never from the game title. Five regression tests cover type/price selection,
missing joins, duplicate identities, invalid counts, top-prize agreement and
zero-versus-unknown semantics.

The correct prize query contains 119 inventory IDs. Thirteen do not match the
106 listed CMS games and are explicitly excluded, not silently treated as
current catalog records: 157, 158, 162, 163, 164, 617, 626, 657, 667, 761, 765,
766 and 768. Thus the published scope is the official **listed retail instant
catalog**, not every inventory record or a complete historical collection.
Raw responses are retained locally in `work/michigan_catalog_metadata.json` and
`work/michigan_instant_prizes_source.json`.

The refreshed bundled and generated catalogs preserve each prize tier and a
visible retrieval/coverage note. The response does not establish its verification
date or update cadence; both remain unconfirmed. The official application warns
that remaining prizes include tickets that may already have been sold. No paid
or 2026 winning-ticket total is inferred. The six-hour publisher now checks this
verified catalog join. Catalog readiness depends on deployment verification;
Michigan's retailer activity and full-state completion remain pending.

## September 21 missing-inventory refresh repair

Scheduled publisher run 35672483932 stopped at Michigan because the official
INSTANT inventory removed game 630, 500X Money Maker, while the CMS still lists
it in stores at $50 with a $6,000,000 top prize. The inventory now has 118 IDs;
105 of the 106 listed games have inventory. No agency explanation or inventory
verification timestamp was supplied. The absence does not establish zero prizes,
a final-prize claim, or that the game has ended.

The importer now keeps authoritative catalog fields for a listed game whose
inventory row is absent or whose tier array is explicitly empty. Its remaining
count is null and its visible note says inventory is unavailable, unknown rather
than zero, and earlier counts are not current. It does not carry forward game
630's previous count of one as fresh data. A later valid inventory row restores
its counts through the normal refresh.

Malformed responses/arrays, duplicate identities, invalid counts and conflicting
published top prizes still fail. A response with no matched inventory fails,
and production still requires at least 40 games with validated inventory,
so a general inventory outage cannot silently replace the feed with unknowns.
Only game 630's data changed in this repair; the other 105 Michigan games and
the other 25 state catalogs remained unchanged. The published scope remains a
listed retail catalog with partial inventory, not a complete winning-ticket map.

Local verification: 50 Node, 118 Python and 70 Flutter tests passed, along with
five HTTP checks and the macOS debug build. Analysis reported only the 12
existing informational notices. New regression cases cover missing/empty
inventory, malformed/systemic loss, restored counts, and offline null handling.
Live publishing verification is separate from these local checks.
