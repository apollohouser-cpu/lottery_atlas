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

### Full candidate-detail validation

All 39 report candidates were fetched and validated against their detail pages.
The 378 detail prize rows reconcile exactly: total = claimed + remaining.
Every detail's maximum cash prize matches its report top prize, and every
top-prize remaining count agrees with the report. No candidate detail is marked
expired. The excluded Louisiana Seasons page remains the negative control for
an expired game that still carries positive lower-tier inventory.

Printed identities in page titles, explicit ticket prices and launch dates
also agree for all 39 candidates. Every detail provides a source timestamp
with an explicit CDT timezone (the parser should also support CST), allowing
per-game inventory timestamps to remain distinct from the earlier summary
report timestamp and importer retrieval time. The only noncash tier label
observed was `TICKET`; do not assign it a cash value or fold it into cash tiers.

The reproducible detail audit is `work/louisiana_catalog/audit_details.py`,
with 39 saved detail pages, `detail_audit.json` and `identity_audit.json`.
No source-validation failures occurred in this pass. Public import remains
pending implementation and regression tests; this audit does not claim that
Louisiana is ready for app testing or a complete statewide heat map.

### Validated publication path

The importer now fetches the report and all candidate detail pages, verifies
printed identity, ticket price, launch date, top prize, full tier arithmetic,
source timestamp and detail eligibility, and writes only after validation.
A fresh run produced 39 eligible games. Inventory counts come from each detail
page rather than combining differently timed summary and detail counts.
Per-game source timestamps retain explicit CDT/CST offsets; the catalog-level
report timestamp describes candidate discovery. Retrieval time is separate.

Expired detail pages and passed claim deadlines are excluded even if remaining
inventory is positive. Noncash TICKET tiers remain categorical. Five importer
regression tests cover expiration, inclusive deadlines, zero/noncash prizes,
arithmetic and identity/price/timestamp errors; an offline app test covers
expired-game exclusion and visible timestamps. The six-hour publisher and
bundled catalog now include Louisiana. This is inventory coverage, not
January-to-current dated claims or verified retailer heat-map completeness.
