# Wisconsin source screen — September 12, 2026

Wisconsin is **deferred for the launch heat map**. Its existing
starter catalog, source links, draw schedules, and historical winner record
remain untouched.

- The [official Big Winners page](https://wilottery.com/winners/all-winners)
  includes game, prize, date, named selling retailer, and city and offers a
  list download. When screened on September 12, 2026, its newest displayed
  winner date was August 28, 2026. Its actual publication lag must be shown
  to users; this lag alone no longer blocks inclusion.
- The [official retailer information](https://www.revenue.wi.gov/Pages/Contact/lottery.aspx)
  says there are about 3,800 Wisconsin lottery outlets. A complete official
  active retailer export with exact addresses, verified coordinates, and a
  source-specific update timestamp was not established in this screen.
- The [Lottery Services Portal](https://www.wilottery.com/retailers/retailer-questions)
  offers retailer-specific sales and inventory history to authorized owners;
  it is not a public statewide winner-location source.

To resume, verify access to a complete official active-retailer feed and a
comprehensive winner feed with source-specific dates and disclosed cadence.
Match winner retailers only by official identifiers or exact published
locations; do not infer addresses.

The Department of Revenue's [August 2026 public-records notice](https://www.revenue.wi.gov/DORFAQ/openrec.pdf)
names Lottery Division Administrator Cindy Polzin as the Lottery records
custodian and accepts requests by email. A records request was sent to her
official address on September 13, 2026, seeking existing draw-game ticket
counts, Scratch-Off game/tier counts, retailer data where public, the meaning
of the published Big Winners subset, and update cadence. No fee was authorized;
the request asks for notice before any fee is incurred.

On September 18, Wisconsin Lottery's Chuck Klink asked what the phrase
“winner records linked to verified selling retailer IDs” means. The intended
records are existing validated winning-ticket or prize-claim entries, or an
aggregate report by selling retailer, game, prize tier and draw/claim date,
when the Lottery maintains a selling-retailer association. Personal winner
identities and ticket serial numbers are not requested. If no such association
exists, all-tier statewide counts and the active retailer directory are still
useful separately. The clarification was sent and Gmail confirmed delivery on
September 18. Wisconsin's substantive response is pending.

## September 20 catalog pagination and date audit

The public Scratch listing was followed through all 22 linked pages. The saved
HTML contains 2,120 rows, representing 2,117 distinct detail URLs after three
identical repeated rows across page boundaries. The page route alone does not
filter game type: published attributes identify 2,090 Scratch entries, 26
Pull-tab entries and one `pulltab-vc` entry. A refresh must enforce type and
follow pagination rather than treating the first 100 rows as a complete catalog.
The local working audit, source URLs and HTML SHA-256 checksums are retained in
`work/wisconsin_catalog/audit.json`, alongside the downloaded pages and script.
These are observations of the listing, not a verified catalog replacement.

As of September 20, Scratch entries have 2,017 past `data-endd` dates, 29 end
dates not yet past and 44 blank end dates. Blank does **not** establish current
availability: the blank-date group includes old Gold Rush (48), Wind Fall (147)
and Spin N Win (61) entries without a displayed top-prize label. Historical
URLs also repeat numeric suffixes; treat a suffix as a candidate identifier
until the detail page confirms its Game Number. Do not silently combine games
by URL suffix or infer an active game from a missing date.

Listing end dates and redemption deadlines must remain separate. For example,
[Cash Boom (2665)](https://www.wilottery.com/games/instant-games/cash-boom-2665)
has listing `data-endd` February 21, 2026, while its detail page prints
**Redeem By August 20, 2026**. The detail page is the source for the claim
deadline; the listing attribute must not be substituted for it.

The [Crossword Millionaire (2767) detail page](https://www.wilottery.com/games/instant-games/crossword-millionaire-2767)
prints game number, price, start date, total and remaining top-prize counts,
and says counts are verified weekly. It does not print a dated last-verification
timestamp. The [Green & Gold Crossword (2780) page](https://www.wilottery.com/games/instant-games/green-gold-crossword-2780)
labels its $50,000 amount as the top **instant** prize and separately describes
bonus drawings. Preserve that distinction; do not add promotional prizes into
instant-ticket inventory. Report retrieval time separately from unknown source
verification time, and do not describe a six-hour poll as six-hour source updates.

Next: verify detail-page identity, start/end/redemption semantics and historical
exclusions before implementing a refresh of the dated bundled catalog. Preserve
unknown or unavailable counts as unknown. No Wisconsin game data or winner
locations were changed by this audit. The records clarification remains pending;
no new agency replies were received during this check. Wisconsin remains
unready for retailer heat-map testing.

## September 20 detail-page verification

The official site's `themes/custom/wilottery/js/main.min.js?v=1.0.4` classifies
a game as expiring after its listing end timestamp and historical 180 days
later (15,552,000 seconds). This confirms that `data-endd` is not the redemption
deadline and that filtering out every past listing end date would omit closing
games still within that window. A copy of the script is retained in the local
audit folder. The source's calculated flag is useful for discovery; the printed
Redeem By field remains the authority for the displayed claim deadline.

Detail pages were fetched for all **95 Scratch candidates** with a blank
listing end date or an end date within/after that 180-day window, using
September 20, 2026 as the comparison date. All 95 printed Game Numbers match
the candidate identifiers, and all prices match their listing attributes.
All pages contain the weekly-verification notice, which alone does not imply
that each page still publishes a remaining-prize count.

Three blank-end-date entries have explicitly expired redemption deadlines:
[Gold Rush (48)](https://www.wilottery.com/games/instant-games/gold-rush-48)
December 10, 1998; Wind Fall (147) November 27, 1997; and Spin N Win (61)
May 15, 1997. Exclude these from the current/closing catalog despite their
misleading blank listing dates. The other **92 candidates** include 70 with
published total and remaining top-prize counts (all integer, nonnegative,
remaining no greater than total) and 22 without those counts. The 22 missing
counts must remain unknown, never zero and never inferred from another game.

The working `work/wisconsin_catalog/audit_details.py` and `detail_audit.json`
retain exact source URLs, source checksums, printed detail fields and the
candidate comparison scope. This resolves the previously identified identity
and expiry exceptions sufficiently to implement a current/closing catalog
importer with strict failure handling. It does not prove retailer stock,
all-tier claims, or a complete historical archive. The next implementation
must preserve top-instant-prize wording, unknown counts, redemption dates,
retrieval date and weekly source cadence without inventing a verification date.
No public game records changed in this verification run. Agency replies remain
pending, and the last deployment continues to pass.

## September 20 importer implementation — live refresh deferred

`tooling/import_wisconsin_scratch_catalog.py` now implements the audited
pagination, game-type selection, 180-day candidate window and detail-page
identity/price/start-date checks. It preserves instant-prize labels, weekly
verification wording, unknown remaining counts and exact redemption dates.
Seven regression tests cover these rules, repeated-page conflicts, invalid
counts and the source's paragraph-inside-heading markup. The importer validates
all 92 eligible games against the previously saved official responses; the
result is retained privately as `work/wisconsin_catalog/importer_validated_catalog.json`.

A new live retrieval returned HTTP 500 repeatedly, including a separate curl
check of the first listing page. No generated catalog was published and the
six-hour Wisconsin importer was **not enabled**. The current production workflow
remains unchanged so this source failure cannot block other states. The importer
writes its output atomically only after every required response validates.
Next run: recheck source availability, complete a fresh import, then wire the
validated output into the combined live feed and refresh the bundled snapshot.
Do not relabel the archived audit as a new retrieval. No user intervention is
needed for this agency website outage.

## September 20 source recovery and catalog publication

The first listing page recovered to HTTP 200 on the next scheduled check.
A complete fresh run of the importer then validated all 22 listing pages and
**92 eligible Scratch games**. The current output replaces the dated bundled
snapshot and is included in the combined live catalog. Seventy games publish
remaining top-prize counts; 22 retain unknown counts. Redemption deadlines,
instant-prize wording, retrieval date, weekly verification cadence and the
absence of a printed source verification date are retained in visible notes.

The normal six-hour publisher now runs the Wisconsin importer and commits its
validated generated output. A failed retrieval or validation leaves the previous
output file untouched and fails publication rather than substituting partial
results. This refresh adds a game catalog only: Wisconsin still has no newly
verified retailer activity or all-tier winning-ticket total. Catalog testing
can begin after the publishing workflow and live-feed comparison pass; retailer
heat-map testing remains deferred pending the existing records request.

### September 20 publisher outage handling

Scheduled run 35510861331 exhausted all four connection attempts to the
Wisconsin listing and stopped publication. The importer now distinguishes
exhausted transient connection/HTTP failures from malformed data and permanent
HTTP errors. During a transient outage only, it may retain the existing
Wisconsin catalog after validating provenance, dates, game identities, prices
and counts. The previous retrieval date must be no more than seven days old;
a missing, invalid, future-dated or older fallback still stops publication.
The retained file is byte-for-byte unchanged and a workflow warning exposes
the outage. Source/schema validation failures never use this fallback.
