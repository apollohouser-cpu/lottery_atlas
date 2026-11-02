# Arizona source screen — September 13, 2026

Arizona is not ready for a complete verified winning-ticket total or
retailer heat map. Its [official draw-game page](https://www.arizonalottery.com/draw-games/)
and [Scratcher catalog](https://www.arizonalottery.com/scratchers/) provide
game information. Individual Scratcher pages list prize tiers and prizes
remaining, but those are outstanding prizes rather than a count of tickets
won in a selected period. The [winner gallery](https://www.arizonalottery.com/winners)
is a selection of stories, not a complete record of winning tickets.

The [Where to Play locator](https://www.arizonalottery.com/where-to-play)
supports location search; this screen did not verify a statewide current
retailer export with stable identifiers and coordinates or a complete
retailer-linked winning-ticket feed. Do not infer full coverage from a locator
or use remaining prizes as claimed winners.

The [Lottery contact page](https://www.arizonalottery.com/contact-us)
links to a public-records portal. Its [instructions](https://feedback.arizonalottery.com/recordsrequest/instructions.aspx)
require a commercial/noncommercial-use attestation under penalty of perjury.
No attestation or request has been submitted. Determine the appropriate use
classification and a supported contact route before sending a formal request;
continue screening other states in the meantime.

September 20 source-access check: a direct local HTTPS fetch of the official
Scratchers page returned HTTP 403. The browser-search reader could access the
page, but several listing cards exposed a blank top-prize amount; details would
need independent validation. No automated Arizona import was enabled and no
records-use attestation was made. Continue with accessible official sources
while preserving this limitation.

## November 1 — active scope opening

Arizona activated at09:15EST with scope due November2 at09:15EST and supported
release due November6 at09:15EST. See ARIZONA_ACCEPTANCE.md. Direct draw-game
and Scratchers requests again returned403; private failed-response manifests are
retained. Web-reader access supports initial product discovery only, not recovered
production transport. No formal attestation, fees, new correspondence or feed.

### November 1 Quick Draw review

The eight linked game pages now have a product-by-product discovery matrix in
[ARIZONA_ACCEPTANCE.md](ARIZONA_ACCEPTANCE.md#november-1-quick-draw-source-screen).
Critical boundaries are hourly Draw ID/time identity, Lucky Links' distinct daily
schedule, ordered digit/dice results, and wager-unit reports ($2 for Pick Your Bet,
$1 on several other pages). These are not accepted person/ticket counts. Reader
result cells remain blank; no production transport recovery or source collection
is claimed. Scope closure and existing deadlines remain unchanged.

### November 1 supported scope fixed

Full supported scope was fixed at16:22EST, before the November2 09:15EST scope
deadline. See ARIZONA_ACCEPTANCE.md#fixed-supported-scope--november-1-at-1622-est
for every reviewed product, nineteen result-identity targets and explicit gaps.
Capture/parsers, publication and native acceptance remain open. Release remains
November6 at09:15EST; no extension, feed or acceptance is claimed.

## November 1 Powerball DOM evidence parser

Retained structured, populated browser DOM tables from the official Powerball
page, with acquisition timestamp, in private work/arizona_scope and an observed
fixture. The two tables share an HTML ID; exact column headers distinguish
Powerball from Double Play without relying on table order. The strict parser
validates 77 Powerball and 60 Double Play date-only rows, including the latest
October 31 and October 28 results. These are observed rows, not the full Arizona
scope target or complete historical coverage. Nested prize details are retained
as source evidence but no counts/reports are promoted: geography and units remain
unverified. No draw timestamps are fabricated.

Twelve focused Python tests pass across draw and catalog navigation parsers,
including blank templates, invalid ranges, duplicate/out-of-order dates, cadence,
changed table structure, source provenance and table-order independence. Browser
DOM access is not direct HTTP recovery or a scheduled collector. Remaining game,
rule/detail, refresh continuity, coupled publication, app and native gates remain
open; no Arizona feed/build/acceptance. November 6 09:15 EST release is unchanged.

## November 1 Fantasy 5 structured evidence

Captured the populated official Fantasy 5 result table through ordinary browser
DOM observation and retained timestamped evidence privately plus a source fixture.
Strict parsing validates 179 consecutive date-only rows, latest October31/30;
blank templates, missing daily rows, duplicate numbers, out-of-range values and
changed source/table structure fail closed. Nested prize details are retained but
not promoted to counts or reports; instant EXTRA is not a separate draw result.
Twenty-two focused Arizona parser tests pass. This is parser development, not
HTTP transport recovery, a scheduled collector, new public feed or acceptance.
Other game/rule/detail capture and publication/native gates remain open. Arizona
remains sole active with unchanged November6 09:15EST release deadline.

## November 1 Triple Twist structured evidence

Captured 180 populated daily Triple Twist rows from the official browser DOM,
latest November1 and October31. Added explicit six-of-42 validation using a shared
daily-lotto parser with Fantasy5's separate five-of-41/source contract. The three
rows on a purchased ticket are not three drawings. The latest source detail row
contains zeros; these are not promoted to verified zero winners or counts.
All report statuses remain unavailable pending semantics/timing validation.

Twenty-six focused Arizona parser tests pass, including cross-game source rejection,
exact number cardinality/ranges and missing daily results. Retained capture is
DOM evidence, not HTTP recovery or scheduled collection. No public feed, app build
or acceptance; remaining capture/rules/publication/native gates and November6
09:15EST release deadline are unchanged.

## November 1 Mega Millions structured evidence

Retained populated official browser DOM results: 51 date-only draws, latest
October30 and October27. Strict current-format parser validates five distinct
white balls 1–70, Mega Ball 1–24, Tuesday/Friday continuity, acquisition timezone,
source and exact table structure. Prior-format dates are rejected rather than
silently assigned current rules. No global draw multiplier is invented; per-play
multipliers belong to the separate rule contract. Nested counts remain source
evidence only; reports are unavailable until semantics are validated.

Thirty focused Arizona parser tests pass. No HTTP transport recovery, scheduled
collector, public feed, app build or acceptance is claimed. Remaining game/rule/
detail capture, publication and native gates stay open; November6 09:15EST release
remains unchanged.

## November 2 The Pick current-format evidence

Retained 60 populated official DOM draw rows from June15 through October31, with
latest October31/28. The single-pool parser now validates The Pick's distinct
six-of-40 contract, Monday/Wednesday/Saturday continuity and June14 format boundary.
Prior-format rows fail closed; no built-in per-play multiplier or instant Plus
result is invented from this date/number table. Reports remain unavailable.
Thirty-six focused Arizona tests pass, including The Pick overlap/correction gates,
range/cadence and prior-format rejection. No scheduled transport recovery, feed,
app build or acceptance. Remaining capture/rules/publication/native gates and
November6 09:15EST deadline remain unchanged.

## November 2 Pick 3 explicit sessions

Retained populated official DOM evidence containing 282 date/session rows: 141
Midday and 141 Evening, June14 through November1. Strict parser uses literal
session labels, preserves three ordered digits including zeros/repeats, and
rejects missing/duplicate/interleaved session gaps and prior-format dates. Latest
two per session remain a selection target; no invented clock times or payout
counts are produced. Source prize-count prose points to next-day PDF availability;
DOM detail values remain unpromoted, reports unavailable. Forty focused Arizona
tests pass. No HTTP recovery, feed, app build or acceptance; remaining capture,
rule/detail, publication/native gates and November6 09:15EST deadline unchanged.

## November 2 Pick 4 explicit sessions

Retained 282 populated Pick4 date/session rows: 141 Midday and 141 Evening,
June14 through November1. Extended digit-game validation with an explicit Pick4
source, four ordered digits, and separate detail-header contract including Mid
Pair. Leading zeros/repeats remain intact; session gaps, wrong widths, cross-game
sources and changed headers fail closed. Reports remain unavailable and source
counts are not promoted. Forty-two focused Arizona tests pass. No new public
feed/app build/acceptance or HTTP recovery. Remaining source/rule/detail captures,
coupled publication/native checks and November6 09:15EST release are unchanged.

## November 2 Xs & Os literal result evidence

Retained eight populated Sunday result rows, September13 through November1,
including exact abbreviation/image-alt/source-path joins. Strict parser preserves
eight distinct literal team labels per draw without expanding names or inferring
NFL game outcomes. Only 28 labels observed in these rows are currently admitted;
unseen labels fail closed for review, not guessed completion of the 32-team roster.
Weekly gaps and changed image joins fail validation. Reports remain unavailable,
including the latest zero-filled details; September13 pari-mutuel exception stays
explicit in scope. Forty-five focused Arizona tests pass. No feed/build/acceptance
or scheduled transport recovery; remaining rules/catalog/detail/QuickDraw capture,
publication/native gates and November6 09:15EST release remain unchanged.

## November 2 regular-result collection validation

Added an aggregate validator for all eight retained regular-game DOM captures,
covering eleven groups and selecting twenty-two date/session results. Each group
retains its source's actual retrieval time and DOM provenance; differing captures
are not relabeled as a fresh coupled collection. Every source passes its strict
parser before selection, and a missing source, changed header, swapped identity,
retrieval regression or overlapping result correction rejects the collection.
Fifty focused Arizona tests pass. All reports remain unavailable. This is an
internal validation step, not a public feed or atomic acquisition/publication.
Eight QuickDraw groups, rules, products and native gates remain outstanding;
November6 at09:15EST release deadline is unchanged, with no acceptance or build.

## November 2 One To Win hourly evidence

Retained the populated official November2 date-selected DOM table: three hourly
results with Draw IDs36268/36267/36266 at06:45/05:45/04:45 Arizona time, numbers
6/14/12 and literal base prize amounts$7/$7/$5. Strict parsing joins the selected
date with each printed time in America/Phoenix, rejects future/out-of-schedule
rows, ID/hour gaps and changed table contracts. Base amounts remain per-wager
source values, not actual payouts; the pari-mutuel limitation remains explicit.
The source labels its win units as based on$1 wagers, so none become ticket or
person counts and reports remain unavailable. Fifty-three focused Arizona tests
pass. This captures one QuickDraw family on one date, not complete daily/history
coverage or a new coupled collection. Seven other QuickDraw families, rules,
products, publication and native checks remain open; no feed/build/acceptance or
HTTP recovery is claimed. November6 09:15EST release deadline is unchanged.

## November 2 Two To Win hourly evidence

Retained five populated November2 hourly result/detail pairs, Draw IDs27646–27642
at08:20 through04:20 Arizona time. Latest observed ordered digits are61 and99,
with Super Bonus1x and2x. Strict parsing preserves leading zeros/repeated digits,
checks date/time/ID continuity and validates paired detail headers without
promoting the source's$1-wager-based win units into ticket/person counts. Reports
remain unavailable; base wager prizes and the pari-mutuel condition stay separate
from actual payouts. Fifty-six focused Arizona tests pass. This is one day's
bounded DOM evidence, not full history, raw HTTP recovery or coupled publication.
Six other QuickDraw families, rules/products and publication/native gates remain
open. No feed/build/acceptance; November6 09:15EST release deadline unchanged.

## November 2 5 In-A-Line hourly evidence

Retained six populated November2 result/detail pairs, Draw IDs33027–33022 at09:30
through04:30 Arizona time. Latest ordered digits64972/85271 carry Super Bonus1x/3x;
other observed rows preserve repeated digits and zeros. Extended the hourly digit
parser with a separate five-digit/source/minute/header contract, retaining the
Two To Win contract. Changed time, digit width, source identity, nested prize
headers and missing hourly pairs fail closed. Reports remain unavailable; source
detail numbers and the pari-mutuel prize condition do not establish ticket counts
or actual payouts. Fifty-nine focused Arizona tests pass. Five other QuickDraw
families, rules/products and publication/native gates remain open. No feed/build,
HTTP recovery or acceptance; November6 09:15EST release deadline unchanged.

## November 2 Money Roll hourly evidence

Retained six populated November2 hourly result/detail pairs, Draw IDs27652–27647
at09:50 through04:50 Arizona time. Parser preserves five literal ordered dice
labels, including repeats, rather than treating the draw as unordered numbers.
Latest labels are ONE/FIVE/FOUR/TWO/THREE with Super Bonus3x. Explicit source,
50-minute schedule, six-label vocabulary and nested prize-header contracts reject
invalid symbols, missing hours and changed structure. The source's$1-wager-based
win units remain unpromoted; reports are unavailable and pari-mutuel limitations
remain separate from actual payouts. Sixty-two focused Arizona tests pass.
Four other QuickDraw families, rules/products and publication/native gates remain
open. No public feed/build/acceptance or HTTP recovery; November6 09:15EST release
deadline unchanged. This is bounded dated DOM evidence, not complete history.

## November 2 Pick Your Bet hourly evidence

Retained eight populated November 2 result/detail pairs at 18:52:05.600 UTC,
Draw IDs 21069–21062, 11:40 through 04:40 Arizona time. Strict parsing preserves
literal two-digit numbers (including 07), Odd/Even and Low/High labels, and Super
Bonus. Category consistency, 1–38 range, hourly schedule, consecutive identities,
future-time rejection and exact nested prize headers are enforced. The latest
observed number is 35, Odd, High, with 2x Super Bonus. Source prize-detail units
are based on $2 wagers, not ticket or person counts; no counts or actual payouts
are promoted and reports remain unavailable. Sixty-five focused Arizona tests
pass, including contradictory-category and missing-hour rejection.

Three Quick Draw families still need strict result parsers; hourly refresh/day
boundary continuity, rules/products, coupled publication and native acceptance
remain open. No Arizona feed/build/acceptance or direct HTTP recovery is claimed.
The November 6 09:15 EST release deadline is unchanged.

## November 2 5/10/45 hourly evidence

Retained nine populated result/detail pairs for November 2 at 2026-11-02T19:50:27.982Z,
Draw IDs 36264–36256, 12:15 through 04:15 Arizona time. The strict parser validates
ten distinct numbers in 1–45, the separately labeled Bullseye belonging to that
set, hourly timing/identity continuity and exact nested prize-detail structure.
Latest observed numbers are 03/06/11/13/14/16/18/19/33/34, Bullseye 03, Super Bonus
2x. The allowed bonus contract includes 10x/12x/20x without truncating digits;
those values are covered by synthetic parser checks, not claimed observed here.
The source's $1 wager-based win units are not ticket/person counts and are not
promoted; reports remain unavailable. Base/Bullseye prize schedules and the
stated pari-mutuel limit are not actual payout reports.

Sixty-nine focused Arizona tests pass. Lucky Links and Hi-Lo still need strict
result parsers. Rules/products, hourly refresh across day boundaries, coupled
publication and native acceptance remain open. No feed/build/acceptance or HTTP
transport recovery is claimed; November 6 09:15 EST remains the release deadline.

## November 2 Lucky Links hourly evidence

Retained nine November 2 result/detail pairs at 2026-11-02T20:54:00.938Z,
Draw IDs 31404–31396, 13:00 through 05:00 Arizona time. Strict parsing requires
eight distinct numbers in 1–22, Super Bonus 1x–5x, consecutive hourly identities
and exact prize-detail headers. Lucky Links has nineteen scheduled daily draws,
05:00–23:00, unlike the twenty-draw families. Latest observed numbers are
03/06/10/12/13/14/17/20 with 2x Super Bonus. These are draw numbers, not positions
on a purchased 3x3 ticket; no ticket grid, lines won, counts or actual payouts
are inferred. All reports remain unavailable. The source's ticket grid and
pari-mutuel conditions remain rule information requiring separate presentation.

Seventy-two focused Arizona tests pass. Hi-Lo still needs a strict result parser;
hourly refresh/day-boundary continuity, rules/products, coupled publication and
native acceptance remain open. No Arizona feed/build/acceptance or direct HTTP
recovery is claimed. November 6 09:15 EST release deadline is unchanged.

## November 2 Hi-Lo hourly evidence

Retained eleven populated November 2 result/detail pairs at 2026-11-02T21:48:26.547Z,
Draw IDs 21082–21072, 14:10 through 04:10 Arizona time. Strict parser preserves
separately labeled high/low number totals, requires each in 0–20 and sum 20,
validates Super Bonus 1x–5x, hourly schedule/identity continuity, and exact nested
prize-detail headers. Latest observed information is Hi 9 / Lo 11, Super Bonus
1x. The underlying twenty drawn numbers are not provided by this result table
and are not invented. Category totals are not winner counts; source $1 wager
win units remain unpromoted and reports unavailable. The observed SEE MORE
footer is explicitly recognized, not interpreted as another draw. This is a
bounded DOM capture, not a claim of exhaustive history or pagination traversal.

Seventy-six focused Arizona tests pass. All eight Quick Draw families now have
initial strict result parsers on retained dated captures. This does not close
hourly refresh/day-boundary continuity, rules/products, coupled publication or
native acceptance. No Arizona feed/build/acceptance or HTTP recovery is claimed.
November 6 09:15 EST remains the unchanged supported-release deadline.
