# Missouri source screen — September 12, 2026

Missouri is **deferred for the current-data launch heat map**. Preserve the
existing Missouri schedules, official links, starter Scratch catalog, and
verified historical winner point.

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
