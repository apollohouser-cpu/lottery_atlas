# Colorado supported-coverage acceptance

Activated October 4, 2026 at 14:15 ET as the sole active state after Ohio
acceptance. Three working imports qualify for 72 hours: release decision due
**October 7, 2026 at 14:15 ET**; full national/state draw and Scratch scope/gap
reconciliation due **October 5 at 14:15 ET**. Not accepted.

## Selection and opening evidence

Colorado follows Ohio on working-import readiness; no newer user priority is
recorded. Scheduled refresh status reports its catalog, directory and winner
transaction updated. Existing exact-address joins and historical retention
provide a working starting point; missing broader records are not a release
prerequisite. Accepted states remain closed.

- 90 official Scratch games.
- 3047 mapped official retailers, two unresolved entries kept separate.
- 1164 selected retailer-matched report rows: 780 Scratch, 247 other draw,
  113 Mega Millions and 24 Powerball. Latest report date October 2.
- 6905 unmatched/excluded rows; no inferred locations or zero-win assertion.
- 254 older Scratch rows retain their original historical snapshot evidence.
  Current 180-day Scratch window begins April 7, 2026.
- Six report pagination/history tests and five generated-data Flutter tests
  pass at opening. These are not native or full acceptance checks.

## Named opening accuracy audit

Every retained activity timestamp ends T12:00:00.000Z. The importer constructs
noon UTC from a date-only report column; noon is not verified event time.
Next inspect detail/timeline date labeling and constrain Colorado to whole-day
source dates without changing source dates, IDs or historical provenance.
Do not assume report date means draw, claim or publication date before official
definition evidence. Each row currently supplies winningTickets=1; reconcile
reported winner-row units before claiming distinct tickets or complete totals.

Current non-Scratch names include Powerball, Mega Millions, Powerball Double
Play, Colorado Lotto+, Plus, Cash 5, Pick 3, Millionaire for Life and historical
Lucky for Life. Reconcile all current national/state games and Scratch against
official sources, including add-ons and historical routes. The importer also
queries second-chance, contest and Cash 5 EZ Match reports; no current matched
rows for those queries establishes neither absence nor a recurring draw scope.
Inspect actual per-game prize reports and units, preserve literal annual prizes,
and disclose unsupported counts. No broad claims-map expansion is authorized
without definitions and exact source joins.

## Acceptance gates

- [x] Full game scope and source/gap matrix within 24 hours (October 4, 18:00 ET).
- [ ] Date/category/count/title semantics and retained-data preservation.
- [ ] Supported report/source integration and atomic refresh/cache behavior.
- [ ] Native compact/wide catalog, directory, detail/source and filters/reset.
- [ ] Native request-failure/reconnect with accurate limitations.
- [ ] Focused tests, ordinary build and independent live-feed validation.
- [ ] Consolidated release decision by October 7 at 14:15 ET.

No new relevant mail at activation. Existing source-screen history remains the
authority for separate agency/data outcomes. No fee or attestation requested.

## October 4, 15:00 ET — conservative date precision correction

Colorado now opts into whole-day timeline selection and Source dates wording.
Its winner detail labels SOURCE DATE and explains that draw/claim/publication
semantics and event time are unverified. Selected rows and retained historical
snapshots are explicitly not complete statewide ticket counts. This removes
the implied draw date and event-hour interpretation of synthetic noon UTC.

Only UI code changed: all generated rows, IDs, dates, counts, coordinates and
historical timestamps remain untouched. Changed-file analysis is clean; four
existing timeline tests pass. Native verification is pending with the ordinary
build. Next reconcile official report-date/count semantics and full national/
state/Scratch game scope by October 5 at 14:15 ET. No new relevant mail, deadline
change or acceptance decision.

## October 4, 16:00 ET — actual draw reports and units reconciled

Official dated HTML reports were captured privately in
`work/colorado_acceptance/`. Six current report families expose actual prize
results; these are separate from the selected retailer-matched winner rows.
No reports or counts have yet been promoted into app data.

| Official dated report | Verified structure / integration constraint |
| --- | --- |
| [Powerball](https://www.coloradolottery.com/en/games/powerball/drawings/2026-10-03/) | Nine Colorado base tiers, eight Power Play tiers, nine Double Play tiers. Preserve variants separately and omit the out-of-state jackpot table. |
| [Mega Millions](https://www.coloradolottery.com/en/games/megamillions/drawings/2026-10-02/) | Colorado jackpot plus eight tiers across five built-in multipliers. Published prizes already incorporate the multiplier. Exclude out-of-state winners. |
| [Millionaire for Life](https://www.coloradolottery.com/en/games/millionaireforlife/drawings/2026-10-03/) | Nine Colorado tiers; preserve $1 million / $100,000 annual-for-life wording and prize-sharing footnotes, not invented cash equivalents. |
| [Lotto+](https://www.coloradolottery.com/en/games/lotto/drawings/2026-10-03/) | Thirteen base and thirteen Plus rows, including multiplier-specific tiers. Keep Plus distinct; published jackpot and cash value are separate fields. |
| [Cash 5](https://www.coloradolottery.com/en/games/cash5/drawings/2026-10-03/) | Four tiers. EZ Match separately reports 1,105 players and $3,295 for the 04:30–23:59 period on the draw date; neither is a Cash 5 tier count. |
| [Pick 3 Midday](https://www.coloradolottery.com/en/games/pick3/drawings/2026-10-03:MD/) / [Evening](https://www.coloradolottery.com/en/games/pick3/drawings/2026-10-03:EV/) | Six bet types and four wager columns with prize/count pairs; unavailable half-dollar combination cells are bullets, not zero. Any-order prizes vary with the drawn number pattern. Preserve session, bet type and wager identity. |

Use the source's reported-winner unit, without asserting distinct tickets or
summing overlapping wager/variant categories. These dated drawing pages verify
draw dates for these reports only. The [Who's Winning report](https://www.coloradolottery.com/en/player-tools/whos-winning/)
labels its column Date Won and its filter drawing date range; that does not
resolve draw/claim/publication semantics for every imported winner row. Retain
the conservative SOURCE DATE treatment and synthetic-time limitation.

[Bonus Draws](https://www.coloradolottery.com/en/games/bonus-draws/) covers Scratch
and jackpot promotions, and links to a separately filtered winner report; it
says posting can lag 5–12 days. The [monthly second-chance promotion](https://www.coloradolottery.com/en/news/monthly-second-chance/)
is current, with a monthly $100,000 prize and restricted ticket eligibility.
Keep promotional results separate from ordinary Scratch/draw results; no
entries, account creation or eligibility attestation were performed. The old
`/en/games/luckyforlife/` route redirects to the games index, so it is not a
verified historical result route.

Next implement strict HTML report parsing and reconcile the remaining
historical/free-play routes to close the full scope matrix. No broad search
needed for the six verified current families. No new relevant mail, deadline
change or acceptance decision; native date correction remains pending.

## October 4, 17:00 ET — first strict draw parsers

Added `tooling/colorado_draw_reports.mjs` for Cash 5 and Lotto+/Plus. Captured
October 3 official pages parse privately into four Cash 5 tiers and 26 Lotto+
base/Plus tiers. EZ Match remains a separate 1,105-player / $3,295 observation
with the source's 04:30–23:59 reporting period. Literal tier prizes are preserved,
not multiplied again. No distinct-ticket total or retailer allocation is inferred.

Validation binds official host/path, game heading and calendar date; enforces
exact table headers, ordered unique tiers, nonnegative integer counts and dollar
prize labels; and requires the dated EZ Match period. Three tests pass, including
malformed count, tier loss/duplication, wrong date/jurisdiction/header and altered
period rejection. Outputs remain private and are not yet imported or navigable.
Next add the remaining four families and close historical/free-play scope routes.
No relevant new mail or deadline change; Colorado remains unaccepted.

## October 4, 18:00 ET — full scope closed; implementation continues

Full national/state/Scratch scope and gaps are now fixed ahead of the October 5
14:15 checkpoint. This is scope closure, not release acceptance.

| Product | Required supported experience | Explicit gap / boundary |
| --- | --- | --- |
| Powerball, Power Play, Double Play | Separate Colorado tier tables and official dated source | No out-of-state totals or retailer allocation |
| Mega Millions | Colorado jackpot and multiplier-specific tiers | No second multiplication or distinct-ticket aggregate |
| Millionaire for Life | Nine Colorado tiers with annual prize/sharing text | No inferred cash equivalent |
| Lotto+ and Plus | Separate base/Plus multiplier tiers | No merged variant totals |
| Cash 5 and EZ Match | Four draw tiers; separate EZ Match players/dollars/period | Instant add-on observation is not a draw tier or ticket count |
| Pick 3 Midday/Evening | Session, bet and wager-specific prize/count cells | Unavailable wager cells stay unavailable; no deduplication inference |
| Scratch | Existing 90-game catalog, official catalog route and selected mapped winner rows | Not store stock or complete claims; 254 historical rows retain provenance |
| Bonus Draws / monthly second chance / contests | Official promotional and winner-report routes | Separate promotions; no fabricated recurring tier feed or eligibility attestation |
| Historical Lucky for Life | Existing selected historical rows and official history route | Not a current recurring import or proof of zero historical winners |
| Free Play Zone | Official route with digital-game context | Not Scratch inventory or a monetary-winner data feed |

The [Lucky for Life history index](https://www.coloradolottery.com/en/games/luckyforlife/drawings/)
responds successfully without redirect, unlike its old product page. Preserve
this history navigation even when its current month has no results. No claim is
made that a historical tier archive has been fully imported. The [Free Play Zone](https://www.coloradolottery.com/en/games/play-free-digital-games/)
describes free digital games; legacy Lucky for Life promotional wording there
must not override the current game roster. Both pages are captured privately.

Millionaire for Life parsing now preserves nine literal tier prizes and both
sharing notes, rejecting missing notes, cash substitutions and wrong jurisdiction
headers. Four parser tests pass; the captured October 3 report parses privately.
Cash 5/Lotto+/MFL now have private parsed reports; Powerball, Mega Millions and
Pick 3 parsers remain next, followed by atomic import/cache/UI/source integration,
native checks and consolidated release evidence. No reports promoted this turn.
No relevant new mail or deadline change; Colorado remains the sole active state.

## October 4, 19:00 ET — Pick 3 wager/session parser

Both captured October 3 sessions now parse privately. Each preserves 24 wager
cells across six bet types: 22 published prize/count pairs and two unavailable
half-dollar combination cells. Unavailable cells keep null count/prize and an
explicit availability flag; published zero counts remain zero. Wager amount,
bet identity, session and literal prize are retained without aggregating winners.

Six parser tests pass, including session/column mismatch, missing pair content,
negative counts, duplicate bet types and unavailable-to-zero corruption. These
join private Cash 5, Lotto+/Plus and MFL reports. Powerball and Mega Millions are
next, then all-source continuity/import, cache/UI integration and native checks.
Scope remains closed, release deadline unchanged, and no reports promoted.
No relevant new mail; Colorado is not accepted.

## October 4, 20:00 ET — national report parsers complete

Powerball now validates nine base, eight Power Play and nine Double Play tiers,
including separate variant headings and the published Power Play multiplier.
Mega Millions validates its Colorado jackpot plus eight tiers at each of five
multipliers. Both exclude the explicitly headed out-of-state table; unknown
additional tables fail validation. Literal prizes are never multiplied again.

Ten parser tests pass, including wrong jurisdiction/variant headings, duplicate
or missing tiers, invalid/missing Power Play multiplier and malformed counts.
Captured Powerball October 3 and Mega Millions October 2 parse privately into
26 and 41 tiers respectively. All six current report families now have parsers
and seven captured reports (both Pick 3 sessions). No public or app report feed
has been added. Next live all-source import with continuity/atomic replacement,
then bundle/cache/UI/refresh integration and native acceptance. No new mail,
deadline change or acceptance decision.

## October 4, 21:00 ET — live atomic report importer

`import_colorado_draw_reports.mjs` now discovers dated official history links,
validates every selected page and stages 12 live reports privately: two per
family, with the newest Midday and Evening for Pick 3. Previous-draw navigation
and bounded previous-month fallback handle short current-month indexes. Failed
or malformed pages fail the refresh rather than becoming zero results.

All six families and both Pick 3 sessions are required; duplicate identities,
duplicate game/session/date slots and per-session date regression are rejected.
Only a completely validated result replaces the prior file atomically. Twelve
parser/import tests pass, including failure of each of the six sources, malformed
late-source content and regression preserving exact prior bytes. Public drawing
markup fixtures contain tier data, not private winner records.

Live private import succeeded with 12 reports. Next bundle/cache/report UI,
official scope routes and four-output refresh/publication integration, then native
acceptance. No public reports promoted, new relevant mail, deadline change or
acceptance decision.

## October 4, 22:00 ET — bundled reports and validated loader

Added the 12-report validated snapshot as a Flutter asset and a Colorado
remote/cache/bundle loader. It preserves literal prizes, variants, annual sharing
notes, Pick 3 unavailable cells and separate EZ Match units. The loader requires
all six families, both Pick 3 sessions, exact dated official routes, unique
report/tier identities, expected tier counts and valid dates/counts. Regressing
remote session dates or malformed content cannot replace a valid cache.

Four focused loader tests pass: exact remote data survives cache-write failure,
request failure preserves cached data, corrupt cache uses the bundle, and invalid
scope/units/tables/dates/annual notes cannot overwrite retained data. Changed-file
analysis is clean after correcting one brace-style notice. No report navigation
or public endpoint yet. Next report sheet and official scope routes, then refresh/
publication transaction and native acceptance. No new relevant mail or deadline
change; Colorado is not accepted.

## October 4, 23:00 ET — navigable report sheet

The Colorado state source screen now opens its 12-report selector. Cards keep
variant, bet/wager, literal prize and reported-winner count together; unavailable
Pick 3 wagers remain explicit. Annual sharing notes, the Power Play multiplier,
separate EZ Match players/dollars/period, retrieval timestamp and limitations
are displayed. Each report opens its dated official source. Footer routes cover
Scratch, Bonus Draws, monthly second chance, historical Lucky for Life and Free
Play Zone without merging those products into draw counts.

Compact (400×640) and wide (1280×900) widget tests exercise all 12 report selections
and scrolling to the final source route without exceptions. Changed-file analysis
is clean. The ordinary macOS debug build passes; it has not yet been relaunched
for native verification. Next four-output refresh/publication integration and
endpoint verification, then integrated native acceptance. No new relevant mail,
deadline change or acceptance decision.

## October 5, 00:00 ET — four-output refresh/publication integration

Colorado's scheduled state transaction now owns catalog, directory, selected
winner rows and draw reports together. Publication copies the validated report
asset to `docs/colorado_draw_reports.json` and includes both report files in the
workflow's change detection and commit list. The staged endpoint contains the
12-report bundled snapshot with its original retrieval/source dates.

Seven transaction tests pass. The Colorado-specific case injects failure at each
of the four configured import commands and verifies exact restoration of every
baseline output, including dates. These simulated failures are validation
evidence, not production source failures. No existing state transaction changed.

Next verify deployment/endpoint bytes, then relaunch the ordinary build for native
integrated acceptance. A successful push publication does not prove Colorado's
scheduled four-output refresh; that checkpoint remains unverified until a scheduled
run completes. No relevant new mail, deadline change or acceptance decision.

## October 5, 01:00 ET — public endpoint and native opening flow

Push publisher 37263078978 for 1dccd42 succeeded. Independent HTTP retrieval of
`colorado_draw_reports.json` exactly matches staged bytes and contains 12 reports.
This verifies publication, not the still-unverified scheduled four-output refresh.

Relaunched the ordinary macOS build and navigated Find a State → Colorado →
CO LOTTERY → draw reports. Colorado map shows whole-day Source dates and a
scoped October 5 empty view. Powerball October 3 displays the verified Colorado
base rows, Power Play multiplier 2 and separate Power Play/Double Play sections.
Scrolling reaches the no-aggregate/no-retailer-allocation limitations, original
retrieval 2026-10-05T01:18:46.563Z, refresh cadence and all five additional product
routes. Private native evidence is in `work/colorado_native/`.

Next remaining report selections, source open/return, compact/wide integrated
checks, catalog/directory/winner detail/filter/reset and request-failure/reconnect.
Do not repeat the completed opening route. No relevant new mail, deadline change
or acceptance decision. Initial AX content was empty until mouse interaction;
this is not an accessibility certification.

## October 5, 02:00 ET — native national selections/source return

Mega Millions October 2 selected natively with Colorado jackpot zero, separate
2x tier labels, literal prizes and reported-winner counts (including 2, 48, 40,
390 and 1,025 on the visible lower 2x tiers). Millionaire for Life October 3
selected with both annual-for-life top prizes, nine tiers and both sharing notes.
Its official source opens the loaded dated Colorado page with matching tiers;
returning to the app preserves the MFL selection, scroll position and footer.
Private AX evidence is retained in `work/colorado_native/`.

Next Lotto+/Plus, Cash 5/EZ Match and both Pick 3 sessions, then remaining wide/
map/catalog/directory/detail/filter and request-failure checks. Completed Powerball
opening and MFL source-return flows do not need repetition. No relevant new mail,
deadline change or acceptance decision; scheduled refresh remains unverified.

## October 5, 03:00 ET — native remaining report families

Lotto+ October 3 selected natively with separate base and Plus rows, literal
multiplier-tier prizes and reported winners. Cash 5 October 3 displays its four
tiers and the separate EZ Match 1,105 players / $3,295 payout for the stated
4:30 AM–11:59 PM period. Pick 3 October 4 Midday and October 3 Evening each
retain their own dates, wager amounts, prizes and counts. Midday combination
half-dollar cells explicitly show unavailable wagers/counts rather than zero.
Private AX captures are retained in `work/colorado_native/`.

All six report families have now been selected natively; completed selections
and source-return flows do not need repetition. Next native wide view and map
catalog/directory/winner detail/date-game-prize resets, request failure/reconnect,
then consolidated acceptance. App remains on Pick 3 Evening. No relevant new
mail, deadline change or acceptance decision; scheduled refresh remains unverified.

### Scheduled refresh failure discovered at this checkpoint

Scheduled run 37273805668 completed globally successfully, but bot commit a8c1079
records Colorado `retained_after_failure` for the four-output transaction. All
four Colorado source files are byte-identical to the preceding commit; no source
or retrieval dates advanced. This is a Colorado refresh failure, not successful
scheduled integration. Public Actions logs retrieval returned HTTP 403, so the
failing importer and cause are not yet established. Next inspect authenticated
logs if available or reproduce the configured commands against private baseline
copies; keep validation intact and do not promote partial probes. Native work
can continue independently. Deadline remains October 7, 14:15 ET.

## October 5, 04:00 ET — bounded refresh reproduction and parser repair

All four configured importers were run against private copies of their retained
baselines. Catalog (90 games), directory (3,047 mapped retailers) and selected
winners (1,164 rows, 6,899 exclusions) succeeded. Draw reports failed with
`Unexpected Colorado table count`. Per-family capture isolates the live October 4
Millionaire for Life page: its second table is explicitly Out-of-State Jackpot
Winners (one Wyoming second-prize winner). The parser now excludes that explicitly
labelled optional table, as already done for Mega Millions. The nine Colorado
tiers and annual sharing notes remain strictly validated. Twelve parser/import
tests pass, including rejection of an unknown second table or third table; the
captured live MFL page parses nine Colorado rows without the Wyoming winner.

The same bounded probe found a separate incomplete October 4 Cash 5 source:
its four draw tiers are present, but EZ Match players, payout and period are
absent. Existing validation continues to reject it. This is not evidence of zero
EZ Match activity. No private outputs were promoted; the retained draw-report
file is byte-identical after the failed import. The scheduled run's exact failing
command remains unavailable from its logs; these are reproduced live causes,
not a claim that both occurred in that run.

Next check the missing Cash 5 section in a bounded follow-up and verify the next
scheduled complete transaction; preserve prior data until a complete validated
replacement. Continue pending native wide/map/detail/filter/failure checks.
No new relevant mail, deadline change or acceptance decision.
