# North Dakota source screen — September 14, 2026

The North Dakota Lottery's [current games page](https://www.lottery.nd.gov/games/)
lists Powerball, Mega Millions, Millionaire for Life, Lotto America and 2by2.
It does not list a Scratch or instant-ticket product. That page establishes the
currently advertised draw-game catalog, but it is not a complete all-tier count
of winning tickets.

The official [Winners page](https://www.lottery.nd.gov/public/winners/) warns
that it is only a partial listing because winners may remain anonymous. The
[retailer page](https://lottery.nd.gov/retailers) publishes winning retailers
for prizes of $5,000 or more, including draw date, amount, game, retailer and
city. Those thresholds and omissions prevent the public pages from supporting
a complete statewide winning-ticket total, retailer heat map, or ranking. The
Lottery also says it has more than 400 licensed retailers and links a locations
PDF, but a current machine-readable directory with stable retailer identifiers
and a complete winning-ticket join has not been verified.

On September 15, the North Dakota Lottery replied that it does not track
low-tier prizes and that the public Winners page includes the retailer that sold
each published winning ticket. It identified its FAQ retailer list and the
Winning Retailers page for sellers receiving a bonus on prizes of $5,000 or
more. The Lottery also confirmed that these website updates have no fixed
cadence and are made when the Sales and Marketing Manager has time, and that
North Dakota offers no Scratch/instant tickets because state law permits only
multi-state games. This agency response verifies the scope and cadence but also
confirms that the requested complete all-tier count is not maintained. North
Dakota remains a partial public-winner subset and is not ready for full-state
testing.

## October 27, 2026 at 11:29 AM EDT — sole active state

North Dakota activated after Wyoming acceptance. See NORTH_DAKOTA_ACCEPTANCE.md.
Scope due October28 at11:29AM EDT; supported release due November1 at10:29AM EST
(120elapsed hours across the DST transition), no extension. Two official opening
pages captured15:29:38–39UTC with hashes privately retained. Current navigation
identifies five draw families, Power Play and All Star Bonus, and explicitly
retired Lucky for Life. Exhaustive scope and payload/rule semantics remain next.
Prior agency limitations stand; no duplicate request or invented Scratch product.
No new public feed/build/acceptance. Android ordinary app stays running.

## October 27 — supported scope and source structure fixed

The full supported product/history/gap matrix is fixed before the October28
11:29AM EDT scope deadline. Twelve game/history pages and the common FAQs and
promotions page were captured with original timestamps and hashes privately in
work/north_dakota_scope/game-manifest.json and scope-extra-manifest.json.
Current results are server-rendered HTML tables, not an unverified dynamic API.
Ten rows each are exposed for PB/MM/MFL/Lotto America,30 for2by2 and10 retired
Lucky for Life rows. These are raw source rows, not accepted results.

| Product / variant | Supported implementation target | Explicit gap/boundary |
| --- | --- | --- |
| Powerball / Power Play | Latest two dated results, five numbers plus Powerball and published multiplier; literal base/multiplier table and prose | Jackpot column is advertised amount, not actual won payout; Double Play not established by current ND catalog, unavailable |
| Mega Millions | Latest two dates; five numbers and Mega Ball; literal base/range table and per-play2/3/4/5/10x rules | Archive retains legacy Megaplier header with N/A; never infer drawing-wide multiplier; pre-April2025 formats unavailable |
| Millionaire for Life | Latest two dates; five numbers and Millionaire Ball; nine-tier schedule and annual lifetime caveats | Annual prizes not lump sums; exact draw instant absent, no inferred timestamp |
| Lotto America / All Star Bonus | Latest two dates; five numbers, Star Ball and published multiplier; literal base/bonus table | No inferred actual jackpot payout or complete history |
| 2by2 | Latest two dates with separate red/white groups; qualifying Tuesday doubling and categorical Free Ticket/2 Free Tickets | Tuesday doubling requires qualifying consecutive7-draw increments; no generic doubling of every ticket |
| Lucky for Life | Explicit retired status, ended February21,2026 | Retained final results not imported into current catalog; full retired history unavailable |
| Other retired games / older versions | Explicit unavailable history | No inferred legacy results, formats or current products from historical names |
| Scratch / instant | Confirmed absence from prior agency response | No synthetic catalog or inventory |
| Pick & Click | Source-linked sales-channel explanation only | Not a separate drawing game; no purchase, account or subscription automation |
| Players Club / Points for Drawings / second-chance promotions | Source-linked promotional limitations | Credit/merchandise promotions and partial winner notices are not ordinary draw results or all-tier counts; no entries submitted |
| Winner counts / retailer activity | Explicit unavailable exact-date all-tier reports and joins | Prior agency says low-tier records not tracked; partial notices cannot supply complete claims or rankings; no invented coordinates |

Bounded release target is10 results across five current families, all reports
unavailable unless independently verified. Current-year/previous-year archive
links are present for some games; their existence does not establish a complete
validated archive. Full/ten-year history is excluded from this release.

Five current game pages contain62 physical HTML table rows including headers,
merged cells and footers (PB13, MM13, MFL12, LA13,2by2 eleven). These require
literal rowspan/colspan handling; the initial private extraction is not a final
schedule validator or visual audit. Do not count every physical row as a tier.
FAQ draw times are prose only: PB9:59PM CT, MM10PM CT, LA approximately9:15PM CT,
MFL after10:15PM CT,2by2 approximately9:30PM CST. Preserve approximate/after and
literal CST wording; date-only result rows do not authorize fabricated UTC times.

Next strict date/identity/range/header parsers and literal rule/table contracts,
then coupled atomic collection/publication, Dart/UI/native and retention. No new
public feed/build/acceptance. Nineteen accepted,26 unfinished; North Dakota sole
active; November1 10:29AM EST release deadline unchanged, no extension. Android
ordinary app stays running; accepted-state work remains closed.

## October 27 — strict date-only result parser

Implemented tooling/import_north_dakota_draws.py against the retained official
HTML tables. All70 current-family source rows validate (PB/MM/MFL/LA ten each,
2by2 thirty); the private latest-two candidate contains10 results. Original
source hashes were verified before parsing. No new collection or verification
time is assigned to those retained captures.

The parser binds the page heading, exact table/header shape, current family,
strict number cardinality/ranges, descending unique dates, weekday cadence,
UTC capture and Central capture-date boundary. September1,2026 is the reviewed
window floor, not a claimed game inception or format-change date. Older formats
remain unavailable. Date-only results stay date-only: no UTC drawing instant
or synthetic drawing ID is created.2by2 red and white groups remain separate.
PB/LA multipliers validate independently; MM legacy Megaplier must be literal
N/A, never a drawing-wide multiplier. Advertised jackpot cells are structurally
checked but excluded from actual-result payout data. All reports stay unavailable.

Ten focused tests pass, including retained source rows, wrong identities/headers,
merged/malformed markup, duplicate/reordered/future/older dates, wrong cadence,
number/multiplier failures and retired-game rejection. Public test fixtures
contain only extracted official table values and source provenance.

Next literal rule/table contracts with rowspan/colspan preservation, then
coupled atomic collection/publication and app/native integration. No new public
feed/build/acceptance. November1 10:29AM EST release deadline unchanged, no
extension; North Dakota sole active. Android ordinary app remains running.
