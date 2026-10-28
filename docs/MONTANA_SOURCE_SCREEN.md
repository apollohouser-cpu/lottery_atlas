# Montana source screen — September 14, 2026

The [Montana Lottery Scratch games](https://montanalottery.com/scratch-games/)
page publishes games and prize odds. Odds and printed prize inventories are
not actual winning-ticket or claim counts. No complete all-tier draw and
Scratch winning-ticket export, correction contract, or retailer-linked winner
dataset has been verified, so Montana is not ready for a statewide total or
retailer heat ranking.

The [Lottery contact page](https://montanalottery.com/contact/) directs
public-information requests to the state [OPIR](https://doa.mt.gov/opir/)
system. OPIR lists the Montana Lottery among its agencies. The ArkCase
“New Request” route led to an MT.gov sign-in screen on September 14, 2026;
no formal portal request was filed. The contact page also publishes the
general address `montanalottery@mt.gov`.

On September 14, 2026, a data and records-routing inquiry was sent to that
address. It asks for existing electronic all-tier draw and Scratch counts,
their definitions, dates and refresh cadence, retailer directories and public
selling-retailer references, and the supported submission route. It excludes
winner-identifying private information and discloses a public application.
Gmail confirmed “Message sent.” This inquiry is **not** a formal OPIR filing.
No substantive response or complete ticket-count dataset has been received.

Later September 14: The Lottery replied that it does not manage OPIR and
directed portal access issues to `publicrecords@mt.gov`, suggesting an Okta
password reset. No existing Okta account is known. An inquiry to that official
records address asked how a new requester can create an account or use another
accepted filing route, and whether email is accepted. Gmail confirmed it was
sent. This is still not a filed formal request; no ticket-count data arrived.

Later September 14: The OPIR help desk replied that a new requester should
visit `https://login.mt.gov`, scroll to “Don't have an account? Sign up,” and
follow the account-creation instructions. It attached instructions.

On September 16, 2026, the MT.gov account was created and verified, and a
formal request was submitted through OPIR to `LOT - Lottery`. It requests
September 1, 2025 through August 31, 2026 all-tier draw and Scratch records,
retailer records and joins, definitions, cadence, corrections and any existing
recurring source, with a fallback to the most recent complete month. Delivery
is through the web portal; the requester asked for an estimate before any paid
processing. The portal displayed a successful-submission confirmation. Its
confirmation email arrived at 2:58 a.m. Eastern on September 16 and assigned
case `the private request reference` (queue: Intake). No responsive dataset has arrived.
At 11:00 a.m. Eastern, OPIR sent a formal acknowledgment letter confirming
receipt under that same case number. It says OPIR will review the request,
clarify or deny if necessary, or provide records, and will supply a cost
estimate as soon as possible if staff time is billable. The letter includes
general timing guidance, not a committed delivery date for this request.

## September 20, 2026 full listing audit

Fetched all 11 pages of the official Scratch catalog using its published
`e-page-eeedf9c` pagination links. The pages contain 53 unique CMS listings
and 1,032 rows under `WIN / PRIZE / ODDS`. Each listing has one explicit
price taxonomy; every listing has a prize table. These are prize structures
and odds, not remaining inventory, dated winning-ticket counts or claims.
No remaining-count series was established in this audit.

Special prizes require semantic handling. Can-Am lists a vehicle valued at
$53,583, a separate $50,000 cash prize, and a second-chance vehicle row with
`1:0.00` odds. Selecting the largest numeric prize would wrongly flatten
vehicle and second-chance semantics into a cash top prize. Free-ticket rows
use the label `Ticket` and must not be turned into cash. Repeated cash amounts
can represent different winning combinations rather than duplicate rows.

CMS post IDs identify website entries, not printed lottery game numbers.
Some official game-spec image filenames include apparent game numbers, but
those have not yet been independently matched to printed ticket identities
for all 53 entries. Do not manufacture an identity from a CMS ID or assume
all published listings are currently on sale. Verify game identities and
closing/claim notices before publication; remaining counts should stay unknown
unless a separate official inventory source is verified.

Read-only audit files live under ignored `work/montana_catalog/`: all 11
HTML pages, `audit.py` and `audit.json`. No Montana public catalog or activity
feed changed during this pass. OPIR case the private request reference remains pending.

### September 25 release notification — documents not yet inspected

Gmail notification at 15:09 UTC marks the private request reference complete and says
released documents are available. The official Open Documents link redirects to
MT.gov sign-in; no released file is attached to the notification. This supersedes
pending-request status but is not yet an inspectable data delivery.
A standard no-fee delivery follow-up was sent to the notification's assigned
contact, celina.clift@mt.gov, requesting the already released files by attachment
or a direct download without a new account. Sent Gmail notification.
No additional assembly or fees were authorized. Monitor that delivery reply;
Montana implementation remains queued while Kentucky stays active.

### September 25 workbook emailed

The delivery follow-up succeeded: Gmail notification at 16:25 UTC attaches
the released workbook (220,068 bytes). Rebecca Narmore directs subsequent questions to
rebecca.narmore2@mt.gov because the request is closed. The login-only delivery
obstacle is resolved. Gmail marks this application/octet-stream attachment as
unsupported for connector extraction; do not call its attachment reader for it.
The workbook still needs a private browser download and content/semantics audit.
Do not count it as inspected or publish any new Montana claims from this notice.

## October 27, 2026 at 23:30 EDT — sole active state

Montana activates after North Dakota acceptance. See MONTANA_ACCEPTANCE.md:
full scope/gap matrix due October28 at23:30EDT; supported release due November1
at22:30EST (November2 at03:30UTC), fresh120elapsed hours across DST, no extension.
The September Scratch catalog and workbook delivery are foundations, not current
all-game acceptance. Workbook semantics remain unaudited; do not resend the
confirmed delivery request or promote private records without auditing them.

Opening direct HTTP requests to the official home page returned403, including
an ordinary browser user-agent attempt. www home/Scratch variants also returned
403; these failed response bodies, hashes and actual capture times are retained
privately in work/montana_scope/opening-manifest.json, not successful source
captures. The read-only web tool could read the official home page, establishing
an alternate research path but not production transport recovery. Next inspect
all official game/history/rule links and establish a repeatable permitted capture
path before publication. No prior valid data bytes or dates were replaced.
Administrative request/message identifiers removed from this public source screen;
the original audit copy is retained privately. No new feed, build or acceptance.

## October 28 — successful game-page capture and expanded product screen

Ordinary curl retrieval of the linked /games/ page succeeded, followed by13
successful official page responses in a14-page scope pass. The Can-Am navigation
link returned404 and remains unavailable; no bypass or altered validation was
used. The home/www403 attempts remain historical failures, not overwritten
successful captures. The in-app browser also rendered the games page. Successful
game-page transport does not prove home-page recovery or production publication.
Original bytes/status/timestamps/SHA256 are private in scope-manifest.json under
work/montana_scope. Pagination followed only official links: twelve Scratch pages
expose57 CMS entries/1,157 physical table rows including headers; three Treasure
Play pages expose12 entries/64 physical rows. These are catalog/schedule structures,
not remaining stock, claims or accepted game identities. Original pagination
captures are in pagination-manifest.json; no public feed or new native build.

The current navigation establishes six regular draw families (PB, MM, MFL,
Lotto America, Montana Cash and Big Sky Bonus), Power Play/Double Play,
All Star Bonus, Max Cash, Montana Millionaire raffle, Scratch, Treasure Play and
a sportsbook link. Sports wagering stays a source-linked boundary, not automated
betting or fabricated lottery draws. Full retired/history/status reconciliation
and strict rules remain open before scope closure.

Concrete source hazards now recorded: Big Sky Bonus headline shows October27
while its history table starts October26; never join headline numbers to another
date's report. PB Double Play winner table has one row per date with a jackpot
match label and a large count; report units/geography and schema remain unverified.
PB Double Play schedule headings say Match/Odds/Prize while body money/odds order
is reversed. Montana Cash purchase prose mentions Double Play and inconsistent
per-play costs; preserve and disclose source discrepancies rather than infer a
new variant. All exact-date winner reports remain unavailable pending validation.
Montana Millionaire advertises November1 sales and November30/December28,2026
promotional/final drawings; its historical table begins December26,2025. Planned
prize quantities and older raffle results must never become current winners.

Next inspect literal rule contracts/results implementation, retired/status links,
complete typed catalogs and privately delivered workbook. Scope due October28
23:30EDT and release November1 22:30EST unchanged, no extension. Montana sole
active;20accepted25unfinished. Android ordinary app remains running; no iOS start.

## October 28 at 01:34 EDT — supported scope closed

The fixed full product/history/gap matrix is in MONTANA_ACCEPTANCE.md. Regular
draw target:14 date-only results/seven groups, all count reports currently
unavailable. Scope also includes all published Scratch/Treasure Play catalogs,
Montana Millionaire offer/status, retired Lucky for Life, unavailable Can-Am
promotion, second-chance limits and a separate sports-wagering source boundary.
The linked Scratch ending-date PDF requires audit; catalog listing alone never
establishes active sales, remaining prizes or printed game identity. No new source
retrieval timestamp, feed, native build or acceptance is claimed in this decision.
Scope closed early; release November1 22:30EST unchanged without extension.

## October 28 — strict date-only draw parser

Implemented tooling/import_montana_draws.py against hash-verified retained official
history tables. All709 source rows validate across seven groups: PB79, DP79,
MM52, MFL184, LA79, Montana Cash52 and Big Sky Bonus184. Private latest-two
candidate has14 results. This reuses original October28 capture timestamps;
no new live source verification or public feed is claimed.

Parser binds page title, exact result-table inventory/headers, unique descending
dates, weekday cadence, Mountain capture-day bounds, number cardinality/ranges,
separate DP and bonus identities, and PB/LA multipliers. April26,2026 is the
reviewed source-window floor, not a game inception date. Montana Cash advertised
base plus Max Cash must reconcile to the combined amount, but those estimates
are not promoted as actual payouts. Headline widgets and winner tables cannot
supply dates/numbers/counts. All reports remain unavailable; MM has no inferred
draw-wide multiplier and date-only results have no invented instant.

Twelve focused tests pass, including all retained tables, variant separation,
headline/report isolation, identity/header/table mutations, invalid numbers,
date/cadence/order/capture failures, multiplier/amount errors, merged/unclosed
cells and retired-game rejection. Public fixtures contain extracted official
result tables only. Next literal rule contracts, typed catalog/status and private
workbook/ending-notice audits, then coupled publication and app/native flows.
No native build or acceptance; Montana sole active, release November1 at22:30EST
unchanged without extension. Android remains running; iOS not started.

## October 28 — literal draw-rule contracts

Added six strict family rule contracts covering How to Play, About, Prizes and
Odds, plus Powerball's separately placed Double Play schedule. Seventy physical
table rows include headers: PB/DP20, MM10, MFL10, LA10, Montana Cash6, Big Sky
Bonus14. Literal text, links/image references and table cells/spans are retained;
changed conditions/prizes/identity or missing sections fail closed. These are
HTML text/table contracts, not image-content or brochure visual audits. Rule
images are references only and do not independently establish omitted terms.

Reviewed source text establishes Montana Power Play included with PB, separate
optional DP unaffected by Power Play, MFL annual prizes, and Big Sky Bonus base
versus combined-bonus schedules. Source discrepancies stay literal and require
visible qualification: DP headings reverse body odds/money order; Montana Cash
purchase text conflicts with its About cost and mentions DP; PB About contains
an unverified United Kingdom sales claim. These statements are source prose,
not independent geographic coverage assertions. No invented variant or correction.

Twenty focused Python tests pass (12 results,8 rules), including changed prizes,
conditions, identities, section inventory, cell spans/duplicate attributes and
malformed markup; harmless whitespace/headlines do not alter the contracts.
Retained capture hashes were verified before extraction; original source dates
are unchanged. Next typed catalogs/status, private workbook/ending-notice audit
and coupled publication, then app/native. No public feed/build or acceptance;
Montana sole active and November1 22:30EST unchanged without extension.
