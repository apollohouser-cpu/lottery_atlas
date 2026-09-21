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
