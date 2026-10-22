# Idaho supported coverage acceptance

Status: **ACTIVE — not accepted**. Sole active state from October 22, 2026
at 14:22 ET, after Iowa acceptance.

- Full supported scope and all product gaps due October 23 at 14:22 ET.
- Supported release decision due October 27 at 14:22 ET.
- Fresh 120 elapsed hours for substantial all-game collection/app integration.
- Extensions used: none. Finish early when evidence passes.

## Selection and opening evidence

Reviewed Idaho and Oklahoma source screens and existing collectors. Idaho has
an existing strict Scratch importer and a separate dated Idaho Cash API audit.
Those foundations reduce initial uncertainty but do not establish full draw
coverage or current native acceptance. The single-game audit is not a complete
working all-game import, so the substantial-implementation window applies.
No other state is activated; accepted states remain closed.

Fresh October 22 captures from the [official site](https://www.idaholottery.com)
and linked product pages are retained privately in work/idaho_scope with hashes
and retrieval timestamps. The navigation identifies eight draw families:
Powerball, Powerball Xs & Os, Mega Millions, Lotto America, Millionaire For Life,
Idaho Cash, Pick 3 and Pick 4. Scratch, InstaPlay, Tab games and the current
Raffle need separate dispositions. Two Xs & Os links returned identical bytes;
they must not become two games. These are opening observations, not closed scope.

Initial table inspection distinguishes Idaho and national winner tables. Pick 3
has Day/Night columns and leading-zero-sensitive digits. Powerball has Double
Play results and separate report columns; its Idaho table labels Powerplay and
Double Play, so a base-game count must not be invented. Mega Millions has five
per-play multiplier columns; do not assign a shared draw multiplier. Idaho Cash
free-ticket prizes remain categorical; published winner counts do not establish
distinct tickets or people. Next estimated jackpots and historical drawing
jackpots are separate fields. All match-image meanings, schedules, qualifiers,
report units, session/date joins and API routes still require validation.

The September retailer audit is not current address verification. No coordinates,
retailer-win joins, complete statewide counts or agency records are promoted.
The October14 unsigned nonresident form remains a separate correspondence item;
missing records do not block honest supported completion.

## Release gates

- [ ] Reconcile every current product, variant, session, history limit and gap.
- [ ] Validate actual dated source routes, count units and literal schedules.
- [ ] Strict bounded collection with atomic correction/failure retention.
- [ ] Fresh Scratch and separate instant-product dispositions.
- [ ] Remote/cache/bundle presentation with actual dates and limitations.
- [ ] Native selections, sources, full schedules, layouts and enlarged text.
- [ ] Inventory search/filter/detail returns and persistence/recovery.
- [ ] Ordinary build restoration, tests and independent live verification.
- [ ] Integrated supported acceptance and explicit unavailable features.

No public feed, app build, UI change or acceptance is claimed by activation.


## October 22, 15:31 ET — dated API and source-contract audit

Captured the site's three linked bundled JavaScript files and eight dated
API requests privately, with URL/hash/retrieval manifests in work/idaho_scope.
The date-picker script constructs `/api/v1/drawgame/{page-slug}/{date}`.
Seven requests returned dated game JSON; Millionaire For Life's October21
request returned HTTP404. Its visible HTML still contains results, schedules
and report tables, so this is an API-route limitation, not proof the game or
its reports are absent. Use verified HTML as a candidate source; do not invent
an alternate endpoint or carry a different game's data into it. The shared
check-number form defaults to Powerball on other game pages; exclude that form
from game-specific result parsing.

Observed API contracts and unresolved issues:

- Pick3 `winning_numbers`/`winners` and `_2` arrays correspond to the visible
  Day/Night columns. Source strings include trailing carriage returns; trim only
  explicitly allowed surrounding whitespace and preserve each digit, including
  Pick4 Night's leading zero. Pick3 has twelve API report entries, including
  three Sum It Up stakes, while the visible main table has nine rows.
- Pick4 API labels repeat Any Order 4 Way, Front Pair and $5 Sum It Up, with
  missing/distorted exact-any identities. These must not be repaired by position
  or converted into invented zero counts. Bound the display to unambiguous
  reviewed source rows or explicitly exclude ambiguous report coverage.
- Powerball Idaho `winners` contains nine base entries of zero plus eight Power
  Play entries. The site's own script filters only Power Play for the Idaho
  table. Do not publish the undisplayed base zeros as verified Idaho reports.
  Double Play has a separate result array and nine report entries.
- Mega Millions has41 labeled report entries: one jackpot plus eight rows for
  each of five per-play multipliers. The script inserts N/A jackpot cells in
  later multiplier columns; those inserted cells are not source zero counts.
- Lotto America separates nine base and eight All Star Bonus rows. Idaho and
  national arrays are distinct. Idaho Cash retains four categorical tiers,
  including Free Ticket; XsOs has eight numeric source team codes and five
  match-count rows. Team code-to-image mapping is still unverified.
- Powerball October21 API jackpot is635000000 while the visible past-draw row
  says638.6 million. Its API cash matches the page's next-estimate cash amount.
  Other fields also need date/provenance validation. Do not attach cash/next
  estimates to historical results or silently choose a conflicting amount.

The current Raffle page states sales began October21 and a December29 winner
announcement, with a separate daily promotion already showing a six-digit
number. The two-million-dollar-prize row's printed odds and the stated ticket
limit require explicit source-qualification review; never recalculate or correct
published odds silently. Separate final-draw status from promotional results.
InstaPlay and Tabs remain separate product scope, not Scratch aliases.

Next close all product dispositions and schedules, including image match labels,
Sum It Up, Raffle promotional/final distinction, InstaPlay/Tab inventory semantics,
and bounded history. Then implement strict parsers and atomic retention against
these reviewed contracts. No new public feed, app build, UI or acceptance; scope
and release deadlines remain October23/October27 at14:22ET, no extension.


## October 22, 16:29 ET — other products and image schedule scope

Captured all12 listed InstaPlay and11 listed Tab detail routes privately.
These are catalog observations, not remaining-prize inventories. InstaPlay tables
say Number of Prizes / Prize Amount / Odds; several progressive rows have $0
placeholders and $10 Cash Spot has all-zero prize amounts. Do not treat those
as zero-dollar prizes or remaining counts. Nine Tab pages are TouchTab wager/
top-prize/overall-odds tables; two are fixed prize schedules. Fractional wager
and prize values must survive. No remaining-count field is established for either
product type. Opening Scratch listing has32 cards; its existing strict detail
and claim-date validation must still run before a new accepted snapshot.

Visually reviewed the two official Sum It Up images and transcribed their literal
rows into tooling/idaho_sum_specs.json with exact image hashes: Pick3 has14 paired
sum rows; Pick4 has37 sum rows and explicitly labels a $1 wager. Pick3's image
itself lacks that heading, so its basis must be joined only to verified page text.
The pages prohibit this option for pair wagers (front/back for Pick3; front/mid/
back for Pick4). These are schedules, not actual winner counts. The specs are
reviewed inputs, not yet wired to a collector or app.

Planned bounded scope is now explicit: two available dated results for each of
11 groups across8 families (Powerball and Double Play separate; Pick3/Pick4 Day
and Night separate), literal main/option schedules and exact-date Idaho reports
where unambiguous. Missing/ambiguous report rows remain unavailable; specifically
exclude undisplayed Powerball base counts and unresolved Pick4 counts. Exclude
conflicting historical jackpot/cash values rather than choosing a value. Use
MFL HTML pending a proven dated route and preserve XsOs literal numeric source
codes plus official images without invented expanded team names.

Scratch remains a separate validated remaining-prize catalog with lower-tier
unknowns. InstaPlay/Tab receive separate catalog/rule/schedule presentation with
explicitly unavailable remaining counts and progressive placeholders; no false
Scratch inventory semantics. Raffle receives its source-labeled schedule and
separately dated daily promotion, with final drawing pending and printed odds
qualifications retained. History is the bounded presented window, not ten years.
Retailer lookup, claims/help, VIP and historical-game routes are source links,
not retailer joins, claims datasets or new account interactions.

The full-scope gate remains open for final rule/option and history reconciliation;
remaining work is concrete, including strict schedule contracts and product-field
validation. No feed/build/UI/acceptance or deadline change. Next implement the
bounded draw parser and hash-gated schedule contracts after final reconciliation.
