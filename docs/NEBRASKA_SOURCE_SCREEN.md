# Nebraska source screen — September 18, 2026

Nebraska is **not yet ready for a complete verified heat map**. Its existing
official source links and draw schedule remain in place.

- The [official retailer search](https://nelottery.com/homeapp/retailers/search)
  filters by city or ZIP. The Lottery says its retailer network has more than
  1,200 locations, but a complete published active directory with exact
  addresses and verified coordinates was not established.
- The [official Scratch prizes remaining page](https://m.nelottery.com/homeapp/scratch/prizesremaining/web)
  publishes game, price, top prize tiers and counts. Nebraska Lottery says
  this page updates weekly.
- The [official unclaimed Lotto prizes page](https://nelottery.com/homeapp/lotto/unclaimedprizes)
  identifies retailers, towns, games, draw dates and prizes, but only for
  *unclaimed* prizes; it also says it updates weekly. This is not the full
  retailer-level winner history.
- The [recent winner notices](https://nelottery.com/homeapp/landing)
  show named selling locations and exact addresses for selected recent
  winners. They are useful verified points, but do not establish complete
  claims coverage from January 1, 2026 onward.

Weekly official data is allowed with a state-specific notice; the app now
shows one for Nebraska. To complete Nebraska, verify a full official active
retailer directory and comprehensive retailer-level winner feed, preserving
each source's real publication date and cadence.

The Lottery's [public-records page](https://nelottery.com/homeapp/about/publicrecords)
identifies `lottery@nelottery.com` for written requests addressed to Director
Brian Rockey. A request was sent September 13, 2026 for existing draw-game
winning-ticket counts, Scratch game/tier original and claimed counts,
retailer records where public, source definitions, and update cadence. The
request provided a name and reply email and asked for notice before any fees.

On September 16, Lottery counsel Jordan Mruz confirmed receipt and asked for a
concrete example to route the request. A reply narrowed the initial period to
August 2026 and described example rows for Nebraska-sold draw-game winning
counts by drawing and tier, Scratch prize counts by game and tier, the active
retailer directory, and any releasable selling-retailer link. It accepted
existing standard reports and partial production with clear coverage, and
requested an estimate before billable work. Gmail showed the sent reply.

On September 18, counsel said he was still coordinating with multiple people
to determine what records are publicly available. He identified the current
[Scratch catalog](https://nelottery.com/scratch), whose game details give prize
tiers and total winners for each game; a separate
[prizes-remaining report](https://nelottery.com/images/media/Scratch_Prizes_Remaining.pdf);
[closing-game notices](https://nelottery.com/scratch-games-closing); and
[draw-game results](https://nelottery.com/lotto-detail?gamename=Mega+Millions),
which he described as showing only the latest draw. These sources may support
a dated catalog and cumulative game inventory, but they do not by themselves
establish January 1, 2026-to-current validated winning-ticket counts or
selling-retailer joins. The request for those records remains open; no fee
estimate or responsive extract was provided in this message.

## September 20 catalog and inventory reconciliation

Retrieved the current official catalog and all 25 linked detail pages. They
contain 630 prize-structure rows under `Prize / Odds / Winners**`. Prize amounts
can repeat within a game (different winning combinations). These rows must
not be treated as dated claims or as remaining inventory. The source cautions
that quantities can vary with omissions, unsold tickets, reorders and unclaimed
prizes. A URL's `gameid` is a routing identifier, not the printed game number:
for example `gameid=1035` displays game 1335, Pocket Change 5X. Join using the
printed identity, not arithmetic on routing IDs.

The separate one-page remaining-prizes PDF was downloaded, text-extracted,
rendered and visually inspected. It is explicitly dated September 13, 2026
and shows selected top prize tiers for 25 games, not every prize tier. The
report and current catalog overlap on 24 printed game numbers. Current game
1344 Power Play is absent from the report; report game 1357 50X is absent from
the current catalog. Missing remaining counts must stay unknown, never zero.
The September 13 closing page also separates closing dates from expiration
(last claim) dates. The PDF explains that tickets can remain on sale during
the closing process; a closing notice does not establish retailer stock.

Audit materials are in ignored `work/nebraska_catalog/`: official PDF,
listing/closing HTML, 25 detail pages, reproducible detail audit script,
`catalog_audit.json` and `join_audit.json`. No public Nebraska feed changed
in this pass. Next implementation should preserve the weekly report date,
selected-tier scope, distinct printed and routing IDs, closing/claim dates,
and the unmatched Power Play count while testing joins and repeated prize
amounts. The agency's request for broader records remains pending.

### Verified catalog import

The September 20 import validates all 25 current catalog games and joins 24
top-prize counts from the visually reviewed September 13 PDF. Power Play
1344 keeps an unknown remaining count. The reviewed JSON records the PDF's
SHA-256, date and manual-review method; counts require a new document review
to update. The automatic six-hour job refreshes catalog details only, never
changes the report date, and does not imply current inventory verification.
Each game displays its dated inventory or explicitly unknown count.

The importer checks printed identities, listing/detail names, explicit ticket
prices, structure-column labels, and matching top-prize amounts before writing.
Repeated prize amounts remain separate structure rows. Free-ticket and mixed
cash/ticket combinations retain their labels without a guessed cash value.
The combined feed and offline bundle both include Nebraska. This is catalog
and dated top-prize coverage only, not a fully developed state or claims heat map.
