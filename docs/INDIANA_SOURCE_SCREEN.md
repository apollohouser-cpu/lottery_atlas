# Indiana source screen — September 13, 2026

Indiana is not yet ready for a complete winning-ticket total or retailer
ranking. The official [Scratch-off Stats](https://hoosierlottery.com/games/scratch-off/scratch-off-stats/)
page lists current games, game numbers, top-prize totals and unclaimed top
prizes. These are not all-tier winning-ticket or claimed-ticket counts for
a selected period. The [game FAQ](https://hoosierlottery.com/contact-us/frequently-asked-questions/hoosier-lottery-games/)
explains that odds use printed tickets and total prizes; printed counts
should not be presented as realized wins. Its winner and retailer lookups
do not establish a complete, retailer-linked state feed in this screen.

The Lottery's [public-records page](https://hoosierlottery.com/who-we-are/bids/public-records/)
directs requests to the [APRA portal](https://in.accessgov.com/hoosierlotto-apra).
The portal's request form requires login and states submissions appear in
the public request log. The portal publishes `publicrecords@hoosierlottery.com`
for questions. On September 13, 2026, a written data and submission-routing
inquiry was sent to that address for all-tier draw counts, Scratch-Off
winning or claimed counts, retailer data, definitions and update cadence.
Gmail confirmed “Message sent.” It asks whether the email can be accepted
as a request or requires a separate portal filing; do not mark a formal
APRA request filed until confirmed. No responsive dataset is verified yet.

On September 16, 2026, an Access Indiana account was created and its email
verified. A formal APRA request was submitted through the Hoosier Lottery
portal for existing August 2026 all-tier draw and Scratch-Off winning-ticket
records, retailer records and joins, definitions, update cadence, corrections
and any existing regularly updated source. The portal displayed “Form
submitted successfully” and said it would review the request and provide a
follow-up email. No fee was authorized. No responsive dataset has arrived.

## September 20, 2026 inventory import

The unfiltered official Scratch-off Stats table contains 64 games, with
explicit game numbers, ticket prices, cash top prizes, unclaimed top prizes,
original top-prize totals, on-sale dates and estimated odds. No pagination
was present. The importer preserves these fields and checks unique IDs,
column identity, integer counts, remaining counts against original totals,
and valid on-sale dates. Missing counts, noncash prize labels, pagination,
or an unexpectedly small response stop publication rather than invent values.

The source does not print an inventory verification date or publication
cadence. `sourceDate` remains null; `updatedAt` records retrieval/change time.
Each game discloses that the counts cover unclaimed top prizes only, with
store availability unverified. The table does not supply game ending or
redemption dates. These listings do not establish active stock at retailers.
The six-hour publisher now refreshes this catalog; this remains partial
inventory coverage, not all-tier 2026 winning-ticket totals or a fully
developed state. The September 16 APRA request remains pending.

Six regression tests cover valid zero remaining, missing and malformed
counts, impossible inventory, duplicate games, invalid/future dates, changed
columns, pagination and unsupported prize labels.
