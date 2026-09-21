# Louisiana source screen — September 13, 2026

Louisiana is not ready for a complete winning-ticket total or retailer
ranking. Its [Top Prizes Remaining](https://louisianalottery.com/scratch-offs/top-prizes-remaining/)
information covers top-prize claims and unclaimed prizes for active games,
not all winning tickets in a selected period. The Lottery's
[retailer terminal report guide](https://louisianalottery.com/static/files/docs/RetailerForms/Terminal-Report-Guide22.pdf)
describes top prizes claimed and remaining; this cannot establish all-tier
Scratch-Off counts. Monthly winnings releases on the
[news page](https://louisianalottery.com/news-and-promotions/) generally
report prize dollars, not complete ticket counts. A complete active
retailer export and retailer-linked wins were not established in this screen.

The [2026 official press kit](https://louisianalottery.com/wp-content/uploads/2026/02/2026-Press-Kit.pdf)
lists Communications Director Chrislyn Maher. On September 13, 2026, a
data inquiry was sent to `Chrislyn.Maher@LouisianaLottery.com` for routing
to the appropriate data or records custodian. It requests existing all-tier
draw counts, Scratch-Off ticket or claim counts, retailer records, definitions,
historical coverage, update cadence and daily access if available. Gmail
confirmed “Message sent.” This is an inquiry rather than a formal records
filing; no complete dataset has been verified from a response yet.

## September 20, 2026 catalog and inventory audit

The current official endpoints are `/scratch-offs/`, `/top-prizes-remaining/`,
`/last-day-to-claim/` and `/expired-games/`. The older nested report link above
should not be used for an importer. Reports embed structured JSON inside
`prize-table` elements; a text-only or HTML-table-only reader misses the rows.

The source catalog contains 40 unique game links. The top-prize report contains
39 unique game numbers, all linked from that catalog, with explicit price,
top prize, start date and remaining/original quantities such as `1 of 6`.
All numeric fields and remaining <= original checks passed. The report is dated
September 20, 2026 01:51:04 AM CDT. The closing report has nine rows and the
expired report has 36; neither overlaps those 39 top-prize entries. The closing
page explicitly states daily updates; do not assume every source shares that
cadence without checking.

The extra catalog link is game 1605 Louisiana Seasons. Its detail page explicitly
marks it expired, with a February 4, 2026 final redemption date. Its prize table
still shows positive remaining lower-tier counts, even though prizes can no
longer be redeemed. Thus neither presence in a catalog nor remaining > 0 proves
eligibility. Exclude this game from a current playable/redeemable catalog.
The expired report is not by itself a complete historical exclusion list.

The detail source distinguishes total, claimed and remaining prize quantities
by tier, including a categorical TICKET tier. These are cumulative game inventory,
not dated winning-ticket totals. Preserve categorical awards and source timestamps.
The separate approximate percent-claimed metric does not equal the percentage
of top prizes claimed (for example 1640 has 1 of 6 top prizes remaining but
97% claimed), so do not derive or relabel it as top-tier claims.

Read-only audit files are in ignored `work/louisiana_catalog/`: catalog, three
report pages, Louisiana Seasons detail and `audit.json`. No Louisiana public
feed changed during this audit. Before import, validate the 39 candidate detail
pages and their explicit eligibility, then test identity joins, expiry, remaining
arithmetic and noncash tiers. The records-routing inquiry remains pending.
