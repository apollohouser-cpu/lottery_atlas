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
