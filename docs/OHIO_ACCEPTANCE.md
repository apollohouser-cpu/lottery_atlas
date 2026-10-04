# Ohio supported-coverage acceptance

Activated October 3, 2026 at 19:12 ET as the sole active state following New
York acceptance. Existing working catalog, directory and winner imports qualify
for 72 hours: release decision October 6 at 19:12 ET; full game-scope and gap
reconciliation October 4 at 19:12 ET. Not accepted.

## Selection and opening evidence

Ohio and Colorado both have three working imports. Ohio is selected next on
readiness; no newer user priority is recorded. Its separate agency request is
awaiting response after the user personally confirmed October 2. No repeat
attestation, fees or records dependency is introduced.

- 74 official Scratch catalog games.
- 10,642 mapped directory locations and 10 unresolved entries; unresolved
  entries must not become precise pins or distances.
- 136 selected physical-retailer winner releases; 52 excluded entries.
  Latest source publication October 2. No complete statewide claims assertion.
- Opening audit identified malformed Scratch titles including prose fragments
  and “several”; importer lines 89–93 use a loose prose fallback like the
  previously corrected NY defect. Next replace unverified titles conservatively
  and compare every other field before promotion.
- Winner inventory includes KENO and EZPLAY, which require explicit product
  classification and separate limitations; never silently treat them as Scratch.

## Required scope reconciliation

Explicitly cover Powerball, Mega Millions, all currently supported Ohio state
draw games and Scratch. Reconcile Pick 3/4/5, Rolling Cash 5, Classic Lotto,
Millionaire for Life, historical Lucky for Life, KENO, EZPLAY and Cash Explosion
against official sources. This is a candidate inventory, not a claim every
product is a current recurring draw game. Establish actual payout/count reports,
jurisdiction, units, dates and cadence; numbers-only pages are not tier counts.

## Acceptance checklist

- [x] Full per-game scope/gap matrix closed October 4 02:00 ET, before October 4 19:12 ET.
- [ ] Winner category/title/date provenance and retained-data audit.
- [ ] Supported reports/source routes and cache/bundle integration.
- [ ] Native compact/wide catalog, retailer, map, filters/reset, detail/source.
- [ ] Native request failure/reconnection with accurate limitations.
- [ ] Focused automated checks, ordinary build and independent live evidence.
- [ ] Consolidated release decision by October 6 19:12 ET.

Opening repository fast-forwarded to bot922ed58; publisher37159640506 succeeded.
No new agency emails. Accepted states and closed maintenance are not reopened.

## October 3, 20:00 ET — unverified Scratch title correction

Removed the loose prose fallback for catalog-unmatched Scratch game titles.
Those rows now explicitly say Ohio Scratch-Off (game name unverified). Two fresh
private imports before/after contain 136 rows and exactly 13 title differences;
all other row fields match and top metadata differs only by retrieval timestamp.
Only those 13 names were promoted into the retained baseline, preserving every
other field, excluded row and top-level date/metadata exactly. The private fresh
imports had 53 excluded entries; the retained baseline's 52 were not altered.
Combined publisher validation passed with 24,112 records across 19 states.

Next full product/report scope and winner category/date audit. This closes only
the malformed-title defect, not Ohio acceptance. Publication verification pending.
No new agency emails; opening publisher37159640506 successful. Deadlines unchanged.

## October 3, 21:00 ET — publication-date semantics

Importer inspection confirms every current Ohio row uses article.date as the
release publication timestamp; no separate structured claim date is read.
Corrected the inaccurate coverage wording accordingly without changing any row
or timestamp. Ohio details now label PUBLICATION DATE and disclose selected
releases, unverified draw/claim dates and incomplete statewide counts. Ohio uses
whole-day source dates instead of implying event times. Scratch shortcuts now
use selected-release/publication wording as well. Changed map analysis is clean;
native verification remains pending.

Publisher37164249192 succeeded and the prior title-corrected public activity
bytes match. Next full game/report scope and product classification, then
validated integration and native acceptance. No new mail; deadlines unchanged.

## October 3, 22:00 ET — live draw API and omitted product found

Official [The Lucky One](https://www.ohiolottery.com/games/the-lucky-one) is a
separate monitor draw game; add it to scope alongside KENO. Published fixed
odds/prizes are not observed winner counts. The general drawings page retains
legacy Lucky for Life/Megaplier wording, so it cannot alone settle current scope.

The official app bundle, retrieved with the existing importer user agent, exposes
DrawGames/{game}/GetLatestDraws. Private authenticated public-site API captures
for Pick3, Keno and TheLuckyOne are saved under work/ohio_acceptance. Pick3 returns
actual prizes arrays with winnersNumber, description, payout and prizeTier,
plus draw identifiers and dates. These are candidate report data, not yet
validated ticket counts: wager units, session, jurisdiction and renderer labels
need reconciliation before integration. Initial ordinary Python fetch 403 was
resolved using the existing Node/user-agent route; no source-unavailable claim.
Next inspect the per-game report renderer and current product IDs, then complete
the scope matrix. No reports published in this session.
Publisher37167293021 successful; no new mail or deadline changes.

## October 3, 23:00 ET — per-game API inventory and session evidence

Captured GetLatestDraws for the ten game identifiers used by the official
archive renderer: MegaMillions, PowerBall, MillionaireForLife, ClassicLotto,
RollingCashFive, LuckyForLife, Pick3, Pick4, Pick5 and Kicker. Private response
files remain under work/ohio_acceptance. Add KICKER explicitly to scope as the
Classic Lotto add-on; the official [game rule](https://www.ohiolottery.com/getattachment/56f1ee36-1789-46eb-9abf-d83744b6b8fe/827_GameRule.pdf)
describes its separate six-digit matching game.

The official past-results renderer explicitly labels modifier 1 as Mid Day and
2 as Evening for Pick games. It displays prizePayout separately as dollars;
these values must not become ticket counts. Latest captures contain 12/13/25
prize rows for Pick 3/4/5, four each for Classic Lotto/Rolling Cash 5, five for
KICKER, nine for Millionaire for Life and ten for historical Lucky for Life
(last February 21). The current Powerball and Mega Millions latest responses
have empty prizes arrays: this is a specific endpoint gap, not proof that
reports are unavailable.

Tier winnersNumber units and jurisdiction still need direct reconciliation.
In particular, Pick 3 Straight payout 250 does not itself prove distinct-ticket
units; Millionaire for Life top numeric payouts 20,000,000 and 2,000,000 must
not be presented as verified cash awards or replace annual-for-life wording.
The app bundle does not directly render winnersNumber. Next inspect the actual
per-game payout view/alternate report route, then close the complete scope
matrix including monitor games, EZPLAY and Cash Explosion. No candidate
reports promoted. No new agency mail; deadlines and acceptance status unchanged.

## October 4, 00:00 ET — official game tabs and product classification

Captured the official draw-detail component's GetGameInformation responses for
Pick 3, Powerball, Mega Millions and Millionaire for Life privately. These
provide the rendered rule/odds tabs, not observed tier winner reports. Pick 3's
[official game page](https://www.ohiolottery.com/Games/Draw-Games/Pick-3)
tab explicitly separates $0.50 and $1 payouts: the API's Straight 250,
3-way box 83.50 and 6-way box 41.50 match its $0.50 column. This establishes
prize denomination, not the meaning of winnersNumber; distinct tickets remain
unverified. Both wager sizes are permitted, and a back-up combines straight
and box bets on one ticket.

Millionaire for Life's official tab specifies $1,000,000/year for life and
$100,000/year for life, with a 20-year guarantee. Its FAQ gives cash options
of $18,000,000 and $2,200,000, so the latest-report numeric top-tier values
20,000,000/2,000,000 must not be labeled cash. Preserve annual-for-life labels
and disclose the raw numeric-field limitation if reports are integrated.
The FAQ explicitly dates replacement of Lucky for Life to February 22, 2026.

The [official EZPLAY page](https://www.ohiolottery.com/Games/EzPlay-Games)
identifies terminal-generated instant tickets with no drawing. Current importer
classifies its seven selected releases as state-draw: a concrete classification
defect to fix before acceptance, without recasting EZPLAY as Scratch. Review
the shared game-category schema and preserve all other row fields when fixing.
The [games overview](https://www.ohiolottery.com/games) separates Cash Explosion
as a television game show; three selected releases are named Cash Explosion
and also require a product-category audit rather than assuming recurring draws.

Next fix this product-category defect, finish the scope matrix, and bound the
remaining tier-count-unit/source gap before integration. Latest/candidate API
responses remain private. Gmail checked once with no new relevant message.
No acceptance or deadline change.

## October 4, 01:00 ET — instant terminal and game-show categories fixed

Added explicit terminal-instant and game-show activity categories throughout
model serialization, labels/icons, game/stats rendering and publisher validation.
Ohio's seven EZPLAY and three Cash Explosion releases now use those categories;
neither is counted under State Draw Games or Scratch-Offs. Existing filters
enumerate the shared categories and All Games continues to include them.
Importer emits these categories for future matching releases.

Exactly ten category fields changed in retained Ohio data; all other row fields
and all top metadata/exclusions remain identical. A fresh private import's 136
rows exactly match the corrected retained rows. Its 53 exclusions were not
promoted over the retained 52. Combined publisher validation passed with 23,773
records across 19 states. Seven focused Ohio tests pass including category
round-trip and offline bundled loading; changed production analysis is clean.
Ordinary macOS debug build passed; it has not yet been relaunched or natively
accepted. Older binaries do not recognize the new category codes and need the
updated build; native acceptance must use this build.

Next complete the scope matrix and bound report-unit gaps, then native
integration and publication verification. No new agency mail, deadline change
or acceptance decision.

## October 4, 02:00 ET — full scope and bounded report support

Scope/gap reconciliation is closed; this is not release acceptance. The official
app's current archive and game-detail routes, saved API responses and product
pages establish the following implementation scope. No broad roster research
remains. An unverified count stays unavailable and does not delay supported
coverage indefinitely.

| Product | Supported release scope | Explicit gap/constraint |
| --- | --- | --- |
| Powerball / Power Play | Selected publication-dated retailer releases and official game/results route | Latest API prize arrays empty; no Ohio tier counts or inferred national allocation. |
| Mega Millions / built-in multiplier | Selected retailer releases and current official game/results route | Latest prize arrays empty; no invented tier/multiplier winner totals. |
| Millionaire for Life | Selected releases and official game/rules route | Top prizes retain annual-for-life wording; raw 20M/2M fields are not verified cash. Tier jurisdiction/count units unresolved. |
| Pick 3 / Pick 4 / Pick 5 | Selected releases, separate Midday/Evening dates and published payout-dollar reports | No distinct-ticket counts; Pick 3 prize denomination is $0.50 but winnersNumber semantics remain unresolved. |
| Rolling Cash 5 / Classic Lotto | Selected releases, official results and published payout-dollar reports | Dollar totals remain separate from jackpot advertisements and all count fields. |
| KICKER | Separate Classic Lotto add-on official source route and schedule | No unsupported aggregation into Classic Lotto payout or retailer counts. |
| KENO / Booster | Selected KENO releases and official monitor/results route | No fabricated complete monitor history or prize-tier counts; multiplier is not a count. |
| The Lucky One | Separate official monitor-game/results source route | No inferred observed counts from fixed wager odds/prizes. |
| Scratch-Offs | 74-game official catalog and selected publication-dated retailer releases | Remaining inventory is not period wins/claims; unmatched game titles explicitly unverified. |
| EZPLAY | Selected terminal-instant releases and official product route | No draws; no Scratch classification or complete validation counts. |
| Cash Explosion | Selected game-show releases and official show route | Show prizes are not recurring draw results or a complete claims layer. |
| Historical Lucky for Life | Historical official source route, ending February 21, 2026 | No current recurring schedule; replaced February 22 by Millionaire for Life. |

Official entry points: [games](https://www.ohiolottery.com/games),
[draw games](https://www.ohiolottery.com/Games/Draw-Games),
[KENO results](https://www.ohiolottery.com/winning-numbers/keno-drawings),
[The Lucky One](https://www.ohiolottery.com/games/the-lucky-one),
[EZPLAY](https://www.ohiolottery.com/Games/EzPlay-Games).
Source-route availability is a required UI integration item even for games
without verified count reports. Retailer directory and publication-date
limitations continue to apply to every selected release.

Added a strict payout parser for the five groups whose official past-results
renderer displays prizePayout as dollars: Pick 3/4/5, Classic Lotto and Rolling
Cash 5. It requires approved reports, exact game identity, real calendar dates,
valid sessions and finite nonnegative payouts. It deliberately omits raw tier
counts, preserves zero dollars and emits null ticket counts. Three focused
JS tests pass; ten captured reports across five groups validate privately.
No report data published yet. Next implement bounded live import/continuity,
cache/UI/source routes and native acceptance; no further broad scope research.
No new relevant mail; release deadline remains October 6 19:12 ET.

## October 4, 03:00 ET — live payout importer and retained-data guards

Implemented import_ohio_draw_reports.mjs using the official public-site
authentication configuration and five observed GetLatestDraws routes. A live
run validated ten payout-dollar reports privately in
work/ohio_acceptance/live-payout-reports.json. No raw tier counts, internal
operator fields or authentication material are included in its output.

The importer requires at least two reports per game and both Pick sessions,
rejects duplicate identifiers/date-session slots, and prevents per-game/session
date or draw-number regression against the existing file. It writes a temporary
file and replaces the output only after every source validates. Five tests pass,
including failure at each of the five sources preserving baseline bytes, missing
session rejection, and date/draw-number regression rejection.

Next bundle/cache/report sheet and official source-route integration, then
four-output refresh transaction and native/live acceptance. Reports remain
private and Ohio is not accepted. No new relevant mail; deadlines unchanged.

## October 4, 04:00 ET — bundled reports and validated cache loader

Added the ten validated live payout-dollar reports as an explicit Flutter asset
and an Ohio-specific remote/cache/bundle loader. It requires all five groups,
at least two reports each, both Pick sessions, valid calendar dates and official
source links, unique report identities/date-session slots, finite nonnegative
dollars and explicitly null ticket counts. Cached game/session dates and draw
numbers cannot regress on a remote refresh. Invalid remote responses never
overwrite the cache; a persistence failure does not discard valid remote data.

Four focused loader tests pass, covering exact data preservation, offline cache,
bundle fallback and malformed/incomplete/inferred-count/regressing responses.
Changed-file analysis is clean. Reports are bundled but not yet navigable; the
remote endpoint and refresh transaction remain to be published. Next report
sheet and official source routes, followed by transaction and native acceptance.
No new relevant mail; Ohio remains unaccepted with unchanged release deadline.

## October 4, 05:00 ET — navigable payout sheet and product source routes

Ohio's state source screen now opens the payout sheet with ten report choices
across five groups, explicit dollar values, draw date/session/number, unavailable
counts, retrieval/cadence and scope limitations. Official source routes include
Powerball/Power Play, Mega Millions, Millionaire for Life, Classic Lotto/KICKER,
KENO/Booster, The Lucky One, EZPLAY, Cash Explosion and historical Lucky for Life.
Routes follow official site navigation; current monitor, terminal instant,
game-show and historical limitations stay distinct.

Compact and wide widget tests traverse all ten selections and the source footer.
An initial fixed-distance scroll test stopped short on compact layout; replaced
with scrolling until the historical route is visible. Both tests pass, changed
analysis is clean and the ordinary macOS debug build passes. Not relaunched or
natively verified yet. Next four-output refresh/publication transaction, then
native integrated acceptance. No new relevant mail or deadline changes.

## October 4, 06:00 ET — four-output refresh and publication integration

Ohio payout reports now join catalog, directory and selected releases in the
state refresh transaction. The publisher stages ohio_draw_reports.json and
tracks both the generated asset and public output. Six transaction tests pass,
including failure at each actual Ohio importer restoring all four baseline
files byte-for-byte. Dates are retained on failed refreshes.

The ten bundled report records are staged for publication. Deployment/endpoint
verification and scheduled Ohio transaction evidence remain pending; a push
publisher alone does not prove scheduled import success. Next verify endpoint
bytes and proceed with ordinary-build native integrated acceptance. No new
relevant mail, deadline change or acceptance decision.

## October 4, 07:00 ET — deployment and native opening verified

Publisher37194646320 completed successfully. An independent download of the
public ohio_draw_reports.json exactly matches the staged ten-report file.
Scheduled four-output refresh is still unverified.

Quit the previous process and relaunched the ordinary debug build. Native
Find a State → Ohio → OH LOTTERY → Ohio draw payouts opens Pick 3 October 3
Evening, draw 23904, published payout $362706.00, unavailable winner/ticket
counts, publication-date-unavailable and no-retailer-allocation disclosures.
Retrieval shown is 2026-10-04T07:13:35.742Z. Scrolling exposes national/monitor
sources, distinct EZPLAY terminal-instant and Cash Explosion show descriptions,
and historical Lucky for Life ending February 21. Ohio map showed source-only
whole-day dates and the scoped-empty October 4 state. No native failure found.

Next remaining report selections/source-open-return, compact/wide checks and
integrated catalog/retailer/detail/filter/failure-reconnect acceptance. Do not
repeat this completed opening route. No new relevant mail; no deadline change
or acceptance decision.

## October 4, 08:00 ET — native group selection, source return and wide layout

All five payout groups have now been selected in the ordinary native build.
Additional October 3 selections verified Pick 3 Midday draw 23903/$132494.00,
Pick 4 Evening 23561/$160900.00, Pick 5 Evening 10332/$121500.00,
Classic Lotto 3084/$23562.00 and Rolling Cash 5 10623/$178178.00.
Counts remain unavailable; source publication date and event-time limitations,
no retailer allocation, retrieval 2026-10-04T07:13:35.742Z and scheduled cadence
remain visible. Both Pick 3 sessions were distinguished. The dropdown offers all
ten reports; existing widget tests cover every selection.

Rolling Cash 5's source button opens the loaded official game/results page,
showing October 3 numbers 2, 4, 14, 17, 25. This page also contains static odds
and prizes; that is not independent proof of the imported actual payout dollar
amount. Returning to the app retains Rolling Cash 5 and its report details.
Zooming the native window to 5120x2820 retains a centered readable report with
all nine product/historical routes and their limitations visible without
clipping. Initial AX was empty until interaction, consistent with prior native
observations; this is not accessibility certification.

Next integrated catalog, retailer, publication-detail, category/date/prize
filters and failure/reconnect acceptance, then consolidated live review.
Scheduled Ohio four-output evidence remains outstanding. No new relevant mail,
deadline change or acceptance decision.

## October 4, 09:00 ET — native catalog and retailer integration

Returned from the payout sheet to the source screen and opened Scratch-Off
games and prizes. The official /games/scratch-offs/ page loaded its price-group
catalog and remaining-prizes route. Returning to the app and back to the Ohio
map retained the October 4 whole-day source-date view. The Scratch shortcut
shows the selected-release/publication-date/incomplete-claims disclosure and
remaining-top-prizes-not-store-stock limitation.

The native directory opens with 10642 locations. Searching ABERDEEN 1ST STOP
returns one match; its detail shows ABERDEEN 1ST STOP #54, 767 Us Highway 52,
Aberdeen, OH 45101, Brown County, and explicitly says a directory listing alone
does not create a heat-map win. App left on this detail for continuation.

GitHub's latest returned runs still end at successful push publisher37194646320;
no post-integration scheduled Ohio run is available in that response. Scheduled
four-output evidence remains unverified, not presumed failed. No relevant new
mail. Next publication detail/source, category/date/prize filters and native
failure/reconnect, then consolidated live acceptance. No deadline or release
decision change.

## October 4, 10:00 ET — native publication detail and source return

Changed the native timeline from October 4 to October 2, retaining whole-day
source-date wording. Returned from the directory retailer through city/county
to Ohio; the October 2 Licking heat point exposes one selected release. Its
Ultimate $5,000,000 detail shows PUBLICATION DATE October 2, $50,000 and
SAK'S CASCADE MARKET, 599 E Main St, Newark, OH 43055, with the explicit
publication-not-draw-or-claim-date and incomplete-statewide-count disclaimer.

The source link opens the loaded official Newark Lottery Player Wins $50,000
release dated October 2, 2026. It matches the retailer/address and gross prize;
the article separately states purchase on September 28 and $36,625 after tax.
The app correctly retains the publication date and gross $50,000 without
substituting the purchase date or after-tax amount. Returning to the app retains
the detail. No new relevant mail or native defect found.

Next category/date/prize filter reset and native failure/reconnect, then
consolidated automated/live acceptance. Scheduled run 37206460485 completed successfully, producing bot commit
881d054. Its status records Ohio updated across all four transaction outputs;
independently fetched public payout-report and refresh-status bytes match.
The scheduled integration checkpoint is closed. The bot commit was incorporated
by a clean rebase before pushing these notes. Deadlines and not-accepted status
are unchanged.

## October 4, 11:00 ET — native category and prize reset

On October 2 in Licking, selected Terminal Instant Games in the native filter
and applied it: the Scratch release disappeared and the scoped-empty message
appeared. The distinct Game Show Prizes choice is also visible. Resetting to
All Games restores the Newark Ultimate $5,000,000 selected release, one reported
ticket and $50K. Raising the minimum prize to the displayed $19.1M (maximum
$60M) again produces the scoped-empty state; dragging the minimum back to the
full-range endpoint and applying restores the same release. October 2 and
whole-day source-date wording remain intact throughout.

Filter-sheet AX stays stale while visual controls update; mouse interaction
and resulting map AX verify behavior. This does not certify accessibility.
No code changes, relevant new mail or deadline change. App left on the restored
Licking October 2 map. Next native request-failure/reconnect and consolidated
automated/live review; Ohio is not accepted yet.

## October 4, 12:00 ET — native request failure and reconnect

A private Dart HttpOverrides probe directs HTTP requests to an unavailable
loopback proxy while a local flag exists. With the flag present, the native
Ohio payout sheet retains Pick 3 October 3 Evening draw 23904, $362706.00,
unavailable counts and retrieval 2026-10-04T07:13:35.742Z. Limitations remain
visible. Removing the flag and reopening the sheet advances retrieval to
2026-10-04T13:48:54.384Z, matching an independently downloaded ten-report
public feed; the draw, dollars and unavailable-count semantics remain intact.

This verifies Dart request failure and recovery, not OS-wide offline behavior
or map-tile availability. Probe source and live evidence are private under
work/ohio_native. No relevant new mail or deadline change. Final consolidated
automated/live review and release decision remain; Ohio is not accepted yet.

The ordinary lib/main.dart macOS debug build passed and was relaunched after
closing the probe. No probe is left active.
