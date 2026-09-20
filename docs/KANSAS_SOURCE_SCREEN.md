# Kansas source screen — September 16, 2026

The Kansas Lottery's [instant-game pages](https://www.kslottery.com/games/instants/?gameid=418)
list game number, start date and **prizes remaining** by prize tier, including
small prizes and sometimes free-ticket tiers. Remaining prizes are not a count
of tickets claimed or validated during a period, and the screen did not
establish original inventory or a dated historical series for each tier.

The [recent-winner notices](https://www.kslottery.com/recent-winners/robert-hendrix-250k/)
occasionally identify a selling retailer and exact address, but cover selected
stories, not every winning ticket. A retailer finder is linked from the
[Lottery's official site](https://www.kslottery.com/contact); a stable statewide active-retailer
export and winner-to-retailer join have not been verified. Draw results and
prize rules alone do not establish how many Kansas tickets won each tier.

The Lottery's [open-records policy](https://www.kslottery.com/Downloads/openrecordsactfinalrevisedoctober2014.pdf)
directs written requests to its Freedom of Information Officer at
`info@kslottery.net` and describes possible fees. Existing all-tier draw
counts, Scratch claims and original inventories, the retailer master file,
definitions, update cadence and correction fields remain to be requested or
verified. On September 16, a focused written August 2026 request was sent to
the policy's published address for these existing records, with an estimate
requested before any billable work. Requester contact information was supplied
in the email and is not stored in this repository. Gmail showed the send
notification; no responsive dataset has arrived.

Kansas can display dated official remaining-prize and selected-winner subsets
with their precise definitions, but is not ready for a complete statewide
winning-ticket total or retailer heat ranking.

## September 20, 2026 redesigned-site audit

The old `kslottery.com/games/instants/` URLs now redirect to the PlayOn
homepage. The replacement official [Scratch and Pull Tab catalog](https://playonkansas.com/games/scratch-and-pull-tabs)
embeds a complete `scratchOffs` array in the page's Next.js response, even
though the rendered first page shows only twelve games. The array contains
109 entries: 103 explicitly marked Scratch and six Pull Tabs. All 109 detail
pages were retrieved and checked against the listing: game numbers, ticket
prices and advertised top prizes agree. Every detail page has prize rows;
free-ticket rows remain categorical prizes rather than cash.

The listing includes historical games: 58 of the 103 Scratch entries have
end dates before September 20, leaving 45 without a passed end date. Those
45 detail pages contain 421 prize rows. Do not import all 103 as active games.
Keep end dates separate from claim deadlines; ended games may still be
redeemable. Remaining inventory is not a dated winning-ticket total.

A date discrepancy still requires an explicit handling decision before
publication: game 490's listing metadata says August 24, 2026, but its detail
page displays August 23. Do not silently choose a launch date. The detail
pages state that remaining quantities update hourly, but do not display the
actual inventory verification timestamp. Retrieval time must not be called
source verification time. Example [100x detail page](https://playonkansas.com/games/scratch-and-pull-tabs/100x).

Local reproducible audit files are under ignored `work/kansas_catalog/`:
`audit.py`, `list.html`, `listing.json`, all 109 detail pages and `audit.json`.
No Kansas public feed was changed during this audit. The existing records
request remains pending; no duplicate request was sent.
