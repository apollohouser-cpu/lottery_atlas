# Maine source screen — September 13, 2026

Maine is not yet ready for a complete winning-ticket total or retailer
ranking. Its official [Unclaimed Prizes](https://mainelottery.com/players_info/unclaimed_prizes.html)
page says it updates daily and dates its snapshot (September 11, 2026 at
5:00 AM when screened). It lists percent unsold, total unclaimed dollars and
top unclaimed prize counts for current instant games. These are not all-tier
winning-ticket counts or claims within a selected period; the page says the
Lottery's official outstanding prize list prevails if there is a discrepancy.
The [retailer lookup](https://www.mainelottery.com/cgi/findAgent.pl) displays
names and addresses, but a verified complete export with stable identifiers
and selling-retailer winner links was not established in this screen.

The Lottery's [contact page](https://www.mainelottery.com/about/contact.html)
specifies `foaarequest.dafs@maine.gov` for Freedom of Access Act requests.
On September 13, 2026, a written FOAA request was sent there for existing
all-tier draw and Scratch-Off counts, retailer records, definitions, source
dates, history and refresh cadence. Gmail confirmed “Message sent.” No
responsive records or complete count have been verified yet.

DAFS acknowledged the FOAA request by email on September 13, 2026 at
8:25 PM Eastern. It will review the material, estimate response time and
potential costs, and identify any withheld records. This is an acknowledgment,
not a delivered dataset or an estimated completion date.

## September 21 current catalog and report audit

Fetched all eight linked price categories ($1, $2, $3, $5, $10, $20, $25,
$30), their 37 unique official Maine.gov detail pages, the unclaimed-prizes
report and the end-date table. CMS article IDs differ from the printed game
numbers; joins must use the detail's `Game #`, not the article ID or name.

The report contains 66 unique games and 179 listed prize tiers, dated September
21, 2026 at 5:00 AM (timezone not printed). It says it updates daily. Continuation
rows omit the first five columns and belong to the preceding printed game.
All report prices/counts/percent-unsold values passed basic bounds checks.
Total Unclaimed is dollars, not a ticket count. The highest remaining tier
must not replace the game's original maximum award: lower prizes can remain
when the original top prize is depleted.

The current price-category catalog overlaps 35 of the report's 66 games.
Games 721 ($50 OR $100) and 714 ($100 OR $250) have explicit maximum awards
but no report rows, so their remaining counts must stay unknown. Game 725,
HIGH CARD POKER, has a blank Maximum Award field on its detail page; the
report's $100,000 remaining tier cannot establish the original maximum on its
own. Exclude that game from an amount-filtered import until its maximum is
independently verified, or support an explicit unknown amount in the app.
The other 34 shared games' detail maximum awards match a report tier.

The end-date table has 383 rows / 382 unique IDs. Historical ID 431 appears
twice with identical dates; ID 468 has an end date later than its last cash
date. Neither is among the current 37 catalog games or 66 report games.
No current catalog game has an end-date notice; none of the report games has
a last cash date before September 21 in this snapshot. The lottery defines
Game End as the end of warehouse shipment, not the end of retailer sales;
do not reuse Connecticut's sales-ended wording for Maine.

Audit materials in ignored `work/maine_catalog/` include all fetched HTML,
`audit.py`, `audit_report.py`, `audit_join.py`, `listings.json`, `details.json`,
`report_audit.json`, and `joined_audit.json`. No Maine catalog was published.
A scoped next import can cover the 36 catalog games with verified maximum
awards, retain two unknown remaining counts, disclose the excluded game and
current-catalog scope, and fail on any conflicting date relevant to its games.
The pending FOAA request is separate from these independently fetched sources.
