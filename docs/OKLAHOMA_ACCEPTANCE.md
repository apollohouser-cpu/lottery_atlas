# Oklahoma supported coverage acceptance

Status: **ACTIVE — not accepted**, sole active state from October24,2026 at21:06ET,
after Idaho acceptance. Sixteen states accepted;29 unfinished including Oklahoma.

- Full supported scope/gap matrix due October25 at21:06ET.
- Supported release decision due October29 at21:06ET.
- Fresh120 elapsed hours for substantial draw/Fast Play/app integration.
- Extensions used: none. Finish early when evidence passes.

## Selection and opening evidence

Oklahoma already has a strict no-end-date Scratcher importer and app bundle,
but no accepted all-game draw/Fast Play experience. This partial catalog does
not qualify as a complete working import for a72-hour window. The September16
agency denial remains a separate unavailable-records outcome; no repeat request
or fee is necessary for supported completion.

Five official responses were captured with UTC retrieval timestamps and SHA256
hashes under private work/oklahoma_scope/opening-manifest.json: home, Powerball,
Mega Millions, one Fast Play detail and the Scratcher listing. The home links
Powerball (including Double Play), Mega Millions, Scratchers and Fast Play.
This is an opening inventory, not yet an exhaustive current/retired-game matrix.
The existing listing parser finds102 listed Scratchers and50 eligible no-end-date
entries; detail inventory has not been freshly validated in this pass.

The draw pages' server-rendered body does not expose the game content, but the
embedded Next payload contains CMS rules/legends and nested draw results. PB
includes a SCHEDULED row with empty numbers/tiers and separate Double Play data.
Never convert that into a completed result or zero winners. UTC drawingDateUTC
and drawDateTimeUTC differ from Oklahoma local calendar dates: the home renders
October22 for the PB timestamp2026-10-22T02:59Z. Validate America/Chicago draw-date
semantics before importing; do not copy that UTC day as the local drawing date.

Prize-tier payload fields include share counts, multiplier counts and MM per-play
multiplier arrays. Their geographic/count semantics are unverified. Do not label
these Oklahoma ticket counts or national totals until source evidence establishes
which they are. Zero shareAmount fields do not establish actual zero payouts.
Fast Play Extreme Green Progressive254 shows separate remaining/total tier
quantities and a dynamic progressive estimate; do not infer claims or treat that
estimate as a fixed tier prize. Full schedules and unknown statuses need review.

## Gates and next work

- [ ] Exhaustive current/retired product and history/gap matrix within24 hours.
- [ ] Review dated-result identity/status/timezone, count units and literal rules.
- [ ] Validate full Fast Play and fresh Scratch inventory with explicit unknowns.
- [ ] Coupled atomic publication, continuity/correction and failure retention.
- [ ] Strict app loader/bundle/cache and visible all-product UI.
- [ ] Native selection, sources, paging, filters, enlarged/layout and cache checks.
- [ ] Ordinary restoration, appropriate tests and independent live verification.
- [ ] Supported acceptance with explicit unavailable features.

No new public feed, source-date advancement, app build or Oklahoma acceptance
is claimed by activation. No retailer coordinates/joins, complete claims/history,
store stock or progressive inference. Preserve existing validated bytes/dates on
refresh failure. Next inspect the full navigation and draw CMS contracts, map
all product/history gaps, and test source-date/count semantics before publication.


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
