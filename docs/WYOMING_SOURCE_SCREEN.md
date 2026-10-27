# Wyoming source screen — September 15, 2026

Wyoming is **not ready for complete verified heat-map testing**.

- The official winner list is limited to prizes of $100 or more, so it cannot
  establish all-tier winning-ticket totals.
- WyoLotto currently lists Powerball, Mega Millions, Cowboy Draw, Millionaire
  for Life, 2by2 and Keno. No Scratch product was identified in the official
  game catalog.
- The official retailer finder is interactive; a complete current export with
  stable retailer identifiers and winner joins has not been verified.

The website's earlier Public Records link returned a 404. A request was sent
September 15 to the published media contact, who supplied the corrected
[official public-records form](https://faq.wyolotto.com/support/tickets/new?ticket_form=request_for_public_record).
The public-records request was submitted successfully on September 16, 2026;
the portal confirmed that the ticket was created. It requests an electronic
export for the most recent complete 12-month period, including all-tier draw
and Scratch records where maintained, retailer records and identifiers, joins,
definitions, cadence, and any existing regularly updated report, API, dataset,
or file. It also permits the most recent complete month if the full period is
burdensome. No fees were authorized.

## September 21 agency response and limited-data path

David Stevens, Chief of Security & Enforcement, declined the requested winning-
ticket data citing winner anonymity, declined a retailer-list export, and said
retailer joins are limited to the public winners list. He directed us to
`https://wyolotto.com/wyo-wins`, `/find-retailer`, and `/wyo-wins/winners-list`.
He confirmed that Wyoming offers no Scratch or instant-ticket games and asked
for clarification of definitions/cadence/revisions. No dataset was delivered.
This is an explicit refusal of requested records, distinct from a pending reply.

A September 21 reply clarified that no winner personal information is sought,
accepted existing nonpersonal aggregate August 2026 counts by game/tier and
partial reports, and asked about the public list's date meaning, prize threshold,
completeness, selling versus validating retailer, update frequency and corrections.
No new report or paid work was requested; no fees were authorized. Gmail confirmed
sending. A shared Wyoming data-limitation notice now appears on the map coverage
card and state source screen. App completion can proceed with verified public
information and honest missing-data notices; no complete heat-map coverage is
claimed. The absence of Scratch games is a confirmed product limitation, not a
missing Scratch dataset.

Later September 21, Stevens replied that the narrowed aggregate reports are not
built or available and again referred us to the website's winner information.
No new dataset or field/cadence clarification was supplied. Continue with the
explicitly limited public-source path; no further intervention is needed for
that approach.

## September 28 administrative contact confirmation

WyoLotto Support asked for business name and phone at 19:11 UTC to confirm the existing request. The Sent-confirmed reply supplied Lottery Atlas as the project name, Apollo Houser as
requester, and the phone already provided in prior official records correspondence.
The phone is intentionally omitted from this public source-screen document.

The reply linked this administrative confirmation to David Stevens's existing
responses and explicitly avoided a duplicate request, new compilation or fees.
Email delivery remains preferred. This does not reverse the September 21 refusals
or establish a new substantive review, deadline or data delivery. No user action
is required; preserve the public-source limitations above.

## September 29 administrative forwarding acknowledgment

At 17:22 UTC, WyoLotto Support confirmed receipt of the contact details and said
the correspondence had been forwarded to David Stevens for review (private correspondence references retained locally). No records, revised
substantive decision, response deadline or fee request accompanied this message.
The September 21 refusals remain the latest substantive disposition. Monitor
for a further response; no reply or user action is required for this acknowledgment.
No fees or new compilation are authorized, and no public data changed.

## October 26, 19:00 ET — sole active state

Wyoming activated after New Mexico acceptance. Full supported current/retired
scope and gap matrix due October27 at19:00ET; supported release due October31
at19:00ET, fresh120hours for substantial draw/Keno integration. No extension.
Eighteen states accepted;27 unfinished including Wyoming. See
[WYOMING_ACCEPTANCE.md](WYOMING_ACCEPTANCE.md).

Four official opening captures at23:00:01–02UTC are hashed privately under
work/wyoming_scope/opening-manifest.json. [Current catalog](https://wyolotto.com/games)
links Cowboy Draw, Powerball, Mega Millions, Millionaire for Life,2by2 and Keno.
[Results](https://wyolotto.com/wyo-wins/check-your-numbers) and
[Keno](https://wyolotto.com/games/keno) expose dynamic search/history controls;
this shell alone does not verify payloads, draw dates/IDs, timezones, counts,
prize geography or history depth. Existing agency refusal/no-Scratch evidence
remains authoritative for those limitations; no new correspondence is needed.

Next inspect official result payloads, all rules/add-ons and retired/history
sources, then fix the full matrix before strict parsers/coupled publication/app
work. No new public feed, build or accepted Wyoming coverage is claimed.
Private administrative identifiers were removed from this source screen; the
original audit copy remains private.

## October 26, 20:05 ET — official dynamic contracts located

Captured the five remaining game HTML shells, the site's public JavaScript bundle,
its all-games response and all six rule responses privately. Hashes/timestamps
are in work/wyoming_scope/game-manifest.json and api-manifest.json. The bundle
identifies same-origin `/api/v1/game/all` and `/api/v1/game/rules` (identifier,
platform=web, cmsPreview=false); all seven requests returned success envelopes.
These are research captures, not validated or published app data.

The all-games response contains six current entries: five draw games and rapid
Keno, none marked retired. This does not prove historic scope completeness.
Keno's rule response has ten structured spot tables with38 data rows excluding
headers; the other five game responses link prize/odds images. Those images still
need visual review before literal schedule transcription/validation. Rule prose
and monetary/odds semantics are not yet contract-gated. Never substitute an
estimated jackpot for a dated prize or treat catalog startDate as game inception.

Result and Keno history code uses a separate game-data service. Keno queries
explicit draw-number ranges; standard draw data has primary/secondary result
structures. Exact payload identities, timezones, bonus/color grouping, statuses,
count units/geography and current/historical add-ons remain unverified. Public
client configuration stays in private source captures, not tracked feed/docs.
Next capture bounded result payloads through the official implementation, inspect
five schedule images and history/retired notices, then fix the full scope matrix.
No new feed/build/acceptance, no deadline change; Wyoming remains sole active.

## October 26, 21:05 ET — five schedule images visually reviewed

Official rule-linked schedule images were retrieved with hashes/timestamps in
work/wyoming_scope/schedule-image-manifest.json and visually inspected. Private
literal transcription records39 prize rows: Cowboy Draw4, Powerball9, Mega
Millions9, Millionaire for Life9 and2by2 eight. Keno's ten structured tables
remain38 data rows, separately captured; no claim of completed parser validation.

Preserve distinctions: Cowboy Draw Jackpot is categorical; Mega Millions image
states automatic multiplication of every non-jackpot win, so its printed values
are not a single draw-wide final payout. Millionaire for Life's first two prizes
are annual lifetime amounts, not lump sums.2by2 has separate red/white matches,
base/doubled columns and categorical free plays; its jackpot asterisk requires
rule-prose reconciliation. Powerball image is the base table, not a verified
Power Play/Double Play schedule. No missing variant is inferred from the image.

Official JavaScript also identifies draw-game list/details and Keno date-to-draw-ID
and draw-ID-range endpoints. Actual payload capture, timezone/identity/status
validation and exhaustive retired/add-on scope remain next. No new public feed,
build or acceptance; scope due October27 19:00ET and release October31 19:00ET.

## October 26, 22:00 ET — bounded result payloads captured

The official site's game-data client returned five active draw-game definitions
and a current/previous response containing six identities. The extra identity
is not automatically a current game: catalog joins and retired scope remain gates.
The current/previous response contains PENDING future results alongside ACTIVE
completed results; never publish future jackpot metadata as a completed drawing.

Explicit UTC query October12 00:00 through October27 01:57 returned45 ACTIVE
raw draw records: Cowboy Draw5,2by2 fifteen, Millionaire for Life15, Mega Millions4
and Powerball6. These are unvalidated research rows, not an accepted inventory.
UTC dates differ from local draw dates for evening games. Preserve actual
source instants until Mountain-time schedule conversion is validated.2by2 uses
two primary winningNumbers plus two bonusNumbers; those represent color groups
requiring explicit mapping, not a conventional single bonus ball.

Keno date-range lookup returned minimum472009 and maximum472352; a bounded
draw-ID request returned five records472348–472352 inclusive. This demonstrates
endpoint inclusivity for this capture, not complete history or continuous IDs.
Each sampled result carries drawingDate and20 primary numbers. Raw captures
and per-request hashes/timestamps are private under work/wyoming_scope; the
private client extracts public-site configuration without publishing it.

Next finish retired/add-on scope and count geography, then strict parsers. The
[official transition notice](https://wyolotto.com/news/new-millionaire-for-life-game)
identifies Millionaire for Life's February22,2026 introduction and Lucky for Life
retirement; historical data must remain separate from current results. No new
feed/build/acceptance. Scope/release deadlines unchanged, no extension.

## October26 — full supported scope closed

The complete current/retired/variant/history matrix is fixed in
[WYOMING_ACCEPTANCE.md](WYOMING_ACCEPTANCE.md), before the scope deadline.
Five active draw families plus Keno; Lucky for Life retired, Ragtime Raffle
historical, no Scratch and no Wyoming Double Play. Reports remain unavailable
pending geography/units/tier validation despite private summary payloads.
Next strict parsers and atomic coupled collection; no public feed/build or
acceptance. Release October31 19:00ET unchanged, no extension.

## October27 — initial draw parser implemented

The five current draw families now have a bounded parser in
`tooling/import_wyoming_draws.py`. It validates query bounds, UTC instants,
source game identity, result timestamp agreement, completed status, positive
unique draw IDs, number group cardinality/range/uniqueness and Power Play
multiplier. It rejects unknown secondary/session structures and drawing-wide
Mega Millions multipliers; empty PENDING rows are excluded. Local dates use
America/Denver. Public candidate records omit customer/internal result IDs.

The official UI code renders2by2 bonusNumbers in red before white primary
numbers; the parser preserves the two groups and permits equal numbers across
colors. Six focused tests pass with mutation subcases. All45 retained completed
rows pass without a source refresh; latest-two selection would yield ten draw
records. This private candidate is not a new public feed or accepted coverage.
Keno parsing, schedule/cadence/version gates, literal rule contracts, collection
continuity and app/native work remain. Exact reports remain unavailable. Release
October31 19:00ET unchanged, no extension.

## October27 — bounded Keno parser

Official rapid-game metadata confirms Keno range1–80 and240-second nominal
frequency; captured privately with original retrieval/hash. Added strict Keno
parser validating inclusive ID bounds, UTC time window, source game identity,
20 unique integer numbers1–80, draw-ID/time ordering and no unexpected
bonus/multiplier/secondary/session structure. Source number order is preserved.
Gaps do not produce invented draws; jackpot metadata is excluded from results.

All five retained Keno records472348–472352 pass. Eleven focused Wyoming tests
pass together, including mutation cases for both draw and Keno parsers. No fresh
result collection or public feed/build/acceptance. Next cadence/version and
literal rule contracts, coupled atomic collection, then app/native gates. All
reports remain unavailable; October31 19:00ET deadline unchanged.

## October27 — literal rule and image contracts

Added six exact structured rule contracts and five SHA256-gated schedule-image
contracts. Every retained rule response and original image passes. Changed prose,
prizes, table structure or image bytes fail closed for review, including in-place
image replacement at the same URL. Returned schedules preserve the reviewed39
image prize rows and Keno ten tables/38 data rows, with categorical jackpots,
annual lifetime prizes, free plays and multiplier caveats. These are schedules,
not dated payout/count reports.

Sixteen focused Wyoming tests pass together (draw, Keno and rule suites). No
new source refresh, public feed, app build or acceptance. Next complete cadence/
version gates and coupled collection/atomic retention, then app/native work.
Scope closed in c59e8d4; release October31 19:00ET unchanged, no extension.

## October 27 — bounded version and draw cadence gates

Completed-result validation now enforces the literal Mountain-time weekdays and
clock times from the retained official rules for all five draw families, including
America/Denver daylight-saving conversion. Completed draw IDs must increase with
time. Both draw and Keno imports reject records before October12,2026 UTC, the
start of the reviewed capture window; this is an explicit supported-history
boundary, not an asserted game inception or historical format-change date.
Older formats remain unavailable pending separate evidence. Empty pending rows
remain excluded and do not become results.

Nineteen focused Wyoming tests pass, including wrong weekday/time, fractional
seconds, older records, ID regression and both sides of the November DST change.
All45 retained draw rows and five retained Keno rows pass these gates after their
original manifest hashes were checked. This reuses original capture timestamps;
it is not a new source collection. No public Wyoming feed, app build or acceptance.
Next implement coupled atomic collection and failure/correction/regression
retention. Release October31 at19:00ET remains unchanged, no extension.

## October 27 — coupled collection and atomic retention implementation

Added the in-memory Wyoming collector and atomic refresh transaction. Its18
result/rule requests cover five draw windows, a separately bound Keno range and
five-ID lookup, six literal rule payloads and five reviewed image-byte contracts.
The output requires two completed dates per draw family and five returned Keno
IDs; missing data fails collection instead of being invented. Each capture keeps
its actual transport completion timestamp, byte length and SHA256. All15 target
reports remain explicitly unavailable. The collector emits no API credentials,
customer IDs, private result IDs or estimated jackpot fields.

Twenty-six focused tests pass. Synthetic transaction tests inject failures at
all18 request positions and preserve the prior snapshot bytes/date. Disk-replace
failure cleans up its temporary file and preserves prior bytes; corrections,
interior result loss, rule changes and window/date regressions fail before
replacement. A newer bounded Keno window can advance. Literal rule/image tests
remain separate from the transaction suite's mocked rule transport.

This is implementation and synthetic failure evidence, not a fresh collection or
public deployment. Next wire the official transport and catalog/config identity
gates, run a fresh private coupled collection with retained raw evidence, then
publish only after validation. Dart/UI/native and ordinary restoration remain
open. Wyoming is not accepted; October31 at19:00ET remains the release deadline
without extension. Android's ordinary installed app remains unchanged.

## October 27 — fresh private coupled baseline and transport gates

Official transport, six-game catalog, five active draw identities and Keno
configuration gates are implemented. Keno range/identity/cadence configuration
changes fail closed; API credentials stay in caller configuration and are never
serialized. Source redirects require review before credentials can be forwarded.

A fresh21-request private collection completed at **09:08:26.821262UTC October27**:
10 draw results (two per five families), five bounded Keno results, all15 reports
unavailable, six literal rules and five reviewed schedule-image hashes. The
private205312-byte candidate has SHA256
`2372205d598238d18853d5beb273b4df23f7a5d5a59d8fd5b03b9c18663273c0`.
Raw responses, original capture timestamps and hashes are retained privately.
Every source hash matches its manifest. Replaying failures at all21 request
positions preserves the real candidate bytes/date. Twenty-eight focused tests
pass, including catalog/config mutations and synthetic disk-replace retention.

The initial private attempt rejected the service's millisecond-rounded range
boundary. Queries now use exact whole-second boundaries while actual capture
timestamps retain full precision; strict range equality remains enforced. The
failed attempt produced no snapshot. This is resolved implementation validation,
not a production outage or a deadline extension.

No public Wyoming feed/deployment, app build or acceptance yet. Next integrate
the transport configuration into publication, deploy and independently verify,
then strict Dart loader/bundle/cache, UI/native and ordinary restoration. Release
October31 at19:00ET remains unchanged; Android ordinary app remains running.

## October 27 — coupled baseline publication prepared

The official public-site bootstrap now resolves transport configuration in memory;
no API key is embedded in source, feeds or logs. Scheduled Wyoming refresh is
isolated through the existing state refresh runner, preserving prior bytes/date
on errors. The public feed staging and commit paths include Wyoming.

A fresh21-request collection completed **10:06:23.250012UTC October27** and passed
continuity against the09:08 baseline. It contains15 results (10 draw, five Keno),
all15 reports unavailable, six literal rule contracts and five reviewed images.
Generated and staged public bytes are205312 bytes, SHA256
`0d82ae6653dc05bd094e8172d6aea6a97431342a1db87a717e782b6fc4a6b564`.
Actual raw responses and source timestamps remain private. Public configuration
bootstrap is an additional request outside the21 coupled data/rule requests.
Thirty focused Wyoming tests pass. Deployment and independent live verification
are pending at this checkpoint; no app build or Wyoming acceptance. Next close
publication verification, then strict Dart loader/bundle/cache and visible/native
flows. Release October31 at19:00ET unchanged, no extension.
