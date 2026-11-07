# Delaware source screen — September 13, 2026

Delaware is not yet ready for a complete winning-ticket total or a verified
retailer heat map. The [Multi-Win Lotto Number of Winners printable page](https://www.delottery.com/Drawing-Games/Multi-Win-Lotto/Number-Of-Winners/Print)
lists prize-category counts by drawing, but covers one game and does not
establish complete state, national, and Scratch-Off counts. The general
[Number of Winners page](https://www.delottery.com/Winners/Number-Of-Winners)
did not expose a complete aggregate in this screen. [Top prizes remaining](https://www.delottery.com/Instant-Games/Top-Prizes-Remaining)
describes unclaimed prizes, not winners during a period. Selected
[winner stories](https://www.delottery.com/winners) are not a complete dataset.

The [retailer locator](https://www.delottery.com/Where-To-Buy/Drawing-And-Instant-Games)
supports searches and says there are more than 525 retailers, but a complete
active export with stable identifiers and winning-ticket retailer links was
not established. A scoped Multi-Win Lotto importer may be possible after
confirming its table definitions, date coverage, access and correction cadence.

On September 13, 2026, a data inquiry was sent to Director Helene Keeley at
`helene.keeley@delaware.gov`, published in the Lottery's
[Media Center](https://www.delottery.com/Media-Center). It asks for routing to
the appropriate data or records custodian, existing draw and Scratch-Off
counts, retailer records, definitions, update cadence and official access.
Gmail confirmed “Message sent.” This is an inquiry, not a formal FOIA request;
no response or complete dataset has been verified yet.

## Current Scratch catalog — September 21, 2026

The importer now joins the official [current Instant Games catalog](https://www.delottery.com/Instant-Games)
to the [top-prize report](https://www.delottery.com/Instant-Games/Top-Prizes-Remaining)
and checks the [closeout schedule](https://www.delottery.com/Instant-Games/Close-Out-Schedule).
The initial snapshot has 35 distinct printed game numbers from 37 current game
cards. Featured cards outside the current-game grid are excluded.

Game 528, Game Show Experience, has three ticket designs: Price is Right,
Press Your Luck, and Family Feud. They share a printed game number, price, top
prize, and detail image. The report's three original and three remaining top
prizes apply once to that game. Design names are preserved in the coverage note;
they are not three independent prize pools. Six report-only game numbers
(410, 468, 491, 494, 497, 508) are excluded because they are absent from the
current catalog. Current games must match report price and top prize; single
design names must also agree. Conflicts fail the refresh instead of overwriting
verified data.

The source timestamp is September 21, 2026, 2:24:42 PM; the source does not
specify its timezone. Routine updates are weekly, with a stated same-business-day
update when final-top-prize changes occur. The application checks for updates
every six hours. Retrieval time is separate from the printed inventory date.
Zero remaining prizes stay zero; absent records are never fabricated as zero.
Games with a past announced sales end or future launch are excluded when those
dates are published. The sales-end date itself is inclusive.

This is top-prize inventory, not complete prize-tier coverage, dated winning-ticket
totals, or a retailer map. Remaining prizes may already be in sold tickets. The
existing request for additional official records remains separate, and unavailable
records do not block completion of supported application features.

Validation: fresh official-source import produced the same 35-game snapshot;
113 Python, 48 Node and 68 Flutter tests passed, plus five source HTTP checks.
The macOS debug build passed. Analysis reported only the 12 existing informational
notices. Tests cover zero inventory, duplicate/shared designs, report-only
exclusion, conflicting joins, malformed source structure, and inclusive sales-end
dates. All 24 existing catalogs were unchanged by this integration. The catalog
is ready for local testing; live feed publication is verified separately.

Live verification September 21: publisher run 35660292296 succeeded. The live
combined catalog exactly matched the publisher's repository snapshot, including
all 35 Delaware games. Activity and retailer feeds also matched their published
snapshots. Delaware is ready for current-catalog testing; full map coverage is
still limited as described above.

## November 6 at12:48EST — supported-coverage activation

Delaware is the sole active state after Arizona acceptance. Scope due November7
at12:48EST; release November11 at12:48EST (17:48UTC), fresh120elapsed hours for
substantial draw/rule/app integration, no inherited deadline or extension. See
DELAWARE_ACCEPTANCE.md. Four opening ordinary HTTPS captures returned200; private
raw bytes/hashes retained. No current catalog count or draw import claimed yet.
Current/retired Lucky For Life, daily sessions, add-ons and Keno boundaries need
reconciliation. No new agency correspondence or private delivery integration.

## November 6 — linked source capture and current catalog validation

Thirteen linked official pages returned HTTP200: nine draw-family pages (including
Lucky For Life), three Keno pages and Past Numbers. Raw files/hashes/timestamps
are retained in work/delaware_scope/linked-manifest.json. Linked prizes/odds,
number-of-winners and November2026 history URLs are inventoried privately.
Lucky For Life still describes daily draws and links November history despite
being absent from the main current-game navigation; current status remains a
named reconciliation gap rather than an assumed retired/current classification.
Play5 explicitly distinguishes DAY/NIGHT/BOTH and published drawing/cutoff times;
leading zeros and session identity must be preserved. Keno results require
separate semantic inspection; page retrieval alone is not observed draw coverage.

Existing strict Scratch parser validates39 current printed identities against49
report rows and35 closeout rows, yielding39 joined games. Report timestamp is
November5,2026 at10:33:35AM, source timezone unspecified. These counts describe
captured catalog/report/closeout records, not wins or retailer stock. Private
joined candidate retained; no public output overwritten or source date advanced.
The three-design game528 remains one printed identity under the existing join.

Next inspect linked result/report/rule tables, resolve Lucky For Life status,
audit instant detail/coming-soon/second-chance boundaries, and fix the complete
supported matrix before November7 at12:48EST. Release deadline November11 at
12:48EST unchanged; no acceptance or new native build claimed.

## November 6 — report semantics and first strict draw-report parser

Captured28 linked rule/report/history/instant-boundary pages with ordinary HTTP200;
raw hashes and retrieval times retained in work/delaware_scope/rules-history-manifest.json.
The Lucky For Life November history table has headers but no result rows: that
is unavailable observed history, not zero winners or evidence that the game is
currently operating. Its legacy daily-rule page remains separately identified.
Coming-soon and second-chance pages are captured; their product/promotion scope
still needs reconciliation before the fixed scope decision.

Multi-Win Lotto's Number Of Winners table has two distinct category groups:
Win in A Line (four columns) and Combination Win (six columns). Both contain6N,
so a label-only map would silently merge different counts. New strict parser
preserves group plus label, source title/URL, date and published count without
summing categories or inferring unique tickets, geography or retailer positions.
The retained fixture has10 dated rows from October27 through November5. Header
spans, row labels/width, nonnegative integers, unique descending dates and future
bounds fail closed. Ten focused Delaware tests pass, including existing catalog
checks. No report output is published yet; complete report-unit qualification
and integration remain open. Release and scope deadlines unchanged.

## Fixed supported scope — November 6, 2026 at15:49EST

Scope fixed before November7 at12:48EST. Release remains November11 at12:48EST
(17:48UTC), no extension. This fixes implementation targets and explicit gaps;
it is not publication or acceptance and target row counts are not observations.

| Family | Supported target | Explicit boundary |
| --- | --- | --- |
| Powerball | Base and Double Play results; Power Play; literal rules/tiers; source returns | Distinct draws and prize schedules, no inferred actual payouts |
| Powerball Xs & Os | Team-logo results and rules/tiers; published Delaware report where qualified | Random logo draws, not NFL outcomes; no number conversion |
| Lotto America | Results, All Star Bonus and literal rules/tiers | Multiplier distinct from base drawn numbers |
| Mega Millions | Results and multiplier-specific rule/tiers | No fabricated drawing-wide multiplier |
| Play3, Play4, Play5 | Separate DAY/NIGHT groups; positional digits and all published bet types/tiers | Preserve leading zeros; drawing times distinct from sales cutoffs |
| Multi-Win Lotto | Results, line and combination schedules, grouped published report categories | Repeated6N labels retain group; no cross-category sum or unique-ticket inference |
| Keno | Dated/game-number results, literal local display time and Bonus multiplier, full published spot schedules | No assumed timezone/instant or complete historical archive |
| Lucky For Life | Clearly historical/legacy source page, rules and dated available report | Current navigation omits it; November history empty; report latest February21. Do not label active or invent a retirement date |
| Instant Games | All39 captured current printed identities, available source prize data and illustrated instructions; shared designs preserved | Remaining prizes are not claims or retailer inventory; unknown unavailable tiers explicit |
| Coming soon | Separate source-listed532 Did I Win? and520 $50,000 Bonus Stars | Not current sales/inventory; featured navigation excluded |
| Closeout | All35 captured closeout rows with literal dates and separate sales/claim semantics | Not complete retired catalog or full historical availability |
| Second chance | Source-linked eligibility/rule information and explicit registration boundary | No login, ticket submission, entry, or claimed complete promotions archive |

Result target: latest two validated observations in each of12 ordinary draw/session
 groups plus Keno, where actually available. Historical Lucky For Life remains
separate. Capture available monthly history as source evidence; full long-term
history remains unavailable until independently validated. All linked current
number-of-winners reports will be screened for game/date/session/unit/geography;
only supported literal categories may be displayed, otherwise explicitly unavailable.
No complete statewide total, retailer positions/joins, or unique-ticket counts.
Sports betting, video lottery, casino table games and iGaming are outside the
lottery draw/instant dataset; provide clear exclusions rather than invented coverage.

Keno's ordinary date-search form was submitted for November5 using its provided
session token/cookie. It returned HTTP200,1164267 bytes, with explicit date, game
numbers, local display times,20-number rows and multipliers. Original bytes and
hash retained in work/delaware_scope/keno-query-manifest.json. This is permitted
read-only result lookup, not betting or access-control bypass. No parsed result
count or feed is claimed yet; strict shape/range/date/identity validation comes next.

Next implement complete strict result/rule/report contracts against retained
captures, couple atomic publication and failure retention, then integrate ordinary
app/native paths. Existing Multi-Win parser and catalog tests remain valid; no
new mobile build or beta readiness claim.

## November 6 — strict Keno result validation

New Keno date-search parser validates the retained November5 response as327
observed rows, game numbers1464188–1464514. This is the captured response count,
not proof of a complete drawing day or all historical results. Each row retains
its printed date, game number, literal local display time,20 distinct numbers
in1–80 and source-listed Bonus multiplier. Published Bonus table permits1/3/4/5/10;
other multipliers fail closed. No timezone or UTC drawing instant is inferred.

Source URL/title and requested date must agree. Empty results, malformed number
sets, duplicate/unordered game numbers or display times, future dates and unknown
multipliers are rejected. Two actual source-row excerpts form a public regression
fixture without form tokens. Full source and validated development output remain
private. Thirteen focused Delaware tests pass (catalog, Multi-Win and Keno).
No production feed/native build/acceptance yet; fixed scope and release deadline
remain unchanged. Next implement the ordinary draw/session parsers and literal
rule/report contracts, then coupled publication and ordinary app integration.

## November 6 — Play3/4/5 positional session parser

Strict monthly parsers now validate33 captured rows across Play3/4/5: each source
contains six DAY and five NIGHT observations for November1–6. November6 has only
a DAY row in these captures; the missing NIGHT is neither synthesized nor zero.
Session identity comes from the source sun/moon marker, with missing, unknown or
ambiguous markers rejected. Positional digits remain strings, preserving leading
zeros and repeated digits. No drawing instant is invented.

Exact game/month title and source URL, table headers/row labels, digit count,
single ASCII digits, date bounds/order and duplicate date/session rejection are
covered. Three source-table excerpts are retained as public regression fixtures;
full captures and parsed development observations remain private. Seventeen
focused Delaware tests pass. No production publication, new native build or
acceptance is claimed. Scope fixed November6 at15:49EST; release remains
November11 at12:48EST without extension. Next cover Powerball/Double Play,
Lotto America, Mega Millions, Multi-Win and Xs & Os result contracts and integrate
literal rules and qualified reports.

## November 6 — Multi-Win, Mega Millions and Lotto America results

New monthly result contracts validate five Multi-Win, one Mega Millions and two
Lotto America rows in the retained November captures. Mega Millions needs a
preceding-month capture to satisfy the latest-two target; no missing row is
invented. Source URLs/titles, month/date/order, row labels, number cardinality,
uniqueness and published game ranges are checked. Special balls must carry the
correct source color marker and range; Lotto America All Star Bonus stays
separate. No drawing-wide Mega Millions multiplier is fabricated.

Actual source-table excerpts are regression fixtures. Twenty focused Delaware
tests pass, including wrong-game sources, special-ball confusion, range errors,
duplicate dates and unsupported multipliers. Private parsed observations are not
a public feed. Powerball/Double Play and Xs & Os result contracts, remaining
literal rules/reports and coupled app/publication/native work remain open.
Release November11 at12:48EST is unchanged; no acceptance or beta claim.

## November 6 — Powerball/Double Play and preceding-month coverage

Strict paired-row parsing validates two Powerball and two distinct Double Play
observations (November2/4) from the retained monthly source. Game labels, common
printed date, distinct number containers, special-ball roles/ranges and Power Play
are checked; Power Play is never copied to Double Play. Corrupt/missing paired
containers, duplicate dates, wrong ranges and unknown multipliers fail closed.
Twenty-two focused Delaware tests pass. Public fixture contains only the actual
source title/table excerpt; no form tokens or private identifiers.

Followed the observed Previous Month link from Mega Millions November history.
The October response returned200,52850 bytes and validates nine dated rows,
latest October30; together with November3 this supplies two observed results
without inventing an absent November row. Private manifest/bytes preserve the
independent retrieval time and source dates. No public feed or new native build.
Xs & Os logo parsing, literal rules/qualified reports and production integration
remain open. Fixed scope and November11 at12:48EST deadline are unchanged.


### November6 Xs & Os monthly logo validation

Followed the official draw navigation history link and its observed Previous
Month link. Raw November/October responses and retrieval hashes are retained
privately in `work/delaware_scope/xsos-manifest.json`. Strict parsing validates
one November1 observation and four October observations (latest October25),
supplying the latest two across the month boundary. Eight source-labelled team
codes, names and matching logo URLs are preserved per draw; these are random
lottery results, not NFL outcomes or numeric balls. Source results remain
unofficial and tickets remain proof of winning.

The parser rejects changed source/title/date identity, malformed logo groups,
duplicate identities and mismatched image paths. Public fixtures contain only
actual title/results excerpts, with no form tokens. Twenty-four focused Delaware
tests pass. Literal rules, qualified reports, production publication and native
acceptance remain open; no new feed/build or acceptance is claimed. The fixed
scope and November11 12:48EST release deadline are unchanged.


### November6 — qualified Xs & Os report and report-screen finding

The captured Xs & Os report explicitly identifies Number of Delaware Winners.
Strict parsing now preserves eight dated rows (September13–November1), with
five literal match categories each. The latest row publishes0/0/3/39/243 for
Match8/7/6/5/4. These are source category counts, not inferred unique-ticket
counts, actual payout totals or retailer locations. Source URL/title/geography,
headers, row labels, dates/order, integer counts and merged-cell rejection are
validated. Public fixture is the actual title/table excerpt; full raw provenance
and parsed candidate remain private. Twenty-six focused Delaware tests pass.

Screening found an unresolved Lotto America report schema inconsistency:
its grouped header says All Star Bonus Multiplier Winners, but the corresponding
body data-labels say Power Play; group colspans also specify10 while each group
has nine category columns. Do not silently relabel or publish this as a qualified
multiplier report. Preserve the source and disclose report unavailability unless
independent evidence resolves the mismatch. This does not block honest supported
results/rules completion. Remaining report/rule parsing, publication and native
acceptance stay open. No feed/build/acceptance; November11 12:48EST unchanged.


### November6 — Xs & Os qualified prize schedule

Five literal prize/odds tiers now validate from the retained official page.
The jackpot remains the word Jackpot, not an invented cash value. Overall odds
and mandatory qualifications are retained: jackpot cash is pari-mutuel,
lower tiers may also become pari-mutuel, and logo draws are independent of NFL
outcomes. Changed/missing qualifications fail closed. This is a prize schedule,
not actual payouts; separate second-chance entry is not performed. Twenty-eight
focused Delaware tests pass. Source excerpts are public fixtures, full captures
and parsed candidate private. Remaining rules/reports and production/native work
remain open; no new feed or acceptance. November11 12:48EST unchanged.

Development follow-up checked the previously emailed Pages failure for b58af59.
Newer runs for dd1aea7,3053a9e and fb60758 all completed successfully; latest
run42331472724 is successful. No current deployment failure is inferred from the
older email, and no source refresh/retrieval date was advanced by this check.


### November6 — Multi-Win grouped prize schedules

Strict rule parsing preserves four Win in a line and six Combination win tiers.
The two six-number categories stay distinct: the line prize is literally
$50,000 +, while combination six is $3. The zero-match qualification explicitly
requires no numbers matched on any three lines. Overall1:5.7 odds and its source
PDF link are preserved; PDF contents are not yet audited. Undated page Total
Prizes/Total Money aggregates are excluded from imported rule data.

Changed group identity, tier structure, growing-prize qualification, zero-match
note and odds fail closed. Thirty focused Delaware tests pass. Full captured
bytes and development output remain private; actual source excerpt is a regression
fixture. Remaining rules/reports, coupled publication and native acceptance stay
open. No new public feed/build/acceptance; November11 12:48EST unchanged.


### November7 — illustrated rule capture and Play5 transcription

Five linked chart images returned HTTP200 and were visually inspected: Lotto
America, legacy Lucky For Life and Play3/4/5. Exact URLs, bytes, hashes and retrieval
times remain in work/delaware_scope/rule-charts-manifest.json. These are image
sources, not absent rules simply because the HTML has no prize table.

Play5's13 rows are transcribed with bet type, matching requirement, literal
rounded source probability and separate50-cent/$1 prizes. The source's30-way box
is $825/$1,650; its rounded probabilities are retained without recomputation.
Illustrative number permutations are not imported as results. The transcription
loader requires both the exact audited image SHA256 and URL; altered bytes and
wrong source were verified to fail closed. This is a development candidate, not
a published rule feed. Other illustrated schedules still require structured
transcription/qualification before integration; Lucky For Life stays historical.
No native build/acceptance; release November11 12:48EST unchanged.


### November7 — Play3/4 illustrated bet schedules

Visual transcription now covers all nine Play3 and13 Play4 chart rows, alongside
13 Play5 rows. Straight/box rows preserve separate straight-and-box versus
box-only outcomes; merged payout cells do not become invented50-cent/$1 columns.
Combination rows retain minimum ticket costs and per-straight-bet costs. Play4
explicit ticket-cost/prize options remain separate. Rounded probabilities stay
literal to the chart, including combination-row probabilities; none are recomputed.

A shared chart loader verifies game, exact source URL and audited image SHA256.
All three actual captured images passed; changed bytes and wrong URLs failed.
The30 existing focused Delaware tests still pass. Parsed candidates remain
private and no public feed, native build or acceptance is claimed. Remaining
rules/reports, integration and native checks continue under the unchanged
November11 12:48EST release deadline.
