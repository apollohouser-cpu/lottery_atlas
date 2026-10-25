# Oklahoma source screen — September 14, 2026

**October24,2026 at21:06ET: sole active state.** Scope due October25 at21:06ET;
supported release due October29 at21:06ET. See OKLAHOMA_ACCEPTANCE.md.

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

### Validated catalog import

The fresh importer validates the 44 no-end-date games against their detail
payloads before publishing. It verifies unique printed and internal identifiers,
prices, eligibility, launch dates, prize formatting and inventory arithmetic.
It accepts the source's literal double-dollar prefix as dollar formatting,
checks maximum tier against advertised top prize, and rejects duplicate tiers
instead of counting desktop/mobile copies. Missing/negative counts and source
schema or status changes stop publication before atomic replacement.

The six-hour publisher and refreshed offline bundle now include this subset.
Each game discloses scope and unknown verification timestamp/cadence. The
catalog's `sourceDate` stays null; retrieval/change time is separate. Five
importer regression tests and an offline app-loading test cover identity,
ended/future eligibility, zero/invalid counts, joins and duplicate tiers.
This remains catalog inventory coverage, not dated all-tier claims or a
fully developed retailer map.

### September 24 newly launched games without inventory

Publisher 35965100425 stopped because six newly launched game detail payloads
explicitly set `prizeDetails` to null. A fresh official-source inspection found
50 eligible games among 102 listed entries: 44 still have validated inventory;
printed IDs 871, 856, 861, 858, 857 and 859 have September 24 launch dates,
verified listing/detail identities and advertised prizes, but no prize tables.
Raw captures and a local trial catalog are private in
`work/oklahoma_september24/`.

The importer now retains catalog metadata for explicit-null inventory with
`topPrizesRemaining: null`, empty prize tiers and an unknown-inventory notice.
It never translates missing inventory into zero or carries an older count
forward. Missing fields, malformed/ambiguous structures, identity conflicts and
invalid published counts still fail. Fewer than 20 games with validated prize
tables also stop publication, so broad inventory loss cannot silently produce
an apparently complete refreshed feed. Source date remains unknown.

The fresh local import validated all 50 games. All 134 Python tests passed,
including three new regression tests covering unknown inventory, malformed
structures and broad inventory loss. Publishing and live verification are still
pending; this does not establish all-tier claims or retailer-map completeness.


## October24 opening all-game audit

Five official captures and hashes are private in work/oklahoma_scope. Current
[home](https://oklottery.com/) links Powerball/Double Play, Mega Millions,
Scratchers and Fast Play; exhaustive scope remains open. Draw bodies are client
rendered; embedded CMS contains schedules and nested results, including scheduled
empty PB/DP entries. UTC date labels must not be copied as Oklahoma draw dates.
Tier count geography and zero payout meanings remain unverified. The Scratcher
listing has102 entries,50 eligible under the existing no-end-date filter; fresh
detail validation is pending. One Fast Play detail confirms distinct remaining
and original quantities and a separate progressive estimate. No public data was
changed. See OKLAHOMA_ACCEPTANCE.md for gates, limits and fresh deadlines.


## October24,22:02ET — full navigation and catalog audit

Decoded official navigation and captured the complete draw/Fast Play listings
plus five additional draw detail pages. Seven new responses have private hashes
and UTC retrieval timestamps in work/oklahoma_scope/catalog-manifest.json and
draw-manifest.json (twelve opening responses in total). The full draw listing,
unlike the home teaser, includes seven families: Powerball, Mega Millions,
Lotto America, Powerball Xs & Os, Millionaire For Life, Pick3 and Cash5.
Double Play is a separate nested Powerball drawing. All seven CMS end dates
are null. Each detail embeds two result records, but PB, Lotto America and MFL
include one scheduled/empty record; two records do not mean two completed draws.

Fast Play listing contains32 entries beyond the twelve initially rendered cards:
19 have no end date and13 have ended. All ten nonprogressive entries are ended;
the no-end-date subset is progressive. This is listing evidence only, not fresh
verification of every detail/inventory. Do not confuse the Fast Play game named
Double Play Progressive with the nested Powerball Double Play drawing.

Pick3 CMS lists two daily times (13:10 and21:10), while Cash5 lists21:10.
Session identification and local draw-date joins therefore remain explicit
scope questions; do not silently assume one Pick3 session. Pick3 legend has five
match categories; Cash5 has four, including categorical Free Ticket. No dated
winner-count geography/units are accepted from these observations. Current and
retired history gaps, scheduled-result treatment, full Fast Play eligibility,
and source client display semantics must be reconciled before scope closure.

Next inspect the source client result/session and winner-table contracts and
review all seven rules/schedules. No public feed/app/build or acceptance change;
October25 21:06ET scope and October29 21:06ET release deadlines unchanged.


## October24,23:07ET — rule structures and client semantics audit

Reviewed retained rule prose for all seven current draw families and counted
20 prize-legend groups containing167 physical match rows. Powerball has six
groups/54 rows (its first group includes a distinct Double Play prize column),
Mega Millions five/45, Lotto America five/45, Millionaire for Life one/nine,
Pick3 one/five, Cash5 one/four and Xs & Os one/five. These are source structure
counts, not winner counts; strict row-contract validation remains open.

Powerball rules specify5/69+1/26, optional Power Play and Double Play, and the
10X threshold of $150 million. Mega Millions specifies5/70+1/24 with a per-play
2X/3X/4X/5X/10X multiplier. Lotto America specifies5/52+1/10 and optional
All Star Bonus. Millionaire for Life specifies5/58+1/5. Pick3 uses three ordered
0–9 digits with Straight, Box and pair categories; Cash5 uses5/36 and includes
categorical Free Ticket. Xs & Os uses eight of32 team logos: retained result
codes must remain literal until the logo/code mapping is verified. Cash5 prose
also describes a shared pretax pool when more than five top-prize winners occur;
do not infer an actual dated payout from the advertised top prize.

Captured45 source client scripts linked by the retained Pick3 page, with UTC
retrieval times and SHA256 hashes in private client-manifest.json; all retained
hashes rechecked. Client configuration explicitly names America/Chicago and
contains a UTC-to-local date helper, supporting the required local-date audit.
It also contains UTC-only formatting, so configuration alone does not establish
which formatter renders a particular result. Translations distinguish Pick3
Midday1:10PM and Evening9:10PM, consistent with its two CMS times, but the rule
prose gives only an8:59PM CST cutoff. Preserve that discrepancy. The two retained
Pick3 completed timestamps correspond to evening local dates; midday history is
not established by those records.

Client translations include Oklahoma-winner labels and legacy game/multiplier
names, but the inspected scripts do not establish the actual shareCount or
multiplierShareCount rendering joins. Count geography, zero payout meaning and
session joins remain unverified and must not be promoted. Legacy translation
names are not proof of current offered games or an available retired history.
The current family list remains grounded in the full official navigation.

Next resolve bounded result/session contracts and explicitly classify unavailable
history/count fields, then validate Scratch and Fast Play details before scope
closure and publication. No public feed, app build, source-date advancement or
acceptance change. Scope due October25 21:06ET and release due October29 21:06ET
remain unchanged; no extension.


## October25,00:13ET — complete eligible product detail audit

Fetched all 50 eligible Scratcher and 19 no-end-date Fast Play detail pages
against the retained complete listings. The 69 successful responses were
retrieved October25 04:12:39–04:13:03 UTC and retained privately with individual
UTC timestamps and SHA256 hashes in work/oklahoma_scope/product_audit_20261025.
All 69 stored hashes were independently recalculated. This is a fresh detail
audit against the earlier listings, not a fresh atomic catalog publication.

All 50 Scratch details pass the existing strict parser's identity, eligibility,
prize-format, duplicate-tier, inventory arithmetic and advertised-top-tier checks.
They now contain 653 numeric prize rows; none has explicit-null inventory in this
audit. The six previously unavailable games therefore have published structures
in these captures. Preserve the old public snapshot and its date until a complete
validated collection is published; do not silently change unknowns to counts.

All 19 eligible Fast Play details match listing game ID, slug, ticket price,
launch date and null end date and retain progressive=true. Their single prize
groups contain 219 rows: 200 literal cash rows and 19 categorical JACKPOT rows.
Every original/remaining count is a nonnegative integer with remaining no larger
than original; labels are unique per game and totalTickets is a positive integer.
Each game has exactly one JACKPOT row. The separate changing topPrize estimate
must not replace that categorical label or be checked as a fixed maximum cash
prize. Original prizes, remaining prizes and total tickets remain distinct.
This private audit is not a production Fast Play parser or acceptance gate.

The 13 ended Fast Play entries and 52 Scratch entries outside the existing
eligible filter remain outside this current-product inventory audit; no complete
retired-game inventory/history or claim counts are inferred. Count geography and
Pick3 session joins remain separate unresolved draw contracts. Next encode the
bounded product/history/gap matrix and strict Fast Play parser, then coupled
collection and publication. No public feed or native build changed. Scope and
release deadlines remain October25 and October29 respectively, both21:06ET.


## October25,01:08ET — strict Fast Play parser

Added tooling/import_oklahoma_fast_play.py without a publication entry point.
It validates listing identities, Chicago-local launch eligibility, ending status,
and progressive-only coverage; an active nonprogressive game requires review.
Detail validation joins the listing metadata, preserves printed/internal IDs,
and strictly checks cash labels, categorical JACKPOT, original/remaining counts,
duplicates and missing versus explicit-null inventory. Zero progressive estimate
is unavailable; positive estimates stay separate from fixed prize tiers.

The complete retained32-entry listing and all19 eligible captured details pass,
producing219 rows. The listing includes unprefixed slugs: printed game numbers
come from detail gameNumber, with a numeric slug prefix cross-checked only when
present. All18 Oklahoma Python tests pass (10 Fast Play, eight Scratch), including
identity/status drift, local dates, malformed counts, duplicate cash aliases,
jackpot loss and unknown inventory. Replay preserves original capture provenance;
no new source verification timestamp, feed publication, app build or acceptance.
Next close the explicit scope/gap matrix, implement strict draw contracts and
coupled collection/retention before app integration. Deadlines unchanged.


## October25,02:07ET — scope decision

The fixed supported product/history/gap matrix is in OKLAHOMA_ACCEPTANCE.md.
All seven current draw families plus nested Double Play, Scratchers and Fast Play
are included; current-game scope is grounded in complete navigation/listings.
The retained opening window has12 completed records and four scheduled empty
records including nested Double Play. These are implementation targets, not
published parser results. All exact-date winner reports remain unavailable until
geography and units can be proved. Pick3 session identity and session-specific
history remain explicitly unavailable; timestamps alone do not establish sessions.
Retired archives, ended inventory, promotions as claims and retailer joins remain
unavailable/excluded as detailed in the matrix. Scope closed before its deadline;
release still due October29 21:06ET, with no new public data/build or acceptance.


## October25,03:10ET — bounded completed-result parser

Added tooling/import_oklahoma_draws.py with explicit contracts for all seven
families and separate nested Double Play. It validates CMS/envelope/result game
identity, bounded newest-first windows, unique identities/local dates, UTC date
consistency, completion status, number count/range/type/order and multipliers.
Pick3 preserves repeated ordered digits with session unavailable. Xs & Os keeps
literal source codes. Mega Millions never receives a draw-wide multiplier.
Double Play must join its parent by local date, status and later timestamp.
Scheduled records must be empty and are excluded; future completed records fail.

Replayed all seven retained HTML captures with their original manifest retrieval
times:12 completed results across eight groups, four scheduled records excluded.
All12 winner reports remain explicitly unavailable; source prizeTiers and private
source identifiers are not exported. Local dates use America/Chicago while raw
UTC timestamps and original retrieval provenance are preserved. No source refresh
or newer verification is claimed by replay. Output remains private.

All26 Oklahoma Python tests pass (eight draw, ten Fast Play, eight Scratch).
Draw tests cover all family contracts, repeated Pick3 digits, range/type/order,
malformed/future dates, scheduled contamination, mismatched identities,
multipliers and Double Play joins. Strict literal rule/schedule contracts and
coupled collection/retention remain next, followed by app/native integration.
No new all-game public feed, native build or acceptance; release remains due
October29 21:06ET with no extension.


## October25,04:16ET — literal rule and schedule gates

Added seven explicit rule contracts and20 schedule groups/167 physical rows in
oklahoma_draw_rule_specs.json, with oklahoma_draw_rules.py enforcing identity,
eligibility, draw times, all match/prize/odds cells and four rich-text sections.
Presentation marks and whitespace are normalized; changed text, structural nodes,
assets/links, missing fields or changed schedule values require review. The
returned source data preserves categorical prizes, separate Double Play columns,
per-play Mega Millions multiplier groups and lifetime prize labels.

Reviewed every retained schedule row and the additional disclaimers. Pick3's
disclaimer explicitly provides Midday12:59PM and Evening8:59PM sales cutoffs,
whereas how-to-play only mentions the latter; this clarifies the schedule but
does not establish session identity for dated results. MFL how-to-play and
sales-cutoff disclaimer differ. Xs & Os legend prose contains both1 in12 and
1 in8.47 overall odds; both are retained without selecting a resolved value.
Lotto America's SB-only row literally lists1 in160.94 in all five schedules;
it is preserved, not mathematically corrected. Returned source notes identify
these limitations for subsequent app disclosure.

All seven retained HTML rule contracts pass. All31 Oklahoma Python tests pass,
including five rule tests checking every family's schedule drift, missing rules,
new assets, timing changes and prose versus presentation changes. No new source
retrieval, all-game feed publication, build or acceptance. Next implement coupled
atomic collection and correction/regression/failure retention, then app/native.
October29 21:06ET release deadline remains unchanged; no extension.


## October25,05:20ET — coupled collection and atomic retention

Added oklahoma_coverage.py to collect all seven draw/rule pages, both complete
product listings and every eligible product detail before replacing one snapshot.
The retained-source replay requires78 responses and yields12 results, seven rule
contracts,50 Scratch games and19 Fast Play games. Every source keeps its original
retrieval timestamp in this replay; the mixed earlier captures are not represented
as a fresh synchronized collection. The trial snapshot remains private.

Continuity rejects result corrections, newest-date regression, group loss and
holes inside a rolling result window. Product identity/metadata, prize structure
and original quantities must remain stable; remaining quantities may decrease.
Explicit-null inventory remains unknown, and variable progressive estimates stay
separate. Catalogs below the reviewed eligible baseline stop collection. Full
validation precedes fsynced temporary-file replacement; failures retain prior
snapshot bytes and dates and clean temporary files.

All38 Oklahoma Python tests pass. Additionally, replay injected a retrieval
failure at each of the78 request positions; every position retained the exact
previous snapshot bytes. Unit tests cover successful replacement, disk-replace
failure cleanup, correction/regression rejection, inventory increases and allowed
decreases/unknowns. No fresh source collection or public-feed deployment occurred.
Next perform a complete fresh collection, inspect any source changes without
weakening contracts, wire the coupled feed publisher and verify deployed bytes;
app/native gates follow. Release remains due October29 21:06ET, no extension.


## October25,06:20ET — fresh coupled baseline prepared

A complete78-request live collection finished October25 10:19:54.467830UTC.
All strict draw/rule/product checks and continuity against the retained private
replay passed. The new snapshot contains14 completed results/eight groups, all14
winner reports unavailable, two scheduled entries excluded, seven rule contracts,
50 Scratch games/653 numeric tiers and19 Fast Play games/219 typed tiers. Raw
responses and per-response hashes/times are retained privately under
work/oklahoma_scope/fresh_20261025_1018. No time was advanced by replay.

Prepared data/oklahoma_coverage.generated.json and docs/oklahoma_coverage.json,
258327 identical bytes, SHA256
f39d241ea318baca262f4fdb0dd431d02360ab7438035c8f8360392acd31c0b5.
The state refresh transaction now invokes the coupled collector and the publisher
stages the coupled feed. Legacy Scratch-only data remains unchanged with its
original date; the forthcoming app must consume the coupled snapshot. All512
Python tests pass, including38 Oklahoma tests. Deployment and independent live
byte verification are pending this commit; app/native and acceptance remain open.
Release deadline October29 21:06ET unchanged, no extension.


## October25 — initial coupled deployment verified

Production a9f3c2a deployed successfully in workflow40184377143. Independent
live fetch at 2026-10-25T10:22:17.841304+00:00 matched all258327 local bytes and
SHA256 f39d241ea318baca262f4fdb0dd431d02360ab7438035c8f8360392acd31c0b5.
All78 retained capture hashes were recalculated successfully. Initial coupled
feed deployment is closed; this is not app/native acceptance. Next implement the
strict Dart loader, bundled/cache continuity and visible draw/product experience,
then native flows and ordinary restoration. Deadline remains October29 21:06ET.


## October25,07:24ET — initial Dart loader and bundled baseline

Added an Oklahoma-specific loader, reviewed baseline contract and bundled coupled
feed asset. It validates all static metadata, rule structures, exact current
results and source URLs, checks retrieval timestamps, and accepts only bounded
numeric inventory decreases with original quantities and tier identities intact.
Progressive estimates remain independently nullable/positive. Cache continuity
also prevents inventory increases relative to the retained cache, even when the
new count would fit beneath the older bundled count. Controlled retrieval or
validation failure returns valid cache/bundle without writing bad bytes; a cache
write failure does not discard a valid remote response.

Seven Flutter loader/validator tests pass; the three new production Dart files
and test analyze clean. This is an initial fail-closed stage, not completed app
integration: changed draw dates/windows, catalog changes and transitions to
explicit-null inventory are still rejected against the baseline. Next implement
strict dynamic result/provenance and unknown-inventory contracts before visible
UI, then draw/product/native/cache flows and ordinary restoration. No native build,
source refresh or Oklahoma acceptance. October29 21:06ET deadline unchanged.


## October25,08:24ET — explicit unknown inventory and provenance joins

The Dart validator now accepts the collector's explicit unknown inventory forms:
Scratch requires empty tiers, null top remaining and the exact unknown notice;
Fast Play requires empty tiers and unavailable status. Missing or inconsistent
status still fails. Returned data retains those empty/null values without copying
baseline quantities or converting them to zero. Known inventory continues to
validate all original quantities and permit only decreases against known cache.

Every result, product detail and listing timestamp must now join its matching
source URL's retrieval timestamp. Duplicate sources and individual source-time
regression against cache are rejected even if the overall collection time grows.
Eleven Flutter loader tests pass; changed Dart/test analyze clean. Dynamic draw
advancement remains fail-closed and is next before visible UI/native integration.
No new source refresh, build or acceptance; October29 21:06ET deadline unchanged.


## October25,09:28ET — strict dynamic Dart draw windows

Added OklahomaDrawValidator and connected it to baseline and retained-cache
validation. Eight required result groups now accept bounded rolling dates with
exact static metadata, game ranges/cardinality, Pick3 ordered digits, literal
Xs & Os codes, multiplier variants, UTC/Chicago calendar conversion and source
retrieval joins. Completed results cannot be newer than their capture. Nested
Double Play must retain the same local date and a later timestamp than Powerball.
Unverified reports and Pick3 sessions remain unavailable; payload injection fails.

Continuity rejects corrections to overlapping dates, newest-window regression,
group loss and holes inside the rolling window, against both bundle and cache.
Scheduled counts are separately bounded and never become completed results.
Fifteen Flutter tests pass, including valid rolling advancement, cache rollback,
report/session injection, invalid codes, local-date mismatch and Double Play loss;
changed production/test Dart analyze clean. Numeric/unknown inventory handling
and exact rule contracts remain in force. Catalog identity/structure changes still
require review. Next visible draw/rule and typed Scratch/Fast Play UI, followed by
native source-return/layout/cache flows and ordinary restoration. No new source
refresh, native build or acceptance; October29 21:06ET deadline unchanged.


## October25,10:28ET — visible draw and rule sheet

Added the Oklahoma results/schedules entry on its state source screen, backed by
the coupled loader. Every dated selection shows local date, ordered numbers or
literal codes, applicable multiplier, capture time and unavailable report notice.
Pick3 explicitly lacks session history. Fixed paging exposes all literal rule
sections, source discrepancies and schedules. Powerball and Double Play display
separate prize columns; Double Play does not show Power Play multiplier schedules.
Mega Millions identifies per-play multipliers. Categorical and lifetime prizes
remain literal; no source report counts or code-to-team inference was added.

Two widget tests pass: all14 selections at2x text in portrait and landscape, and
fixed paging through all eight family/variant rule flows to coverage limits.
Changed production/test Dart analyze clean. This is automated widget evidence,
not native source-return or manual all-scale acceptance. Typed Scratch/Fast Play
UI is next, followed by ordinary native build and complete bounded flow checks.
No native build, new source refresh or Oklahoma acceptance; deadline unchanged.
