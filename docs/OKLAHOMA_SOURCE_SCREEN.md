# Oklahoma source screen — September 14, 2026

The Oklahoma Lottery's [Scratcher catalog](https://www.lottery.ok.gov/scratchers)
publishes game-level top prizes remaining and overall odds. Individual
[Fast Play pages](https://www.lottery.ok.gov/fast-play/) publish each prize tier's
total and remaining count and state that remaining prizes update Monday through
Friday at 8:00 a.m. Remaining inventory is affected by distribution, sale and
redemption, so these values are dated availability snapshots rather than counts
of every ticket won or claimed during a period.

Official draw pages publish winning numbers and prize tables, while the recent
winners section is selective. Those pages do not establish complete all-tier
winning-ticket counts. The retailer finder is useful for discovery, but a
complete machine-readable active retailer directory with stable IDs and a join
from every winning ticket has not been verified.

The Lottery's [contact portal](https://feedback.lottery.ok.gov/) advertises a
Records Request route. When screened, the direct request instructions displayed
Arizona statute `A.R.S. § 39-121.03` and an Arizona `480` telephone number even
though the page identified itself as the Oklahoma Lottery portal. The form also
required a requester address and phone. Because the published instructions are
internally inconsistent, no formal request was represented as filed.

On September 14, a data and routing inquiry was emailed to
`info@lottery.ok.gov`, the address on the official contact form. It requests
existing August 1–31, 2026 all-tier draw, Scratcher, Fast Play, retailer and
retailer-linked reports and asks the Lottery to confirm the correct Oklahoma
records route. Gmail confirmed “Message sent.” No complete dataset or response
had been received at screening time, so Oklahoma was not ready for full-state
testing.

On September 16, Oklahoma Lottery replied that it cannot provide the
requested datasets, reports, APIs or direct feeds. It said some requested
reports or connections do not exist and other information cannot be provided
for privacy and security reasons. It pointed to public original and remaining
prize information for Scratchers and Fast Play. This supports only a dated,
limited prize-inventory view; it does not verify all-tier draw winning counts
or a complete retailer-linked ranking. Oklahoma remains deferred for those
features.

## September 20, 2026 redesigned catalog audit

The legacy `lottery.ok.gov` paths redirect to `https://oklottery.com/` and
lose the requested game path. The working official catalog is now
[Scratchers](https://oklottery.com/games/scratchers). Its embedded Next.js
`scratchOffs` data contains 96 entries, including 44 without an end date.
The rendered first page shows only twelve cards and a Load More control;
reading only visible initial cards would omit most games.

All 44 no-end-date detail pages were fetched. Each agrees with its listing's
printed game number, internal game ID, slug, ticket price and top prize. They
contain 575 prize-tier rows, with integer remaining and original totals and
remaining <= original for every row. Each detail has a null claim-end date.
All maximum prize amounts match the advertised top prize, and prize amounts
are unique within each game's tier table. The payload uses `$$` as the literal
cash prefix (for example `$$20`); this is formatting, not cents or a second
cash value. Internal IDs differ from printed numbers: All the Luck has
internal ID 95 and printed game number 842. Preserve the distinction.

The page renders separate desktop and mobile representations of the same
inventory. Parse one verified structured representation to avoid double
counting. Original total prizes, remaining prizes and total tickets printed
must remain distinct; none establishes dated claims. No actual inventory
verification timestamp was found in this audit. Do not apply the earlier
Fast Play weekday update statement to Scratchers without verification.

Read-only materials are in ignored `work/oklahoma_catalog/`: source listing,
44 detail pages, `listing.json`, `audit.py` and `audit.json`. No public Oklahoma
feed was changed in this pass. The initial importer should explicitly scope
itself to the verified no-end-date subset and retain unknown source date and
cadence, with tests for identity, duplicated rendering, money formatting and
inventory arithmetic. The agency's September 16 response still limits broader
records availability.
