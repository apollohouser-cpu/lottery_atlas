# Missouri source screen — September 12, 2026

Missouri's **Show Me Cash-only state total is ready for partial-coverage
testing**, while its current-data retailer heat map is deferred. Preserve the
existing Missouri schedules, official links, starter Scratch catalog, and
verified historical winner point. This count does not cover other draw games
or Scratchers and cannot rank Missouri retailers.

- The [official Where to Play page](https://www.molottery.com/where-to-play/where-to-play.do)
  searches by city or ZIP within local, 15-, 30-, or 45-mile radii. This does
  not establish a complete, refreshable statewide active-retailer export with
  exact addresses and verified coordinates.
- The [Lottery's retailer page](https://molottery.com/retailers/retailers.jsp)
  maps tickets worth at least $1,000 sold during **August 2026**. Its
  [monthly winner release](https://www.lotterydirect.molottery.com/article.do?id=2224&method=s)
  lists specific retailer addresses for **July 2026**. These are useful
  historical sources. Their monthly cadence is allowed with a clear monthly
  disclaimer, but they do not provide a complete up-to-date claim feed.
- The [retailer portal](https://retailer.molottery.com/displaytopic.do?topic=faq)
  requires an account associated with a Missouri Lottery retailer and exposes
  location-specific reports. It is not a public statewide feed.

To resume, obtain official statewide active-retailer and retailer-level
winner feeds with source-specific timestamps and disclosed publishing
cadences. Confirm full coverage and exact locations before enabling Missouri
as a map state.

On September 13, 2026, a data inquiry was sent to Wendy Baker, the
Communications Manager listed on the Lottery's [press-contact page](https://www.molottery.com/news/presscontacts.jsp)
and [fact book](https://www.molottery.com/news/files/documents/202520Book%20Final.pdf).
It asks her to route the request to the data or records team for existing
draw-game ticket counts, Scratcher game/tier counts, retailer feeds where
public, count definitions, correction behavior, and publication cadence.
This is not yet a formal Sunshine Law request to a designated custodian;
ask for that contact if the inquiry is redirected. No fees were authorized.

Update September 16: Jay Boresi, Director of Legal Services, replied that
individual [draw-game result pages](https://www.molottery.com/powerball/winning-numbers.jsp)
offer Excel downloads with winning numbers and tickets sold, updated regularly.
The Powerball page's download points to a game-specific `.xlsx` export;
its contents, 2026 date range, tier definitions and completeness still require
validation before publishing a draw winner total. He also pointed to the
[current Scratcher pages](https://www.molottery.com/scratchers-list.do), which
show game-level prize and unclaimed figures, and to the large-prize retailer
map. These do not by themselves establish 2026 year-to-date all-tier Scratch
claims or complete retailer-linked winners. He offered to obtain a complete
retailer list; await that file and validate identifiers and coordinates.

September 16 workbook check: the official Powerball Excel download at
`https://www.molottery.com/powerball/past-winning-numbers.do?order=desc`
returned an XLSX with 3,262 draw rows and 27 columns. It includes 110 rows
dated January 3–September 14, 2026, game-tier ticket-count columns for the
main drawing and Double Play, and composite values such as `201+28` that need
the Lottery's definition before normalization. The source date is the
download date, not necessarily each draw's final correction date. The initial
read-only workbook reader reported only the first row; opening it in normal
mode exposed the full sheet. Do not publish an aggregate yet: verify whether
all counts refer only to Missouri-sold tickets, what the plus-separated
values represent, whether double-play columns overlap, and coverage of all
other draw games. The XLSX was inspected locally, not committed as app data.

A September 16 reply to the legal director and communications manager asked
for confirmation of Missouri-only counts, plus-separated tier semantics,
Double Play overlap, correction/source dates, 2026 Scratcher claim counts,
and the promised retailer directory and winner joins. Gmail confirmed
“Message sent” at 7:28 p.m. ET. No data were promoted to the map yet.

The official Show Me Cash Excel download at
`https://www.molottery.com/show-me-cash/past-winning-numbers.do?order=desc`
also returned an XLSX with 258 rows dated January 1–September 15, 2026 and
four explicit winner-tier columns (`5of5` through `2of5`). Its dates use
two-digit years, unlike the Powerball workbook. This is another usable
game-scoped candidate pending Missouri-only scope and correction confirmation;
it does not establish complete coverage across all draw and Scratch games.

The official Pick 3 Excel export at
`https://www.molottery.com/pick3/past-winning-numbers.do?order=desc`
contains 516 January 1–September 15, 2026 Midday/Evening rows, but its
populated columns are draw date, draw time, winning numbers and Wild Ball;
there are no winning-ticket count fields in that export. The public statement
that draw spreadsheets include tickets sold therefore cannot be generalized
to every game. The latest repository Pages workflow completed successfully at
commit `0a79fb2`; this is a publishing check, not validation of Missouri
coverage.

September 16 implementation: a narrowly scoped Show Me Cash importer reads
the official game workbook and validates consecutive daily draw dates from
January 1, 2026 through the latest available draw, the four winner-tier
columns, and nonnegative integer counts. On the September 16 download it
found 258 draws through September 15 and 1,962,060 winning tickets across
5-of-5 through 2-of-5. Show Me Cash is an in-state game, and the Lottery's
legal director described the game downloads as winning tickets sold. The
state-total feed labels this explicitly as **Show Me Cash only**, excluding
other draw games and Scratchers; it cannot be interpreted as a complete
Missouri total or retailer ranking. The six-hour workflow will refresh the
source and stop on schema or date gaps. `sourceDate` records download day
because the workbook does not provide a separate publication timestamp.

September 17 refresh: the official workbook added the September 16 drawing.
The validated 259 daily draws from January 1 through September 16 total
**1,970,077 Show Me Cash winning tickets** across the four listed tiers. Commit
`fd37f70` passed all 48 Flutter tests and the publishing workflow; the live
Pages JSON was checked after deployment. The same game-only and retailer
limitations remain in force.

September 17 MO Millions check: the official
[`mo-millions/past-winning-numbers.do` workbook](https://www.molottery.com/mo-millions/past-winning-numbers.do?order=desc)
contains 74 drawing rows from January 3 through September 16, 2026. It has
separate main-draw and Double Play winner-tier columns, with integer-valued
counts represented as `.0` in the workbook and some blank tier cells. This is
a promising additional in-state game source, but the main and Double Play
counts are not added to the published state total pending confirmation of
whether a ticket can appear in both sets and how blank/composite Bulls-Eye
tiers should be interpreted. The current Show Me Cash-only label remains
accurate.

## September 21 Scratcher inventory audit

The official [Scratcher listing](https://www.molottery.com/scratchers-list.do)
has 71 distinct games in its main grid. Three featured cards duplicate games
561, 563 and 567; they must not be counted again. The main grid's 278 top-tier
rows match the corresponding rows in all 71 linked game-detail tables. Those
detail tables contain 843 unique-per-game prize amounts with original and
unclaimed counts; all counts are nonnegative integers, unclaimed does not exceed
original, and the highest detail tier agrees with each listed top prize.

Every detail page labels the figures **Estimated Unclaimed Prizes**, states
daily updates, and warns that tickets may already have been purchased but not
redeemed. Second-chance promotional prizes are explicitly excluded. No dated
inventory verification timestamp was established. Do not turn original minus
unclaimed into a dated claim total, or remaining prizes into retailer stock.

Twenty-five listed games have announced end dates, from April 17 through
September 18, 2026. They are ended, not necessarily claim-expired. The official
[claiming instructions](https://www.molottery.com/claiming-prizes/claiming-prizes.jsp)
allow 180 days after the official end; all 25 remain within that window on
September 21. The other 46 list their end as TBD. Preserve this difference in
catalog labels, and do not infer exact store availability from a listing.

Eighteen games advertise top prizes above $1 million. The official
[2026 Fact Book](https://www.molottery.com/news/files/documents/2026FactBook2.pdf)
explains that some Scratchers offer annuity and cash options. The audited detail
pages do not spell out those options. Game-specific treatment must be verified
before treating advertised totals as immediate cash or inserting an estimated
cash value. The remaining integration checks include detail price/identity and
date joins, claim-deadline handling, and clear source-date/coverage notes.

Raw listing, all 71 details, claiming page, and repeatable read-only audit are
retained under ignored `work/missouri_catalog/`. The source's malformed document
structure requires scoped XPath extraction; reading only the first HTML root's
text incorrectly omits the main content and daily-update footnote. Scope the
main grid explicitly to avoid the featured duplicates. No new Missouri catalog,
state total or retailer activity was published during this audit. Its existing
Show Me Cash-only coverage remains unchanged.

## September 21 newest-draw publication repair

Publisher run 35677718108 stopped on the September 21 Show Me Cash row because
one or more tier values were missing or noninteger. The failing workbook was
not retained, so the precise intermediate cell representation is unconfirmed.
A fresh official workbook now supplies all four tiers for that drawing: 0,
11, 512 and 5,531. The validated January 1–September 21 sequence has 264 daily
drawings and **2,006,744 Show Me Cash winning tickets**. This remains game-only
coverage, not a complete Missouri lottery total or retailer ranking.

The importer now separates one newest recent drawing with blank tier cells from
completed drawings. Such a pending drawing must immediately follow the complete
consecutive year-to-date sequence and be dated today or yesterday in Missouri's
America/Chicago timezone. It is excluded entirely until all four tiers are
published, with its date explicitly named in the coverage note. Blanks are never
zero-filled and published partial tiers are not summed. Historical missing
counts, multiple pending drawings, date gaps, future/duplicate dates and any
nonblank noninteger value still fail. Previously complete coverage cannot move
backward. Zeroes explicitly published in all four cells are valid complete data.

The next successful complete response removes the pending note and includes the
new draw. Unchanged totals, period and coverage retain their existing source date;
a routine recheck does not manufacture a fresh source timestamp. SourceDate
continues to mean workbook retrieval date because a separate correction/verified
inventory timestamp is unavailable. Error messages now include the actual public
tier-cell values for future diagnosis.

Four regression tests cover blank/partially blank newest draws, later completion,
explicit zeroes, historical/stale/duplicate/future/gapped/bad values, pending-note
removal, unrelated-state preservation, and prevention of coverage regression.

Validation: 127 Python, 50 Node and 70 Flutter tests passed, plus five HTTP
checks and the macOS debug build. Analysis retained only the 12 existing
informational notices. All other state totals were unchanged. Live publication
is verified separately; the last successful feed remains available until then.

September 22 live verification: publisher runs 35681378970 and 35695369372
succeeded after the pending-draw repair. All four live JSON feeds matched the
repository at `7fda8a1`, including the Show Me Cash total. A later publisher
failure occurred in Nebraska catalog parsing, not the Missouri workbook step;
the last successful published feeds remain accessible.

### September 22 identity/date preparation

A second read-only audit of the previously captured September 21 catalog/details
validated all 71 printed game numbers, names, explicit ticket prices, start dates
and end dates against their listing cards. No start date was after capture. All
25 ended games have internally ordered dates. The source also has a separate
Search heading, so game-name extraction must use the heading beside the printed
game number rather than every h1 on the page.

`work/missouri_catalog/audit_identity_dates.py` and `identity_date_audit.json`
retain the checks and each detail file's hash. Calculated 180-day claim-window
ends are labeled candidates derived from official general guidance, not separately
published game deadlines. This audit does not refresh inventory or its source
date. Game-specific annuity/cash interpretation remains unresolved; no new
Missouri catalog or claim activity was published.

## September 23 agency response — reviewed September 24

Jay Boresi emailed an active retailer workbook September 23 (All Active Retailers (19).xlsx). Attachment presence is verified, but its contents have not yet been downloaded or audited in this pass; do not count it as an inspected delivery or publish coordinates. He says the previously linked draw spreadsheets update at least daily; remaining questions are still being researched. Queue private workbook audit independently of Texas acceptance.

## October 6, 16:00 ET — supported-state activation

Missouri is now the sole active state. Release decision October 11 at 16:00 ET;
full supported scope October 7 at 16:00 ET. See MISSOURI_ACCEPTANCE.md. Four
Show Me Cash importer checks pass; scheduled source period is through October 5
with 2,117,553 game-only winning tickets. This does not expand coverage.

Reopened the [official home page](https://www.molottery.com/) and
[Scratchers list](https://www.molottery.com/scratchers-list.do). Current navigation
adds Powerball Xs & Os and includes MO Millions, Cash Pop, Keno/options and
Pull-Tabs alongside national games, Pick 3/4, Show Me Cash, Scratchers and
promotions. The live Scratch listing has September 28 additions; do not reuse
September's 71 as a current count. Source scope/semantics and a fresh strict
catalog remain next. No new agency mail, private-data promotion or acceptance.

## October 6, 17:00 ET — fresh catalog validation and draw-report audit

Fresh public Scratch listing/detail captures in private work/missouri_scope
validate 73 main-grid games and 868 prize tiers, with 25 announced end dates.
Featured cards are excluded from enumeration. Identity, ticket price, start/end
dates, listed top tiers and full detail inventory agree. All 73 detail pages
state daily updates; a distinct inventory verification date remains unavailable.
The new strict parser retains literal advertised prizes and null source dates.
It does not derive immediate cash options, claim dates, stock or claimed totals.
Two focused tests pass, including malformed/missing counts, impossible inventory,
identity/date mismatch, changed columns, missing cadence and duplicate main-grid
games. All 73 captured details validate privately. No app feed promoted yet.

The [Powerball dated report](https://www.molottery.com/powerball/prizes-paid.do?date=2026-10-03)
labels separate Missouri base and Power Play columns and separate totals, plus a
Double Play table. This supplies a stronger interpretation route than splitting
workbook composite strings without labels. Keep Double Play separate and do not
assert distinct people or cross-draw ticket identity.

The [Mega Millions report](https://www.molottery.com/mega-millions/prizes-paid.do?date=2026-10-02)
uses prize ranges and literal Jackpot; cached extraction showed zeros that are
not accepted as finalized data. Direct curl retrieval of dated draw detail pages
returned incomplete HTML ending at the specific-draw block, despite HTTP success.
Python urllib received 403, while curl loaded index/catalog pages. These are
retrieval observations, not proof of absent reports or zero winners. Raw bytes
and URLs are private; no existing feed was overwritten. Next resolve dated
report retrieval/encoding and validate source completion before any promotion.

The [MO Millions source](https://www.molottery.com/mo-millions/winning-numbers.do)
includes Bulls-Eye, Double Play and EZ Match; [Show Me Cash rules](https://www.molottery.com/show-me-cash/show-me-cash-rules.jsp)
also include EZ Match. The [Cash Pop source](https://www.molottery.com/cash-pop/winning-numbers.do)
separates five sessions. Pick 3/4 preserve Midday/Evening and Wild Ball.
[Club Keno](https://www.molottery.com/check-my-tickets/clubkeno.jsp) and
[Pull-Tabs](https://www.molottery.com/pull-tabs/pull-tabs.jsp) need separate source
routes and unit checks; neither can be silently folded into Scratch counts.
Historical Lotto/Cash4Life and promotion routes remain in the scope audit.
Scope is not yet closed. No Gmail, email, fee, deadline change or acceptance.

## October 6, 18:00 ET — dated-report recovery and supported scope closure

Public dated report retrieval now succeeds using the ordinary request header
`Accept-Language: en-US,en;q=0.9`. A cookie/session retry did not resolve the
truncation. The header is an observed working retrieval configuration, not a
proven diagnosis of the server behavior. Fresh raw pages and extracted tables
are retained privately in work/missouri_scope. HTTP 200 alone remains insufficient:
parsers must require complete documents, dated identity, expected columns/tiers
and reconciled totals. No failed or partially parsed output is promoted.

Fresh [Mega Millions October 2](https://www.molottery.com/mega-millions/prizes-paid.do?date=2026-10-02)
reports 3,609 Missouri prizes and $73,798, superseding the earlier cached-zero
observation. A strict parser validates all nine tier identities, count sum,
jackpot/range labels, payout bounds when no jackpot winner, date/weekday and
report trailer. Literal ranges remain literal; cashPrize and distinctTicketCount
are null, and finalityVerified is false. Three new regression tests and four
existing Show Me Cash plus two catalog tests pass (nine total). Fresh dated
HTML validates privately; this is not a new public feed or claim of finality.

### Supported scope/gap matrix — closed October 6 at 18:00 ET

Scope closure defines implementation and explicit gaps; it is not acceptance.
All current draw families found in the official navigation are included below.
No unavailable layer is interpreted as zero or as proof records do not exist.

| Product/source | Supported integration target and bounded limitation |
| --- | --- |
| [Powerball](https://www.molottery.com/powerball/winning-numbers.do) | Dated Missouri base/Power Play columns, nine base tiers, eight numeric Power Play tiers with top dash retained unavailable, separate Double Play nine tiers. Source subtotals and combined total retained with overlap explanation; no person/ticket identity inference. |
| [Mega Millions](https://www.molottery.com/mega-millions/winning-numbers.do) | Nine Missouri prize-count rows and published count/payout totals. Jackpot and ranges retained; no invented multiplier distribution. First strict parser now implemented. |
| [Powerball Xs & Os](https://www.molottery.com/powerballxo/winning-numbers.do) | Five reported tiers, eight through four teams matched; separate game. Random draw results are not NFL game outcomes. |
| [MO Millions](https://www.molottery.com/mo-millions/winning-numbers.do) | Eight base tiers including labeled Bulls-Eye matches and separate eight-tier Double Play. Preserve source zero/variable jackpot labels without asserting zero jackpot value. EZ Match product route; no realized EZ Match count feed verified. |
| [Show Me Cash](https://www.molottery.com/show-me-cash/winning-numbers.do) | Four dated tiers; retain existing year-to-date game-only importer while adding dated reports. [EZ Match rules](https://www.molottery.com/show-me-cash/show-me-cash-rules.jsp) verified, but separate realized add-on counts not verified. |
| [Pick 3](https://www.molottery.com/pick3/winning-numbers.do) / [Pick 4](https://www.molottery.com/pick4/winning-numbers.do) | Midday and Evening, separate base/Wild Ball columns and source $.50-play basis. Five and ten rows respectively; retain match labels and fractional dollar prizes. No inferred unique tickets across columns. |
| [Cash Pop](https://www.molottery.com/cash-pop/winning-numbers.do) | Five source sessions with dated prize-amount counts and reported totals; do not substitute another state's session schedule or wager labels. |
| [Scratchers](https://www.molottery.com/scratchers-list.do) | Fresh 73-game estimated inventory, 868 tiers, 25 listed end dates; literal advertised prizes, daily cadence, no explicit verification date/retailer stock/claims. Atomic app integration pending. |
| [Club Keno](https://www.molottery.com/club-keno/club-keno.jsp) | Official game/results routes and explicit coverage gap. Multiplier, Bulls-Eye, Double Bulls-Eye and six/seven/eight-spot progressive options are included in scope. Prize charts are scheduled prizes, not observed winners; statewide realized counts/payouts not verified. |
| [Pull-Tabs](https://www.molottery.com/pull-tabs/pull-tabs.jsp) | Separate official product route for preprinted dispenser tickets at eligible clubs. No verified inventory/claim feed; do not merge with Scratchers or invent counts. |
| [Promotions/second chance](https://playersclub.molottery.com/promotions) | Official public route; account/entry functions are not automated. No complete promotion-winner/count feed verified. |
| [Historical Lotto](https://www.molottery.com/lotto/winning-numbers.do) | Official notice says ended October 18, 2025; history/Excel routes retained as historical, not current game. No ten-year completeness claim. |
| [Historical Cash4Life](https://www.molottery.com/cash4life/winning-numbers.do) | Official notice says ended February 21, 2026; historical routes retained. Empty current-month results do not prove historical absence. Do not infer current Millionaire for Life participation. |
| Retailer directory / selected winner publications | Audit delivered directory privately or validate public locator before mapping; no guessed coordinates or private fields. Selected monthly winner stories cannot establish a complete retailer claim layer. |

Fresh report unit checks distinguish source prize counts, published payout totals,
scheduled prize labels, estimated inventory and sales. On October 5 Powerball,
base 7,319 plus Power Play 1,142 equals published 8,461; Double Play 849 remains
separate. These checks are source evidence, not an approved cross-game total.
Date-only reports must remain date-only; Pick sessions keep the source label.
No claim timestamp is inferred. Remaining strict parsers and live selection must
reject missing/changed structure and enforce date/session continuity before
atomic publication. No new email, private record promotion, deadline change or
acceptance. Next implement remaining seven report families and catalog import,
then directory audit, app/cache/UI, transactional refresh and native acceptance.

## October 6, 19:00 ET — Xs & Os and Show Me Cash strict report parsing

Implemented two further strict public HTML parsers using the privately captured
[October 4 Xs & Os report](https://www.molottery.com/powerballxo/prizes-paid.do?date=2026-10-04)
and [October 5 Show Me Cash report](https://www.molottery.com/show-me-cash/prizes-paid.do?date=2026-10-05).
Five team-match tiers reconcile to 844 source prizes/$13,057; four number-match
tiers reconcile to 5,599/$14,983. Separate source dates and game identities are
retained. Printed amounts are not converted into cash-option claims. In particular,
Show Me Cash's zero-dollar top label with no winners is retained literally, with
an explicit limitation rather than a zero-jackpot assertion.

Parsers reject truncated documents, wrong date/weekday, missing or changed
columns, extra/missing tiers, invalid counts, inconsistent totals and a zero prize
with a positive count. Unknown distinct-ticket counts and cash options remain
null, finality unverified. Jackpot-location free text is not exported. Two new
regression tests pass, eleven Missouri checks total; both captured source reports
validate privately. Three report families now have parsers. No new public feed,
retailer association, claim date, sales conversion or agency integration. Next
remaining five report families and live continuity; existing feed bytes preserved.

## October 6, 20:00 ET — strict Powerball/Power Play/Double Play

The [October 5 report](https://www.molottery.com/powerball/prizes-paid.do?date=2026-10-05)
now validates through the strict parser: main total 8,461/$43,839 comprises
without-Power-Play 7,319/$33,617 and with-Power-Play 1,142/$10,222. Separate Double
Play is 849/$9,046 and is not added to that source main total. Power Play multiplier
2 is retained, including the fixed $2 million second prize. Its jackpot dashes
remain unavailable/null, not zero prizes. Literal Jackpot stays without an
inferred cash option. If a jackpot count is positive, lower-tier payout is a
minimum rather than an invented jackpot payout.

Both main and Double Play headings must match the requested date. Full document,
exact tier/column identities, variant count/payout reconciliation, main combined
totals and multiplier-derived amounts are required. Two additional regression
tests exercise truncation, mismatched variant dates, altered multiplier, totals,
columns and unavailable jackpot cells. Thirteen Missouri checks pass; captured
source validates privately. No retailer-location free text is exported and no
claim of source finality, unique people or distinct tickets across variants is
made. Four of eight report families parsed; remaining four and live continuity
are next. Existing public feeds unchanged; no Gmail/email or deadline change.

## October 6, 21:00 ET — MO Millions and Cash Pop strict validation

[October 3 MO Millions](https://www.molottery.com/mo-millions/prizes-paid.do?date=2026-10-03)
contains separate main/Double Play eight-tier tables with explicit Bulls-Eye
matches. Private parsed totals are 5,963/$26,532 and 870/$4,968. Both dated
headings, columns, exact tier identities, blank padding, counts and payout
arithmetic are required. Main printed $0 with zero top winners remains a source
label, not a zero jackpot or cash-option assertion. EZ Match is not included.

[October 6 Matinee Cash Pop](https://www.molottery.com/cash-pop/prizes-paid.do?date=2026-10-06&type=3)
validates 22 prize-amount rows totaling 281 prizes/$11,549. The captured official
[winning-number index](https://www.molottery.com/cash-pop/winning-numbers.do)
maps source types 1–5 to Early Bird, Late Morning, Matinee, Prime Time and Night
Owl. Parser input must match the date and session printed in the report. Amount
rows do not establish wager categories or an exact draw timestamp.

Four new tests cover variant/session identity, dates, malformed or missing cells,
changed prize tiers, unexpected padding and inconsistent totals. All seventeen
Missouri tests pass, and both captured HTML reports validate privately. Cash
options and distinct tickets remain unknown; no source finality assertion.
Six of eight report families parsed; Pick 3/4 and live continuity are next. No
new public feed, private agency integration, mail or deadline change.

## October 6, 22:00 ET — Pick 3/4 sessions and fractional prize units

Strict parsers now cover [Pick 3](https://www.molottery.com/pick3/winning-numbers.do)
and [Pick 4](https://www.molottery.com/pick4/winning-numbers.do), both Midday and
Evening. Exact variant headers/column spans, date/weekday/session, match labels,
$.50-play basis, counts and payout arithmetic are required. Five and ten match
rows retain base and Wild ball columns separately. Straight's asterisk remains
literal; prize amounts such as $7.5 use exact integer cents. Combined published
winner counts are not verified distinct tickets or people across columns.

October 6 Midday private captures validate Pick 3 544/$77,380 and Pick 4
399/$149,443. Fresh official linked October 5 Evening reports validate Pick 3
414/$27,974 and Pick 4 72/$19,260.50, including a fractional total. Raw pages and
parsed outputs remain private. Two new regression tests cover wrong sessions,
dates, play basis, columns, tier identities, malformed money and total mismatches;
nineteen Missouri tests pass overall. All eight report families now parsed.
No finality, cash-option, claim-date or retailer association is inferred. Next
bounded live selection/continuity and atomic publication preservation; no new
public feed or agency integration, email or deadline change.

## October 6, 23:00 ET — bounded selection and live Cash Pop identity failure

Prepared atomic eight-family importer for 28 reports: two per game/session, with
both Pick sessions and five Cash Pop sessions. It follows only official dated
links, uses at most one preceding calendar month when needed, and bounds history
to 40 days. Future dates, incomplete session groups, duplicate report identities
and regressions reject before replacement. Local calendar uses America/Chicago.
Unchanged parsed reports preserve the prior timestamp. Twenty-one Missouri tests
pass, including every source failing and parser failure retaining baseline bytes.

Live trial and private recapture found the official Cash Pop October 6 type=1
(Early Bird) report URL returning a Prime Time heading instead. The strict parser
correctly rejected it; no output or partial public state was promoted. The prior
Matinee capture had matched its requested session, not proven all sessions work.
Captured response and index are private under work/missouri_scope/live_capture.
Do not infer no Early Bird prizes, substitute Prime Time, or weaken session
validation. Next investigate bounded official request behavior/alternate route
and complete live continuity. This affects new integration only; existing public
feeds remain untouched. No email or deadline change.

## October 7, 00:06 ET — Cash Pop retrieval workaround and live continuity

Bounded probes of the same public Cash Pop report parameters found that putting
`type` before `date` in the query returns the requested Early Bird report; POSTing
the same parameters also matched. The prior date-first URL returned Prime Time.
This documents observed request behavior, not a proven cache/server diagnosis.
The importer now uses type-first Cash Pop URLs and still rejects every printed
date/session mismatch. No report is relabeled to make a request pass.

All 28 selected live reports validate privately: eight game families and 14
session groups, two dates each. Cash Pop's five sessions and both Pick sessions
cover October 6/5; Mega Millions October 6/2, MO Millions October 3/September 30,
Powerball October 5/3, Xs & Os October 4/September 27, Show Me Cash October 6/5.
The preceding-month fallback supplies older linked draws without inventing dates.
Published source snapshots remain explicitly unverified as final; zero counts are
not a completeness assertion. The private report payload retains literal units,
unknown identity/cash fields, variants and source URLs.

Twenty-two Missouri tests pass, including all-family failure preservation and
Cash Pop query/session mapping. Injecting a fetch failure against the actual
private live payload preserves its bytes and updatedAt. No public feed was
promoted or changed. Next report bundle/cache/UI, catalog/directory and state
transaction integration; no Gmail/email, fees, deadline change or acceptance.

## October 7, 01:06 ET — fresh atomic Scratch inventory snapshot

Added an importer that follows official listing detail links and validates every
listed game before replacing its output. Fresh live listing and all 73 details
pass privately. Complete HTML, official route, game identity, price/start date,
listing/detail tier agreement and daily cadence are required. A minimum-scale
and prior-count-drop guard flag anomalies for review; neither asserts statewide
completeness. Changed identity rejects; estimated remaining inventory may update
without inventing claim dates or converting differences into claims.

The snapshot preserves advertised prize labels, total/unclaimed source units,
listed end dates and null sourceDate. It is deliberately not yet a generic app
cash-prize feed. A new importer test checks a complete snapshot, unchanged bytes/
timestamp, listing/detail request failures and truncated HTML. Twenty-three
Missouri tests pass. Live payload is private in work/missouri_scope/live_catalog.json.
Next approved app model integration and directory audit; no agency data, public
feed promotion, email or deadline change.

## October 7, 02:06 ET — bounded public locator audit

Reopened the [official locator](https://www.molottery.com/where-to-play/where-to-play.do)
and submitted its ordinary Jefferson City/local-only/all-products search. The
response has 66 business rows, four product labels (Draw Games, Scratchers,
Keno 2 Go, Club Keno), names, street/city and ZIP in directions links. It includes
mobile/subscription/agency-named entries; these are not assumed ordinary stores.
This is one query, not a statewide directory count or completeness result.

Strict local-result parser verifies columns, required address/name fields,
product labels, ZIP/address consistency and duplicate identities. Source hrefs
contain unescaped ampersands/hash characters in names; their literal address
suffix is inspected without navigating or inventing coordinates. No retailer
identifier or latitude/longitude is supplied by this response; those fields
remain null. Two parser tests pass, 25 Missouri tests total; all 66 captured rows
validate privately. Nothing promoted or joined to wins. Next privately audit the
already-delivered agency workbook and reconcile directory scope/position evidence,
while report/catalog app integration remains pending. No Gmail or new email in
this run; no deadline change or acceptance.

## October 7, 03:07 ET — Flutter report asset and fallback loader

The validated public-source 28-report snapshot is bundled with a Missouri-specific
loader. Dates/session keys and official report URLs are checked together; all
14 groups require two unique source dates. Base/add-on variants, count/payout
units, literal jackpot/range/zero labels, $.50 play basis and fractional cents
remain separate. Unknown distinct-ticket/cash values and unverified finality are
preserved. Mega Millions payouts are bounded by ranges when no jackpot wins.

Remote validation or continuity failure falls back to validated cache, then the
bundle. Cache-write failure does not discard a valid remote result. Four Flutter
tests cover bundle loading, malformed remote retention, timestamp regression,
persistence failure, missing sessions and changed fractional amounts; focused
analysis is clean. This is app data preparation, not an endpoint deployment or
native UI pass. Catalog/directory and report sheet remain pending. No private
agency records, retailer joins, fees, email or deadline change.

### October 7, 04:08 ET — navigable Missouri report sheet

Missouri's state source screen now opens the 28-report sheet. All eight families,
14 session groups, separate base/add-on variants, literal prize labels, source
counts, fractional payouts and $.50 play basis are presented without inferred
cash options or distinct-ticket totals. Draw dates and retrieval time remain
separate; publication date/finality limitations and eight official product/history
routes are visible. Powerball main totals explicitly exclude Double Play.

Two widget tests traverse every report through its tiers and retrieval footer at
390×844 and 1400×1000; both pass. The four loader tests also pass and focused
three-file analysis is clean. Ordinary macOS release build passes (not relaunched;
no native UI claim). Endpoint publication, catalog/directory integration,
state transaction and native acceptance remain pending. No private agency data,
Gmail/email, deadline change or acceptance.

### October 7, 05:08 ET — literal Scratchers catalog bundle and cache loader

The privately validated public-page inventory is now bundled as a separate
73-game catalog asset. Its Missouri-specific remote/cache/bundle loader checks
unique game and tier identities, official detail URLs, calendar dates, ticket
prices, literal advertised amount/top-tier agreement and unclaimed counts bounded
by original prize counts. Listed end dates and null source verification dates
remain intact. These fields do not become cash-option amounts, retailer stock,
winning-ticket totals or claim dates in the generic catalog.

Malformed responses, retrieval-time regression, changed existing game identity
and large catalog drops retain valid cached bytes/data. Cache-write failure does
not discard valid remote data. Four focused loader tests pass and two-file
analysis is clean. Catalog UI, directory audit/integration, transactional refresh,
endpoint publication and native acceptance remain pending. No new live endpoint,
Gmail/email, private agency promotion, deadline change or acceptance.

### October 7, 06:08 ET — searchable literal Scratchers inventory UI

The Missouri source screen now opens an in-app inventory sheet with game/name
search, ticket-price filter and selection across all 73 bundled games. Detail
shows literal advertised prize labels, original/unclaimed prize counts, start and
listed end dates (including TBD), retrieval time and daily cadence. Prominent
text keeps source verification date unavailable and distinguishes estimated
inventory from store stock, dated claims and immediate cash values. Official
listing/detail routes remain available; no cash-prize conversion or winner map.

Three widget tests pass: every game's tiers/footer at compact and wide sizes,
and search/price-filter recovery from empty results. Focused three-file analysis
is clean. Ordinary macOS release build passes (not relaunched; no native
interaction claim). Directory audit/integration, state transaction, live endpoints
and native acceptance remain pending. No Gmail/email, private agency promotion,
deadline change or acceptance.

### October 7, 07:08 ET — transactional refresh and endpoint staging

Missouri's scheduled job now owns the existing Show Me Cash totals plus the
literal Scratchers catalog and 28-report snapshot as one three-output transaction.
Failure at any of the three importers restores all prior output bytes and dates;
nine transaction tests pass, including each Missouri failure position. The
publication workflow stages separate catalog/report endpoints consumed by the
Flutter loaders; the literal catalog is not coerced into the generic cash schema.
Reviewed public-source baseline files are staged. This is wiring and staging,
not proof of successful deployment, scheduled refresh or native adoption.

Directory private audit/integration and native acceptance remain open. Next
verify deployment/public bytes and the scheduled three-output job while completing
the directory audit. No Gmail/email, deadline change or acceptance.

### October 7, 08:09 ET — endpoint verification and private directory audit

Publisher 37612210271 completed successfully. Independently downloaded Missouri
report and literal Scratchers endpoints match reviewed asset bytes exactly
(112,831 and 170,114 bytes). Scheduled three-output execution and native adoption
are still unverified; deployment is not state acceptance.

Retrieved the already-delivered September 23 agency workbook using a narrowly
targeted attachment lookup because the active directory integration depends on
its schema. This was not a routine inbox check and no email was sent. The original
115,177-byte workbook is retained privately. Read-only XML inspection of Sheet2,
A3:B4795 finds 4,793 business rows under only Business Name and City. No street,
ZIP, coordinates, retailer IDs, product flags or source verification date columns
are supplied. No formula cells were found. This is a structural/data audit, not
a visual workbook certification or current statewide completeness claim.

Whitespace/case normalization yields 4,742 distinct name/city pairs, 41 repeated
pair groups (51 excess rows) and 639 city labels, not verified distinct cities.
All 66 previously captured local locator rows have name/city candidates in this
file; two match nonunique agency pairs. These are candidate comparisons, not
approved identity/position joins. Agency/mobile/subscription entries remain
included as source records, not presumed ordinary stores. Raw rows and duplicate
keys remain private; no agency layer or guessed position is published.

Next implement a supported directory experience with explicit address/position
limits, using verified public locator evidence; do not geocode names/cities into
invented store positions. Then finish scheduled refresh/native acceptance.
Release deadline unchanged; Missouri not accepted.

### October 7, 09:10 ET — bounded public directory importer

Added an atomic public locator importer for explicit local-only city queries,
using all three official product-group selections. Request identity is retained
with the snapshot and returned city labels must match the requested city. It
rejects empty/partial/malformed responses, mismatched city baselines and large
result drops; unchanged content preserves retrieval time. Coordinates and
retailer IDs remain null. Three focused locator tests pass, including failed
request/parse/query preservation of prior bytes and dates.

Fresh private live queries validate 66 Jefferson City and 85 Columbia rows.
These are separate local result sets, not a statewide count or completeness
claim; no private workbook row or coordinate join is promoted. Next integrate
an explicitly bounded address-directory experience and official statewide search
route, then native acceptance and scheduled refresh verification. No Gmail/email,
public directory promotion, deadline change or acceptance.

### October 7, 10:11 ET — explicitly local address directory UI

Bundled the validated public Jefferson City (66) and Columbia (85) query snapshots
and added a navigable directory sheet. City selection, name/address/ZIP search
and source-product filtering retain source addresses without creating map pins.
The UI prominently limits bundled coverage to these two cities and offers the
official locator for other Missouri locations. Source retrieval dates remain
visible; stock, ordinary-store status, winner links, coordinates and completeness
are not inferred. This is a dated bundle, not a live statewide directory or an
automatically refreshed directory endpoint. No private agency rows are included.

A strict bundle validator rejects query/city mismatch, duplicate identities,
unknown product labels, malformed ZIPs and supplied coordinates/IDs. Three tests
pass, covering validation and compact/wide city/search/product interactions;
four-file analysis is clean. Ordinary macOS release build passes (not relaunched).
Next ordinary native verification, source-return,
failure recovery and scheduled three-output adoption. The bounded directory
limitation remains part of release review. No Gmail/email or deadline change;
Missouri not accepted.

### October 7, 11:11 ET — scheduled refresh and ordinary native opening

Scheduled run 37628614038 (head eacc2e5, bot 60aa90a) completed successfully
and Missouri reports updated all three owned outputs. Independently downloaded
public reports, literal Scratch catalog, published Show Me Cash totals and refresh
status exactly match the checked-in public bytes. This closes the scheduled
three-output integration checkpoint; it does not complete native acceptance.

Restarted the ordinary macOS Release app and navigated Find State → Missouri →
source screen → draw reports. The app adopted Show Me Cash 2,122,702 through
October 6 and report retrieval 2026-10-07T13:39:10.802496+00:00. Powerball October 5
renders multiplier 2, main 8,461/$43,839, base 7,319/$33,617, Power Play
1,142/$10,222 and separate Double Play 849/$9,046; unavailable Power Play jackpot
cells remain unavailable. Mega Millions October 6 renders all nine literal
Jackpot/range tiers, 3,480 source prizes and $65,753 payout, with publication-date,
finality, identity and retailer-map limits retained. Private native evidence and
public-byte hashes are saved under work/missouri_native.

Next continue the remaining six report families/session types, source open/return,
local directory and Scratch native flows, compact/wide and request-failure recovery,
then consolidated release verification. No accessibility certification, OS-offline,
map-tile or statewide-directory completeness claim. No Gmail/email or deadline
change; Missouri is not accepted.

### October 7, 12:13 ET — remaining report families in the ordinary app

Continued the running ordinary app without repeating state opening. Selected
and inspected the remaining six families, including scrolling longer tables:
Xs & Os October 4 (five tiers, 844/$13,057); MO Millions October 3 (eight main
and eight Double Play tiers, 5,963/$26,532 and 870/$4,968); Show Me Cash October 6
(four tiers, 5,149/$11,662); Pick 3 October 6 Midday (five base and five Wild Ball
rows, combined 544/$77,380); Pick 4 October 5 Evening (ten base and ten Wild Ball
rows, 72/$19,260.5, including literal $7.5 prizes); Cash Pop October 7 Early Bird
(22 prize amounts, 214/$9,421). Values agree with the validated feed. The literal
Pick 4 source formatting preserves the half-dollar amount rather than rounding.

Source units, $.50 play basis, Bulls-Eye and variant separation, null identity,
printed-zero jackpot caveat and unverified finality remain present. Footer
retrieval remains 2026-10-07T13:39:10.802496+00:00. Private native captures are
under work/missouri_native. All eight families now have a native selected-report
check; this does not mean every report/session or responsive layout is checked.

Next remaining Pick 3/4 and Cash Pop session types, source-open/return, native
Scratch and two-city directory interactions, larger layout and request-failure
recovery, then consolidated release checks. App left at Cash Pop Early Bird.
No code/feed change, repeated automated suite, Gmail/email or deadline change;
Missouri remains unaccepted.

### October 7, 13:15 ET — remaining native session types

Continued the existing report sheet and checked Pick 3 October 6 Evening
(430 source prizes/$45,685) and Pick 4 October 6 Midday (399/$149,443), retaining
separate base/Wild Ball rows and $.50 basis. Checked the four remaining Cash Pop
session types for October 6: Late Morning 164/$5,887; Matinee 281/$11,549;
Prime Time 186/$7,648; Night Owl 74/$2,593. Scrolled each Cash Pop report through
all 22 prize amounts and the source-unit/finality/identity limitations. Observed
totals match the validated feed, and retrieval remains October 7 at
13:39:10.802496 UTC. Private Night Owl captures are under work/missouri_native.

Native coverage now includes all eight families and all 14 game/session groups
at least once, including both Pick 3/4 types and all five Cash Pop types; it is
not a claim that all 28 dated selections have been manually checked. The existing
widget suite covers all 28. Next source-open/return, native Scratch/two-city
directory interactions, larger layout and request-failure recovery, followed by
consolidated release checks. App left on Night Owl October 6 near the footer.
No code/feed change, repeated automated suite, Gmail/email, deadline change or
acceptance.

### October 7, 14:16 ET — source return and local directory native flows

Opened Night Owl October 6 from the native report footer. The external official
page loaded the exact type=5/date=2026-10-06 route, visibly identified Night Owl
and showed 74 winners/$2,593 with matching prize rows. Closed that task-created
tab and returned to the retained native Night Owl selection, footer limitations
and unchanged 13:39:10.802496 UTC retrieval. This verifies source navigation and
return, not an accessibility certification.

Opened the local directory from the state source screen. Jefferson City shows
66 local query records and its original retrieval. Searching American Legion
returns the supplied address and Draw Games/Club Keno labels; selecting Scratchers
produces a scoped zero-match view, resetting All products restores the record,
and clearing search restores 66. Switching to Columbia shows 85 records and its
separate 13:12:00.454311 UTC retrieval. The two-city-only notice, official other-
locations route, unknown coordinates/source date and stock/winner/ordinary-store
limitations remain prominent. No statewide count, map pins or private agency
rows are inferred. Private source and native captures are in work/missouri_native.

Next native Scratch flow and external statewide-locator route, larger layout,
request-failure recovery and consolidated release checks. App left at Columbia
with search cleared and All products selected. No Gmail/email, code/feed change,
deadline change or acceptance.

### October 7, 15:16 ET — native Scratch filters and official locator route

The directory's other-locations button opened the official Where To Play page,
with city/ZIP, radius and game selections available. Closed that task-created tab
and returned to the app. This verifies the route, not statewide directory contents.

Opened the native Scratch inventory: 73 listed games, including ended games.
Searching 777 selected #505 777 JACKPOT with its literal $777,777 top prize and
April 17 listed end date. Intersecting that search with $1 tickets produced a
scoped empty view; clearing the search restored six $1 games. Selected #566 HOT
7S, verified its TBD end date, literal $7,777 top prize and total/unclaimed rows,
then scrolled to source limits and retrieval 2026-10-07T13:39:07.151863+00:00.
Resetting All ticket prices restored all 73 games and the default #359 24K GOLD.
Estimated inventory, source-date unavailability, cash-option and stock/claim
limitations remain visible. Private footer evidence is in work/missouri_native.

Next larger native layouts and request-failure recovery, then consolidated
release checks. Native Scratch external detail route remains to verify alongside
those checks. App left on the full catalog/default game. No Gmail/email,
code/feed change, deadline change or acceptance.


### October 7, 16:17 ET — wide native layouts and Scratch detail route

Expanded the ordinary native window from a 1600×1264 screenshot to 5120×2820.
Scratch inventory, local directory and Powerball reports retained readable,
centered sheets. Visually checked the full #359 24K GOLD prize table and footer,
directory scope/filter/address presentation, and Powerball variants plus source
limits and retrieval footer. These are native layout checks, not mobile or
accessibility certification.

The Scratch detail button opened the official game=359 page, identifying 24K
GOLD, its $20 ticket, $2 million advertised top prize, matching prize counts and
listed dates. The official page explains daily inventory updates and that
unclaimed prizes can already have been purchased but not redeemed. Closed the
task-created tab and returned to the native app. No cash-option, stock or claim
conversion was made.

Restored the original 1600×1264 native window and left the Powerball report
selected. Private screenshots are under work/missouri_native with the
2026-10-07_16 prefix. Next bounded request-failure/reconnect verification and
consolidated release checks; Missouri is not yet accepted. No Gmail/email,
code/feed changes or deadline change.
