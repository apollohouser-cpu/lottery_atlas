# Oregon source screen — September 12, 2026

Oregon is **not yet approved for the launch heat map**. Keep the existing Oregon
importers and initial catalog; do not add Oregon to the approved activity feed
until the winner-location source gate passes.

- The official retailer API used by `tooling/import_oregon_retailer_directory.mjs`
  returned 3,761 active retailer rows with addresses and published coordinates;
  the importer reported zero unresolved coordinate rows. The response count
  alone does not independently establish that the API returned every active
  retailer statewide.
- The official Scratch-it API used by
  `tooling/import_oregon_scratch_catalog.mjs` returned 55 currently for-sale
  games with price, top prize, and remaining top-prize count.
- The [official winner list](https://www.oregonlottery.org/winners/list/) says
  that its statewide list is currently unavailable. The visible winner stories
  do not constitute a comprehensive retailer-level winner activity feed from
  January 1, 2026 onward. Oregon Lottery's
  [winner-anonymity policy](https://www.oregonlottery.org/winner-anonymity/)
  permits release of the selling retailer, but does not itself supply the
  required historical feed.

Next step: obtain an official comprehensive winner export with game, prize,
win date, selling retailer identifier or exact address, and source provenance.
Confirm that the retailer API response is a complete statewide active roster.
Then normalize and validate the records before enabling Oregon in the app.

On September 13, 2026, a data inquiry was sent to
`publicaffairs.lottery@lottery.oregon.gov`, the contact listed on the
[Lottery's official legal page](https://www.oregonlottery.org/about/legal/).
It asks for existing draw and Scratch-it winning-ticket/claim counts,
retailer-linked winner records, count definitions, refresh cadence, and
confirmation of retailer API completeness. Gmail confirmed “Message sent.”
The [official records request form](https://www.oregonlottery.org/public-information/request-form/)
is available if the Lottery routes the inquiry to that process. This request
does not change the current source gate.

Update September 16: Jessica Nelson, Oregon Lottery Records Management
Consultant, replied that the Lottery does not offer API data access and
directed this inquiry to its [official public-records form](https://www.oregonlottery.org/public-information/request-form/).
That statement concerns requested data access; the already observed public
retailer and Scratch-it endpoints still require their own provenance and
completeness checks. The formal 2026 year-to-date request was submitted on
September 16 through the linked Wufoo form. The confirmation said “Public
Records Request received.” It asks for existing all-tier draw and Scratch-it
counts, retailer roster and selling-retailer joins, with a recent-month sample
accepted only as a first format check. No fees were authorized. Responsive
records and a repeatable update route remain pending.

An Oregon Lottery confirmation email also arrived at 7:26 p.m. ET September
16 and explicitly confirmed receipt of the public-records request.

## September 20 catalog refresh

The official public Scratch-it API returned 467 records and `NextItems: 0`;
51 records fall within their published availability dates as of retrieval.
`tooling/import_oregon_scratch_catalog.mjs` now validates pagination, unique game
numbers, calendar dates, positive integer prices/prizes and nonnegative integer
unclaimed top-prize counts. Missing counts are rejected rather than coerced to
zero. Ended and future games are excluded, and redemption deadlines are retained
where published. Five regression tests cover source semantics, date boundaries,
unknown versus zero counts, duplicate/truncated responses and redemption dates.

The [official Scratch-it list](https://www.oregonlottery.org/scratch-its/list/)
says prize/ticket information updates once daily and defines top prizes
unclaimed as not yet redeemed, which does not establish store stock. The new
catalog notes preserve that definition, daily cadence and retrieval date;
a separate source publication timestamp is not supplied by this response and
is not invented. The six-hour publisher now checks this catalog and includes
its validated output in the combined state catalog feed. The bundled snapshot
is refreshed for offline use.

This adds a dated game inventory only. It does not establish complete statewide
winning-ticket counts or authorize Oregon retailer heat points. The existing
public-records request and the retailer/winner-location coverage requirements
remain pending. Catalog testing is a separate milestone from full-state
completion; deployment verification is reported in the task.

## October 5 agency delivery

Oregon supplied two attachments, Draw Game Sales 10.5.26.xlsx (357,288 bytes)
and Active Retailer List Statewide 10.5.26.xlsx (496,125 bytes), plus a private
access link described as sales and commission reports from 2015 to present.
The agency warns that historical reports come from different systems with
varying fields and time periods and offers to check for missing material.
No fee is stated. The private access token and requester details are not public.

Attachments and linked reports require private schema/privacy/period audits.
Sales and commissions are not winning-ticket or claim counts. Neither attachment
name nor this response establishes delivery of all requested prize-tier counts,
Scratch claims, winner joins, definitions or an update commitment. No new layer
is approved by receipt alone. No acknowledgment or follow-up sent this session.

## October 5, 17:35 ET — private attachment audit

Both original XLSX attachments were downloaded into ignored private storage;
byte sizes match the agency delivery. Read-only workbook audits leave originals
unchanged. Neither workbook is promoted to a public feed.

The retailer Export sheet has 3,690 business rows with unique account IDs,
plus a total, blank row and applied-filter footer. The footer limits the export
to active regular retailers and excludes an administrative account. This is a
filtered roster, not proof of every possible account class. Of the business rows,
1,521 have both traditional and video flags, 1,675 traditional only, and 494 video
only: 3,196 traditional-enabled accounts and 2,015 video-enabled accounts.
These are source flags, not observed inventory or winning activity. The workbook
has no coordinates. Names and business location fields may support reconciliation
with the official public locator, but positions must come from verified sources.

The attachment also includes primary contact names/phones, shipping addresses,
and parent-account fields. Keep those fields private and exclude them from public
artifacts. Account IDs remain private join evidence unless independently verified
as public locator identifiers. Do not copy full workbook rows into public tests.

The sales Export sheet has 3,980 named dated rows, two additional dated rows
without business identity, a blank row and a filter footer. The named rows span
December 28, 2025 through September 26, 2026; the identity-less rows extend through
October 2. The footer specifies business calendar year 2026, which must not be
silently relabeled calendar-year-to-date. Per-row periods vary and none reverse.
Eight game-sales columns and Total use dollar formatting, including fractional
Pick 4 values and 11 negative numeric cells across named rows. These are monetary
sales measures, never ticket/claim counts. The source's Total differs from the
arithmetic sum of the eight displayed game columns on 3,205 named rows. Preserve
source values privately; aggregation and adjustment semantics remain unresolved.

Sales lacks retailer ID and street address. Exact normalized name/city/county
matches find a unique active roster candidate for 3,650 sales rows, ambiguous
candidates for 18, and no candidate for 312. The roster itself has 18 duplicate
name/city/county keys. A unique text candidate is not an approved historical
retailer join; no sales heat layer or winner layer is authorized by these matches.
The private 2015-present archive remains unaudited. No email sent; broader claims,
counts and repeatable delivery definitions remain separate open gaps.

Next reconcile the full product scope and public locator schema, then implement
an allowlisted directory with explicit traditional/video coverage and strict
coordinate/identity validation. The old importer uses a minimum-row heuristic
and calls its output complete; that assertion needs replacement with evidenced
source coverage before app integration.

## October 5, 18:36 ET — product roster and live report discovery

The official [games index](https://www.oregonlottery.org/games/) and
[jackpot index](https://www.oregonlottery.org/jackpot/) establish the following
scope. Source routes are required even where report ingestion remains unverified.

| Product | Official route | Integration/gap |
| --- | --- | --- |
| Powerball / Power Play | [Results](https://www.oregonlottery.org/powerball/winning-numbers/) | Live Oregon share counts/prizes found; multiplier overlap requires reconciliation, no separate Double Play support established. |
| Mega Millions | [Results](https://www.oregonlottery.org/mega-millions/winning-numbers/) | Current renderer exposes aggregate Oregon winners/payout; old tier-shaped API fields must not be treated as current tier evidence. Pre-April 8, 2025 archive is separately linked by the page. |
| Megabucks | [Results](https://www.oregonlottery.org/megabucks/winning-numbers/) | Live shared-prize tiers found; preserve cents and match/kicker labels. |
| Win for Life | [Results](https://www.oregonlottery.org/win-for-life/winning-numbers/) | Live tiers found; top API 52000 is rendered as $1,000 a week, not a cash award. |
| Pick 4 | [Results](https://www.oregonlottery.org/pick-4/winning-numbers/) | Live timed draws found; renderer groups equal prize amounts and sums their counts. Do not label these unique people or invent wager/tier matches. |
| Cash Pop | [Results](https://www.oregonlottery.org/cash-pop/winning-numbers/) | Live aggregate winners/payout found; renderer uses rounded scheduled time. No per-tier split established. |
| Keno | [Product/live board](https://www.oregonlottery.org/jackpot/keno/) | Include Special Keno, Bulls-Eye, Multiplier, 8-spot bonus and Keno To Go options. Static prize odds are not actual draw counts; results/schema still to audit. |
| Scratch-its | [Catalog](https://www.oregonlottery.org/scratch-its/list/) | Existing 51-game catalog; remaining unclaimed prizes are not stock or recent wins. |
| Second Chance | [Information/results links](https://www.oregonlottery.org/second-chance/) | Separate Scratch-related drawings; source route, no automatic entry or count inference. |
| Raffle | [2026 product](https://www.oregonlottery.org/jackpot/raffle/), [ticket checker](https://www.oregonlottery.org/raffle/winning-numbers/check/) | Separate seasonal draw; advertised prize allocation is not claims received. |
| Video Lottery | [Product](https://www.oregonlottery.org/video-lottery/) | Separate product/source route and directory coverage; no invented draw/retailer-winning feed. |
| Sports | [Official provider information](https://www.oregonlottery.org/sports/) | Source route only; no sportsbook wagering integration or inferred counts. |
| Historical Lucky Lines | [Legacy product](https://www.oregonlottery.org/jackpot/lucky-lines/) | Official [Cash Pop launch notice](https://www.oregonlottery.org/press-releases/cash-pop-launches/) identifies January 12, 2025 as final draw. A zero sales column does not establish current availability. |

Captured the public site's API wrapper and results renderer privately, then made
bounded October 1–4 requests to its observed `drawresults/ByDrawDate` endpoint.
Selectors pb/mm/mb/cp/wf/p4 return HTTP 200 with dated records; wf is the renderer's
Win for Life selector. An initial wfl probe returned 400 and was corrected from
source code, not interpreted as product unavailability. No report promoted.

The common schema includes misleadingly reusable field names. For current Mega
Millions and Cash Pop, `buildJackpotTable` selects OregonJackpotWinners and
JackpotShareAmount as aggregate Winners/Payout; it does not render the remaining
arrays as tiers. The October 2 Mega Millions example is 2,696 winners/$51,967,
not 2,696 jackpot winners. Cash Pop October 4 22:00 example is 14/$380.
Powerball, Megabucks, Win for Life and Pick 4 instead use concatenated Oregon
counts/prize arrays, excluding outside-state fields. Pick 4 combines equal prizes;
Win for Life changes the 52000 label to a weekly lifetime prize. The Powerball
page explicitly warns that some million-dollar winners also won a multiplier
award, so do not independently sum overlapping buckets into unique tickets.

These observations establish parser candidates, not accepted report units or
full scope closure. Next reconcile renderer tier labels, count units and date/time
provenance, inspect Keno and historical routes, then close the supported scope
matrix before its existing October 6 deadline. Gmail check found no new messages;
no reply, private attachment promotion or deadline change.

## October 5, 19:38 ET — supported scope closed

The product matrix above is the full supported scope for this release, closed
before the October 6 checkpoint. Scope closure defines work and explicit gaps;
it is not release acceptance. No further broad product research is required.

Implement dated reports for six families: Powerball, current Mega Millions,
Megabucks, Win for Life, Pick 4 and Cash Pop. Counts must be labeled source-reported
Oregon winners, with distinct tickets/people unverified; no cross-tier total or
retailer heat placement. Powerball's nine source prize rows may retain the
published multiplier as context, but must not generate separate Power Play
counts/awards. Megabucks preserves the seven renderer rows and shared prize
amounts. Win for Life preserves the weekly top-prize wording. Pick 4 groups
identical prize amounts as the renderer does without inventing wager labels.
Current Mega Millions/Cash Pop are single aggregate winners/payout reports,
not tier tables. All reports require finalized source records, draw identity,
actual displayed date, retrieval provenance and continuity validation.

Original API wall-clock strings are retained; they have no offset. Cash Pop's
wrapper explicitly substitutes RoundedDrawDateTime for display. Other families
use DrawDateTime, with time retained for Pick 4 sessions. Do not convert these
values to synthetic UTC activity timestamps or claim a retrieval time is a draw.

A bounded [Keno history](https://www.oregonlottery.org/keno/winning-numbers/)
API request returned 344 October 4 records. The observed schema contains draw
number/time, winning numbers, Bulls-Eye, multiplier and 8-spot bonus; it contains
no winner-count or paid-prize fields. The bonus is not a paid total. This result
is a bounded schema observation, not proof that no other records exist. Keno and
its options remain official-source routes for this release, as do Raffle, Second
Chance, Video Lottery, Sports and historical Lucky Lines. The verified
[previous Mega Millions page](https://www.oregonlottery.org/mega-millions/mega-millions-winning-numbers-previous/)
provides a separate historical route; do not mix that version with current reports.

The catalog and a validated public-coordinate retailer directory remain release
requirements. Agency sales/private archive audit is separate; no complete claims,
sales-derived winning counts or fabricated winner locations will be included.
Unsupported activity must be explicit in the app rather than represented as zero.

Added strict current Mega Millions/Cash Pop aggregate parsers. They allowlist
output fields, reject missing/invalid counts and money, reject nonfinal/version
changes and historical MM, validate calendar/scheduled times, retain explicit
zero, and leave winningTickets null. Three synthetic regression tests pass;
private captured data yields one MM and 32 Cash Pop reports. No generated/public
feed changed. Next implement the remaining four report parsers and continuity,
then directory reconciliation and integration. Gmail found no new mail; no reply.

## October 5, 20:39 ET — remaining strict report parsers

Added Powerball, Megabucks, Win for Life and Pick 4 parsing to the same allowlisted
report module. Source arrays must contain exactly 16 entries; expected populated
rows and unused zero padding are both checked. A newly populated unknown row,
missing value, negative/fractional count or malformed money fails closed. Output
excludes outside-state fields and never computes a distinct-ticket total.

Powerball retains nine published rows and multiplier context without multiplying
prizes or inventing Power Play allocations. Megabucks retains seven rows and
fractional dollar values. Win for Life retains seven rows with the top value
represented as $1,000 a week for life and no cash-dollar equivalent. Pick 4 groups
all 17 source entries by exact prize cents, preserving contributing row numbers
and reported counts, and validates its four observed source times (13/16/19/22).
Match labels are verified for Powerball; unverified Megabucks/Win for Life match
labels and Pick 4 wager labels are deliberately null, while prize rows remain.
This narrows presentation honestly rather than guessing from decorative icons.

Six parser tests pass, including array/padding rejection, explicit zero versus
missing, aggregate exclusion, weekly/shared prize semantics and Pick 4 grouping.
All captured six-family data validates privately: PB 1, MM 1, Megabucks 1, Win for
Life 1, Pick 4 8 and Cash Pop 32 reports. The first captured Pick 4 report reduces
to 11 distinct prize amounts; this is a report grouping, not a claim count.
No source/public generated feeds changed. Next bounded live selection, duplicate
and per-session date/draw continuity checks, and atomic report import. Directory
reconciliation and app integration follow. No new Gmail, email or deadline change.

## October 5, 21:39 ET — bounded live report import

Added the six-source atomic report importer. It requests a bounded 14-day window
through the already observed official endpoint, rejects responses reaching the
1,000-row cap, validates every returned row, and selects the latest two finalized
reports per game/session. This yields 48 reports: two each for PB/MM/Megabucks/Win
for Life, two for each of four Pick 4 times and two for each of 16 Cash Pop times.
A partial newer day may coexist with the actual prior date for other sessions;
missing sessions are never zero-filled or silently removed.

Duplicate draw IDs/date-session slots, non-increasing draw numbers, regressed
per-session dates/numbers and changed retained draw identities fail closed.
All six source fetches and validation finish before the temporary file is renamed;
source failures leave prior bytes and retrieval date untouched. Corrupt retained
JSON also stops rather than being silently discarded. Private live import passes
with all 48 reports; no report file was promoted or wired to publication yet.

The wider live window exposed one legitimate shared-prize case in Megabucks:
September 28 has a published zero prize with zero winners for one expected row.
The captured official renderer explicitly displays only positive prize amounts.
The parser now omits that exact zero/zero row while preserving source ordinal
positions; missing/non-numeric values, nonzero counts against zero prize, and
populated unknown padding still reject. This is a verified source variant, not
an exemption for missing data. Eight focused tests pass, including failure at
each source with byte retention, duplicate/session/regression/identity failures,
and this zero shared-prize case. Next public directory reconciliation/validation,
then report bundle/cache and UI integration. No new mail or email sent.

## October 5, 22:39 ET — public locator reconciliation and validation

A fresh request to the established official locator endpoint returned 3,764
unique ACTIVE entries. All have finite published coordinates within the Oregon
bounding sanity range; no missing coordinates were observed. This is the count
of returned public entries, not independent certification of statewide coverage.
Product flags differ: 514 entries are video-only, 43 video/Keno without draw or
Scratch, and 41 have all four product flags false. Preserve explicit flags; do
not label every entry a Scratch or draw retailer or infer store inventory.

Private comparison to the filtered agency workbook matches 3,686 public IDs
(after private leading-zero normalization), with 78 public-only and four agency-
only entries. All matched names/cities/counties agree after whitespace/case
normalization; street strings agree on 3,600 of those matches. This establishes
material source differences, not which source is wrong. Do not backfill public
coordinates/addresses from contact or shipping fields, or guess missing joins.
The approved directory candidate uses only the public locator fields; agency
records and the detailed reconciliation remain private.

Reworked the existing importer to export a strict allowlist, retain draw/Keno/
instant/video flags, validate active status/identity/ZIP/unique IDs/coordinates,
reject capped or anomalously small responses and use atomic replacement. The
3,500-row floor is explicitly an anomaly guard, not a completeness assertion.
Missing coordinates stay unresolved; invalid numeric/out-of-bounds coordinates
fail rather than becoming map points. Phone/contact/game inventory/other raw
fields are excluded. Unchanged rows retain the existing retrieval date; source
or validation failure preserves baseline bytes. Three focused tests pass, and
the captured live payload validates privately to 3,764 mapped/zero unresolved.
No generated public directory promoted yet. Next report bundle/cache and directory
model/UI integration, then shared publication transaction/native acceptance.
Gmail has no new mail; no email or deadline change.

### October 5, 23:39 ET — report bundle/cache loader

Added the validated 48-report public-source snapshot as a Flutter asset and an
Oregon-specific remote/cache/bundle loader. Validation requires all six families,
two reports per each of 24 game/session groups, source date/time consistency,
unique draw identities, increasing draw numbers and verified source routes.
Aggregate dollars/counts remain separate from tier prizes; lifetime top prize
keeps its weekly label/null cash equivalent, and winningTickets remains null.
Invalid payloads or regressions cannot overwrite retained cache; remote/persistence
failure falls back without inventing dates. Four loader tests pass and focused
analysis is clean. No report UI navigation or public endpoint is wired yet.
Directory product-flag model/UI integration is still pending. Next report sheet
and directory integration, then publication transaction/native acceptance. No
new mail, email, deadline change or acceptance claim.

### October 6, 00:40 ET — report sheet integration

Oregon's state-source screen now opens the 48-report sheet. Each selection shows
its actual source draw date/time and number, source-reported winner units, distinct
ticket/person uncertainty, retrieval time and cadence. MM/Cash Pop show aggregate
payout dollars; other games show literal prize rows, weekly lifetime wording,
source-row grouping and multiplier context without synthesized allocations.
Eight separate official product/historical routes cover Keno/options, Scratch,
Second Chance, Raffle, Video, Sports, Lucky Lines and previous Mega Millions.
Both compact and wide widget tests render all 48 reports and reach the footer
without layout exceptions; focused analysis is clean. This is widget integration,
not native acceptance. Directory flags/UI and publication transaction remain next.
No new mail, email, deadline change or acceptance claim.
Ordinary macOS debug build passes; it has not been relaunched for this sheet.

### October 6, 01:41 ET — directory product integration

Bundled the previously validated public-locator snapshot: 3,764 mapped entries,
zero unresolved. Only the importer allowlist is promoted; agency workbook contact,
shipping and private reconciliation data remain excluded. The shared retailer model
now preserves all four explicit product flags through serialization; Oregon rows
with missing or nonboolean flags reject instead of inferring offered products.
The directory list and detail show source-listed draw/Keno/Scratch/Video products,
including video-only and all-false entries, with stock and completeness warnings.
Five model/snapshot tests pass, including every bundled row and invalid flag cases;
four-file analysis is clean. This is bundled integration, not native acceptance
or proof of the public combined feed. Publication transaction/report endpoint and
native checks remain next. No new mail, email, deadline change or acceptance claim.
Ordinary macOS debug build passes; not relaunched for directory acceptance.
