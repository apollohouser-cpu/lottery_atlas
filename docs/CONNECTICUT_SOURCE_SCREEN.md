# Connecticut source screen — September 17, 2026

Connecticut is not yet ready for complete winning-ticket totals or a
retailer heat map. The [official Scratch Games page](https://www.ctlottery.org/ScratchGames)
has game and remaining top-prize information. Its FAQ explains overall
odds using the number of winning tickets printed for a game; those lifetime
print-run odds do not establish actual winning tickets for a selected period.
The [Where to Play locator](https://www.ctlottery.org/WhereToPlay) supports
nearby retailer searches, but a complete active statewide export with
stable IDs and verified coordinates was not established in this screen.

The public results and winner notices do not establish all-tier ticket counts
with physical selling retailer links for every game. Count definitions and
source cadence must be verified before a total can drive rankings. The
[state's Lottery statute](https://www.cga.ct.gov/2026/sup/chap_229a.htm)
applies FOIA to the corporation's records with specified exceptions; the
request seeks aggregate counts, not personal information or unclaimed ticket
serial numbers.

On September 13, 2026, a FOIA request was sent to
`ctlottery@ctlottery.org`, the corporation email published in its
[privacy policy](https://www.ctlottery.com/fr/privacy-policy), with a request
to route it to the custodian. It requests existing draw and Scratch counts,
selling retailer links, an active directory, definitions and cadence. Gmail
confirmed “Message sent.” No records have been verified from the request yet.

On September 17, assistant corporate counsel Jeffrey Yue acknowledged the
request as **FOIA #2026-025** and asked for the requester's name and date
range before processing. The intended range for ticket and claim records is
**January 1, 2026 through the latest available date**; the retailer directory
and Scratch catalog should be the latest available snapshots. The requester
sent a clarification on September 17 naming Apollo Houser and specifying
January 1, 2026 through the latest available date for winning-ticket and claim
records, while requesting a fee estimate before billable work. The sent message
was verified in Gmail. No agency data has been delivered.

## September 21 redesigned public catalog audit

The legacy `/ScratchGames` route now serves a Next.js catalog; its visible
first batch contains only 12 cards followed by Load More. The server's embedded
`games` array contains 74 unique printed `gameNo` records: 4 new, 44 active,
and 26 ended. None of their claim deadlines was before September 21 in this
snapshot. All published top remaining counts are nonnegative and at most the
original top count. Ended games must not be labeled currently on sale.

Fields include explicit numeric `ticketCostRaw` and `topPrizeRaw`, plus
formatted display strings (with doubled dollar prefixes in the payload).
Ten games have `displayTopPrize` values different from `topPrizeRaw`; one is
`$20,000 A YEAR FOR LIFE`. Verify the cash/annuity interpretation against each
detail rather than treating the two amounts as interchangeable.

Detail `/games/scratch-games/1891` was fetched successfully. It identifies
printed game 1891, a $10 price and $100,000 top prize, plus an eleven-tier
original/unclaimed table explicitly dated September 20, 2026. It renders
Game End and Last Day to Claim as TBD even though the listing payload uses
2099 dates. Do not publish these placeholder dates as real deadlines.
The FAQ also says specific active ticket-pack locations are not disclosed;
catalog inventory must not imply store availability.

Saved source material is in ignored `work/connecticut_catalog/`: `list.html`,
concatenated `rsc.txt`, `games.json`, and `detail1891.html`. Full per-game detail
joins, annuity/cash labels, eligibility and source-date validation remain before
import. No Connecticut catalog was published in this pass. This public-source
work is separate from pending FOIA #2026-025.
