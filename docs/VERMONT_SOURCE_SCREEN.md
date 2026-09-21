# Vermont source screen — September 15, 2026

The Vermont Lottery's official [Winners](https://vtlottery.com/win/winners)
page publishes claim date, store name, town, game and prize amount for selected
draw, instant and Fast Play winners. It includes many current 2026 records and
is useful as a verified public subset. The page does not state its prize
threshold or whether every qualifying claim is included, and it supplies only
the retailer town rather than an exact address or stable retailer identifier.
It therefore cannot support a complete all-tier total or exact retailer heat
points by itself.

Individual official game pages publish ticket count, percentage sold and
unclaimed prizes by tier. The Lottery warns that remaining prizes depend on
tickets distributed, sold and redeemed. Those inventory figures are not actual
winning-ticket or claim counts and must retain that limitation in the app.

The Lottery's official [contact page](https://vtlottery.com/contact-info)
identifies its Director of Communications and Legislative Affairs as the route
for public information requests and links a public-records database. A focused
Vermont Public Records Act request was emailed to that published address on
September 15. It seeks existing August 1–31, 2026 all-tier draw, instant and
Fast Play ticket counts, a complete active-retailer directory, winner-to-
retailer joins, definitions, cadence and corrections. Gmail confirmed “Message
sent.” Requester contact information was supplied directly and is not stored in
this repository.

Vermont remains suitable only for a clearly labeled public winner subset until
the prize threshold and completeness are confirmed and exact retailer records
are obtained. It is not ready for map testing.

Update September 16: Hannah Chauvin, Director of External Affairs, acknowledged
the September 15 request and extended the response deadline to ten business
days from receipt because of the volume of distinct records to search and
examine. No responsive data or fee estimate accompanied the notice. Track the
agency response around September 29, subject to its business-day calendar;
keep the existing partial-coverage limitation meanwhile.

## September 21 catalog source audit

The working official catalog is `/games/instant-tickets`; `/games` returns
404. The catalog explicitly reports 82 games and has seven pages (`?page=0`
through `?page=6`). Detail links may be short aliases such as `/full-100s`,
not paths containing `instant-tickets`; collect the actual card links.
The reproducible `work/vermont_catalog/audit_listing.py` checks printed game
IDs, names, explicit ticket prices and advertised top prizes across pagination.

Inspected detail `/games/instant-tickets/bank-vault` identifies game 1824,
price $5, top prize $20,000, start January 10, 2025 and last cash date April
10, 2027. It explicitly shows zero unclaimed $20,000 and $1,000 prizes, four
$500 prizes, 420,000 printed tickets, 98 percent sold and $73,790 total
unclaimed dollars. Do not substitute dollars paid/unclaimed, tickets printed,
or percentage sold for winning-ticket counts. Preserve published zeroes.

No inventory verification timestamp or publication cadence was established
from this initial detail check. Full detail/date/eligibility joins, top-prize
report semantics and any reserved second-chance inventory require validation
before import. No Vermont data was published in this pass. Source HTML and
listing audit materials are retained under ignored `work/vermont_catalog/`.

Pagination did **not** pass: the seven saved pages contain 82 rows but only
77 unique printed IDs. Games 1854, 1838, 1871, 1799 and 1839 repeat across
page boundaries. The default ordering appears unstable among tied entries,
but its cause is not established. Do not silently deduplicate and label 77
games complete. The importer must establish a stable sort/full export or an
independently reconciled source before publication. The audit intentionally
fails its uniqueness check; saved pages preserve the evidence.
