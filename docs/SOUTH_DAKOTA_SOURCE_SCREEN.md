# South Dakota source screen — September 15, 2026

The South Dakota Lottery's official [Winning Players](https://lottery.sd.gov/winning-players/)
page publishes selected winners with claim date, game, prize, selling retailer
and city. The page describes these as players who won top prizes, so the list
does not prove complete all-tier coverage. Its records are useful verified
retailer-linked activity only when labeled as a selected-winner subset.

The official [Locations](https://lottery.sd.gov/locations/) page provides a
retailer search and can display recent published winner activity at individual
locations. An older official retailer PDF is also indexed publicly, but its
current completeness and stable update cadence have not been established.
Neither source proves a complete current retailer directory or a join for every
validated winning ticket.

An August 1–31, 2026 records and routing request was emailed September 15 to
the Lottery address published on both the Lottery and Department of Revenue
contact pages. It requests existing all-tier Lotto and Scratch winning-ticket
records, a complete active-retailer directory, winner-to-retailer joins, data
definitions, cadence and corrections. The request excludes claimant personal
information and asks staff to route it to the correct records custodian if
needed. Gmail confirmed “Message sent.” Requester contact information was
supplied directly and is not stored in this repository.

South Dakota remains suitable only for clearly labeled selected-winner
activity until responsive records establish complete coverage. It is not ready
for full-state testing.

## September 20, 2026 official catalog/API audit

The [Scratch Games page](https://lottery.sd.gov/scratch-games/) embeds a
Next.js `__NEXT_DATA__` payload. Its `post.blocks` Scratch-filter attributes
contain 100 game entries: 32 marked active, 64 closed and four upcoming;
additional featured/second-chance/closing tags can overlap these statuses.
The initial HTML has an empty rendered game grid, but the embedded catalog
is present. Do not infer an empty catalog from server-rendered text alone.
The 100-entry listing has no verified completeness/pagination metadata in
this audit, so it is a published-list subset, not proof of every state game.

Public site JavaScript calls
`/api/igt/games/v1/instant-games/games/{igtIdentifier}`. All 32 explicitly
active entries were retrieved successfully and agree with that endpoint's
`ACTIVE` validation status and explicit listing ticket prices. They contain
268 prize-tier rows. The API expresses ticket and cash prize amounts in cents;
the site's display divides by 100. Its remaining-count calculation is
`winningTickets - paidTickets`, with top prize selected from prize tiers.
Every audited tier has integer nonnegative counts and paid <= winning, and
every game has unique tier numbers. Preserve the components alongside any
derived remaining count. These are cumulative inventory/paid quantities,
not claims assigned to the requested 2026 period or retailer-level activity.

The endpoint supplies distribution/disable dates but no inventory verification
timestamp in the inspected responses. Do not convert a far-future operational
date into a verified consumer claim deadline. Publication cadence is unconfirmed;
retrieval time must stay separate from source verification time. Before an
import is enabled, add tests for cents conversion, explicit active status,
missing/negative/impossible counts, duplicate tiers, listing joins and the
100-entry coverage limit. No South Dakota public feed was changed in this pass.

Reproducible read-only audit materials are in ignored
`work/south_dakota_catalog/`: source HTML/JavaScript, `active_listing.json`,
32 official inventory responses, `audit.py` and `inventory_audit.json`.
The September 15 records request remains pending; no duplicate was sent.

### Validated subset import

A fresh official fetch validated 32 explicitly active games and 268 prize tiers.
The importer verifies Scratch type, unique identifiers, active-status agreement,
explicit listing/API ticket prices, cents conversion, unique tier numbers and
nonnegative integer inventory with paid <= original winning inventory. It finds
the maximum prize rather than relying on API tier order. Ambiguous top tiers,
missing fields and contradictory status stop publication before file replacement.

The combined feed and offline bundle now carry this subset. Every game discloses
published-subset scope, cumulative inventory semantics and unknown verification
time/store availability. `sourceDate` remains null; `updatedAt` is retrieval/change
time. Distribution and disable dates are deliberately not mapped to claim dates.
The six-hour refresh checks these same constraints. Five importer regression tests
and an offline app-loading test cover the core boundaries. This is catalog-ready
partial coverage, not all-state claims coverage or a completed retailer heat map.


## October 18 activation — current official route capture

South Dakota activated October 18, 2026 at 04:24 ET; scope due October 19, 2026 at 04:24 ET;
supported release due October 23, 2026 at 04:24 ET. See SOUTH_DAKOTA_ACCEPTANCE.md.
Fresh home/Lotto/Dakota Cash/winning-number HTML is private in
`work/south_dakota_scope/`, with retrieval metadata. Current navigation lists
Powerball/Double Play, Mega Millions, Dakota Cash, Millionaire for Life, Lotto
America and Powerball Xs & Os. Related-game content also retains Lucky for Life;
status is unresolved. Dakota Cash metadata mentions EZ Match. Actual draw API,
options, history and literal schedules remain to inspect before scope closure.
The Dakota Cash page's selected-winner cards include Powerball records: do not
assign cards to the hosting page's game. No new public feed, build or acceptance
claim is made. Existing Scratch validation remains intact; fresh audit pending.


## Scope closed October 18 at 05:22 ET — public API and product dispositions

Scope closed early; release deadline remains October 23 at 04:24 ET. This is
research scope closure, not collector/app/native acceptance.

| Product | Supported target and boundary |
| --- | --- |
| Powerball / Power Play / Double Play | Two completed draws each for base and Double Play, separate result groups; literal option schedules. Never attach base advertised jackpot to Double Play. |
| Mega Millions | Two completed results and full literal multiplier schedules. API multiplier prize rows kept distinct; geographic count attribution requires separate validation because this component says only Winners. |
| Dakota Cash / EZ Match | Two completed draw results, literal base and eight-row EZ Match prize/odds schedules. EZ Match is ticket-specific instant matching, not another dated draw. |
| Millionaire for Life | Two completed results and literal annuity/cash qualifications; zero top-tier API amounts are not zero-value prizes. |
| Lotto America / All Star Bonus | Two completed results, distinct multiplier semantics and literal schedules. |
| Powerball Xs & Os | Two completed team results using explicit source ID/team map, all literal rules and schedules. |
| Lucky for Life | Historical official route only. API returns February 21/20 local completed results followed by NO_MORE_DRAWS with a 1941 sentinel timestamp; no next draw or current-game claim. |
| Scratch | Fresh validated published active subset: 35 games, 293 tiers out of a 100-entry listing. Source verification timestamp remains null; original/paid/remaining quantities are cumulative inventory, not dated claims. All tiers required in app. |
| Video Lottery | Official overview and licensee/reports routes only; machine play, per-play results, claims and machine positions unsupported. |
| Retailers / selected winners | Official locations and selected-winner routes; no imported joins/coordinates or complete directory/claims claim. Locations default returns a bounded 96-result view, not proof of statewide completeness. |
| Players Club / second chance / mobile cashing | Official routes only; no login, entries, purchases or claims transactions in Atlas. |
| Older history | Official winning-number search route; ten-year import deferred. |

Target: **14 bounded results across six current families/seven result groups**,
plus literal game/option schedules and full supported Scratch tiers. No daily
Midday/Evening split was found in these current products; preserve source draw
identity and variant rather than inventing sessions.

The site's actual public request is
`/api/igt/games/v2/draw-games/draws?game-names=...`; past-number search adds
`date-from` and `date-to` Unix milliseconds. Six current identifiers each return
one OPEN record and two PAYABLE records. Select by status/results, never array
index. Powerball has Regular and Double Play result objects in each completed
record; repeated tier IDs across variants cannot serve as globally unique keys.

Preserve raw drawTime milliseconds and derive the calendar date explicitly in
America/Chicago. These API timestamps do not establish exact physical drawing
times; do not present their 21:15 operational value as broadcast time. The
estimatedJackpot field is cents while jackpots.amount and prize shareAmount
are dollar-valued in the site's respective formatters; never apply one global
unit conversion.

Official winning-number JS labels the generic table **SD Winners**, binding
shareCount to that column and multiplierShareCount to a separate SD option
column. This supports a source-labeled count unit, not unique persons or paid
claims. Mega Millions uses a different renderer, so geographic attribution and
zero/dash placeholders remain separate validation questions; exclude unsupported
counts rather than infer them. Xs & Os renderer suppresses the prize column;
use its literal schedule independently.

Private evidence: all seven current detail pages, Lucky for Life detail,
public responses and draw-api-audit.json; extracted *-rules.json; source JS
2-dti7y5tqmn2.js (history/table binding), 3ya3s1xnb6tvy.js (API client/card);
scratch-fresh.json and official route captures in work/south_dakota_scope.
No public feed or native build changed. Next: strict parsers for status,
date, variant, count units and schedule extraction, then coupled publication,
app integration and native gates.
