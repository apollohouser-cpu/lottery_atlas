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
