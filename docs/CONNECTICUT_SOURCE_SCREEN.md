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

### September 21 full detail validation

Fetched all 74 listed game detail pages with two concurrent requests. The
reproducible `work/connecticut_catalog/audit_details.py` validated printed
identity, ticket price, advertised top-prize label, top-tier original and
remaining counts, exact tier-table headers, and nonnegative original/remaining
bounds for **740 tiers**. Every detail's inventory date was September 20, 2026.
`detail_audit.json` retains each result and source excerpt locally.

`audit_metadata.py` independently reconciled all 74 launch, end and last-claim
dates against the listing. The listing's 2099 dates correspond to visible TBD;
real dates agree. The 26 ended games must be labeled claimable ended games,
not currently on sale. `metadata_audit.json` records the date and cash-option
checks; nine of ten advertised annuity games have a rules-described cash
option matching `topPrizeRaw`.

**Unresolved source conflict:** game 1725, $20,000 A YEAR FOR LIFE, has catalog
`topPrizeRaw=575000`, but the detail rules explicitly describe a $440,000
one-time gross cash option, $20,000 per year for life and a $400,000 guaranteed
minimum payout. Its displayed life-prize label and top-tier counts agree.
Do not publish $575,000 as a verified cash option. An importer must quarantine
that amount or disclose the conflict with a source-specific rule; it must not
silently prefer one numeric source. Preserve the life-prize label and avoid
representing a guaranteed minimum as the full lifetime payout.

No app/feed changed during this audit. The next importer should preserve
per-game dates, separate annuity and cash values, distinguish ended claimable
games from active games, omit TBD dates, and explicitly handle game 1725 before
enabling Connecticut catalog testing. The existing Maryland live catalog and
publisher remain verified; no agency reply arrived during this check.

### Importer with explicit disputed-game exclusion

The importer excludes game 1725 entirely, with its reason recorded in the
catalog and disclosed in each game's inventory note. It does not publish
either conflicting cash value. Other annuity games require an exact cash-option
match between the listing and detail rules; the advertised annuity remains
the display label and amount filters use the verified cash option.

Per-game detail inventory supplies counts and dates, so a later detail refresh
is not mixed with undated listing counts. Original top-tier counts still must
agree. Eligibility, displayed status, prices, printed IDs, tier bounds and
dates are validated. TBD/2099 dates are omitted. Ended but unexpired games are
explicitly labeled with sales-ending and claim dates. Two listing records lack
HTML display names; their plain official game names are retained instead.

Six Python tests cover annuity/cash agreement, zero detail counts independent
of listing counts, the disputed-game exclusion, inclusive claim deadlines,
placeholder dates, missing HTML names, and invalid listing/price/identity/date/
inventory fields. An offline app test covers the exclusion, annuity label,
verified cash filter value and ended-game notice. Catalog readiness remains
separate from unavailable dated claims and retailer-linked activity.

Fresh-source import on September 21 produced 73 games and 731 prize tiers:
43 active, 4 new, and 26 ended but still claimable. All inventory dates were
September 20. The generated feed and offline bundle are registered in the
six-hour publisher and combined feed (now 21 state catalogs). The original
74-game audit remains accurate for the source; the one-game difference is
the explicitly excluded game 1725, not an unreported completeness claim.

### September 21 connection-failure recovery

Publisher run 35596079756 stopped on curl exit 7 fetching game 1892; the next
scheduled run 35599991940 succeeded and published Maine as well as Connecticut.
The importer now retries DNS/connect failures (curl exit 6 or 7) up to four
attempts with one-, two- and three-second delays. Existing bounded curl retries
for supported transient HTTP/timeouts remain. Permanent HTTP and certificate
failures are not retried by this additional loop; no saved data or source dates
are relabeled as fresh on failure.

Three regression tests verify recovery, four-attempt exhaustion, and no added
retry for HTTP/certificate errors. All 94 Python tests pass. A live fetch of
previously failed game 1892 succeeded after the change. This is a transport
resilience change only; catalog coverage and exclusions remain unchanged.

### September 22 optional odds row repair

Publisher 35733918009 passed the Nebraska repair, then failed at Connecticut's
identity/price check. A complete fresh source capture identified game 1840,
MEGA BUCKS, as the only failing entry. Its page omits Overall Odds and puts Game
Start directly after Price. Its game number, $5 price, $50,000 top prize,
listing/detail dates, and prize table agree. Sales ended October 20, 2025;
it remains claimable through September 25, 2026. The missing odds row is not
needed for the fields this importer publishes.

The parser now accepts either of those two exact headings after the price.
Wrong IDs/prices and missing date headings still fail; error messages include
the game number. One regression test exercises absent odds and those invalid
cases. A complete capture of the official catalog and all detail pages is kept
privately under `work/connecticut_september22`. Running the full importer against
that capture validated **74 eligible games and 742 tiers**, dated September 21.
Game 1840 is newly listed relative to the prior generated feed. Game 1725 stays
excluded. The combined feed retains its scope and ended-game notices.

Validation passed 131 Python, 50 Node and 70 Flutter tests, plus five HTTP checks.
Deployment remains a separate check; the last successful live feed stays available
while this publisher repair is pending.

September 22 deployment verification: publisher 35741615131 succeeded, and all
four live feeds matched published commit 9936bdf. The 74-game Connecticut catalog
with September 21 inventory is live and ready for catalog testing. The existing
cash-value exclusion and ended-game notices remain; no all-tier claims map is
implied.
