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
