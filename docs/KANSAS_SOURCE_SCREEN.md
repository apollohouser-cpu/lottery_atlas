# Kansas source screen — September 16, 2026

The Kansas Lottery's [instant-game pages](https://www.kslottery.com/games/instants/?gameid=418)
list game number, start date and **prizes remaining** by prize tier, including
small prizes and sometimes free-ticket tiers. Remaining prizes are not a count
of tickets claimed or validated during a period, and the screen did not
establish original inventory or a dated historical series for each tier.

The [recent-winner notices](https://www.kslottery.com/recent-winners/robert-hendrix-250k/)
occasionally identify a selling retailer and exact address, but cover selected
stories, not every winning ticket. A retailer finder is linked from the
[Lottery's official site](https://www.kslottery.com/contact); a stable statewide active-retailer
export and winner-to-retailer join have not been verified. Draw results and
prize rules alone do not establish how many Kansas tickets won each tier.

The Lottery's [open-records policy](https://www.kslottery.com/Downloads/openrecordsactfinalrevisedoctober2014.pdf)
directs written requests to its Freedom of Information Officer at
`info@kslottery.net` and describes possible fees. Existing all-tier draw
counts, Scratch claims and original inventories, the retailer master file,
definitions, update cadence and correction fields remain to be requested or
verified. On September 16, a focused written August 2026 request was sent to
the policy's published address for these existing records, with an estimate
requested before any billable work. Requester contact information was supplied
in the email and is not stored in this repository. Gmail showed the send
notification; no responsive dataset has arrived.

Kansas can display dated official remaining-prize and selected-winner subsets
with their precise definitions, but is not ready for a complete statewide
winning-ticket total or retailer heat ranking.

## September 20, 2026 redesigned-site audit

The old `kslottery.com/games/instants/` URLs now redirect to the PlayOn
homepage. The replacement official [Scratch and Pull Tab catalog](https://playonkansas.com/games/scratch-and-pull-tabs)
embeds a complete `scratchOffs` array in the page's Next.js response, even
though the rendered first page shows only twelve games. The array contains
109 entries: 103 explicitly marked Scratch and six Pull Tabs. All 109 detail
pages were retrieved and checked against the listing: game numbers, ticket
prices and advertised top prizes agree. Every detail page has prize rows;
free-ticket rows remain categorical prizes rather than cash.

The listing includes historical games: 58 of the 103 Scratch entries have
end dates before September 20, leaving 45 without a passed end date. Those
45 detail pages contain 421 prize rows. Do not import all 103 as active games.
Keep end dates separate from claim deadlines; ended games may still be
redeemable. Remaining inventory is not a dated winning-ticket total.

A date discrepancy still requires an explicit handling decision before
publication: game 490's listing metadata says August 24, 2026, but its detail
page displays August 23. Do not silently choose a launch date. The detail
pages state that remaining quantities update hourly, but do not display the
actual inventory verification timestamp. Retrieval time must not be called
source verification time. Example [100x detail page](https://playonkansas.com/games/scratch-and-pull-tabs/100x).

Local reproducible audit files are under ignored `work/kansas_catalog/`:
`audit.py`, `list.html`, `listing.json`, all 109 detail pages and `audit.json`.
No Kansas public feed was changed during this audit. The existing records
request remains pending; no duplicate request was sent.

### Conservative catalog import

The importer now selects only explicitly typed Scratch games with no announced
end date or claim deadline and a metadata launch date before retrieval day.
A fresh September 20 fetch verified 45 games and 421 prize tiers. Each game's
identity, price and top prize must match its detail page; the detail expiration
must be TBD. The displayed prize table's accessibility and visual values must
agree and are counted only once. Unknown numeric counts and unsupported
noncash labels stop publication. Free-ticket tiers retain their categorical
label and do not acquire a cash amount.

Both original launch representations are retained as provenance fields
(`sourceLaunchMetadata`, `sourceLaunchDisplayed`). Neither is mapped to the
app's normalized `startDate`. Each game discloses the conflict and unknown
inventory verification time. `sourceDate` is null; retrieval/change time is
separate. The source states hourly updates; the publisher checks every six
hours. This is intentionally the no-announced-end subset, not every redeemable
game, all-tier dated claims, or a fully developed state's retailer coverage.

Six regression tests cover eligibility, missing type/date fields, duplicate
identities, zero counts, free-ticket semantics, conflicting source identity or
amounts, expiration disagreements, and duplicate rendering. A malformed source
cannot overwrite the previous file; the full import validates before replacement.


## October 14, 19:40 ET — Sole active state

Kansas activated after Louisiana acceptance. Fresh scope is due October 15 at
19:40 ET; supported release decision is due October 19 at 19:40 ET, with a fresh
120-hour integration window and no extension. See KANSAS_ACCEPTANCE.md.

The current scheduled baseline has 46 games, retrieval October 14 at
12:13:36.236975-05:00, and no source inventory verification date. Fresh public
home/draw-directory/Super Kansas Cash HTML was captured privately. The embedded
draw directory lists twelve entries, including both Lucky for Life and Millionaire
for Life; metadata alone does not establish current game status. Pick 3 describes
two daily drawings. Literal prize legends do not prove actual Kansas winner counts.
Resolve product history, dated reports and options before closing scope. Digital
instants, Pull Tabs, Keno/Racetrax, raffle and loyalty need explicit scope decisions.
No account access, purchases, public feed changes or new correspondence occurred.


## October 14, 20:41 ET — Supported scope closed; public result API audited

Scope closed ahead of October 15 at 19:40 ET. Captured all twelve linked draw
detail pages, their public scripts and read-only public result API responses
privately under work/kansas_scope/. The site's own JackpotService uses
`/services/jackpot/api/v1/jackpot-results` on
`https://gateway-web.loyalty.playonkansas.com`, with COMPLETE status, game ID,
page/size and a separate doublePlay filter. No credentials or account actions
were needed. Detail CMS confirms distinct Pick 3 IDs 9 (Midday) and 10 (Evening),
not one combined result group. The public game directory labels both explicitly.

| Product | Supported integration target | Limits |
| --- | --- | --- |
| Powerball | Two recent base results and two Double Play results, literal number groups/Power Play and published prize schedules | Separate variants; no inferred Kansas winner counts or cash conversion |
| Mega Millions | Two current-rule results and literal multiplier/prize rules | CMS still labels a field Megaplier; retain/disclose source wording, no fabricated draw-wide current multiplier |
| Lotto America | Two results, All Star Bonus and literal schedule | No regional winner count inferred from raw shares |
| Super Kansas Cash | Two results, cash jackpot source field and schedule | All-zero raw share fields are not proof of zero Kansas winners |
| 2by2 | Two results with separate number groups and published bonus rules | Categorical free-ticket awards remain categorical; no count aggregation |
| Millionaire for Life | Two results and literal lifetime award schedule | No multiplication into lifetime totals or cash-option conversion |
| Powerball Xs & Os | Two results with official team mapping and schedule | IDs must map exactly to source teams; no invented labels |
| Pick 3 | Two Midday plus two Evening results; ordered/repeated/leading-zero digits and literal wager schedules | No winner rows in sampled result payloads; missing counts stay unavailable |
| Keno / Racetrax | Two bounded recent results each, explicit draw numbers/times and official rules routes | Not a live stream or all-draw history; no wager-specific calculated payout or winner count |
| Scratch | Existing no-announced-end/claim-deadline catalog with all published remaining tiers and provenance | 46-game baseline; no source inventory verification timestamp, no dated claims/stock |
| Pull Tabs | Official shared catalog/detail route and explicit gap | Excluded from existing Scratch importer; do not relabel as Scratch |
| Holiday Millionaire Raffle | Current official schedule/rules/source route | Current page describes January 4, 2027 final drawing; sampled historical results end in 2025 and must not appear as current 2026/27 winners |
| Lucky for Life / old Mega Millions | Separate historical routes and explicit gap | Lucky result feed ends February 21 local date with no next draw; current MM ID12 separate from old ID2 |
| Digital instants / PlayOn promotions, loyalty, rewards | Official source routes and unsupported winning-data disclosure | No account, purchases, ticket identifiers, balances or promotional winner totals |
| Retailers / selected winner stories | Official search/news routes with clear limitations | No validated full directory/export, exact location join or retailer heat ranking |
| Earlier history | Explicit bounded-history gap | Two results per group is not ten years or complete statewide claims |

Target **24 bounded results across ten current families and twelve groups**:
Powerball base/Double Play and Pick 3 Midday/Evening are separate; each other
family has one group. Historical Lucky for Life and raffle are not counted as
current daily families. The [North Dakota Lottery's official historical page](https://lottery.nd.gov/games/lucky-for-life/)
confirms the final Lucky for Life drawing February 21, consistent with the
Kansas retained API history; a null CMS end date does not establish activity.

Two named source issues must be handled before publication. First, raw
`prizeTiers.shareCount/shareAmount` have no demonstrated Kansas geographic unit;
some games have all-zero placeholders while others have large share counts.
The site's visible past-results component disables its details column. Exclude
these raw count/amount fields from the supported result model rather than
claiming Kansas winners or zero wins. Published prize legends remain separate
schedules. Broader counts remain a records/source-audit outcome, not a reason
to leave the supported results unusable.

Second, API `drawingDate` follows UTC in sampled evening draws: Super Kansas
Cash 2026-10-13T02:10:00Z is October 12 in America/Chicago, while drawingDate says
October 13. Preserve raw timestamp/date and explicitly derive local date with
the named zone; never silently label UTC date the local draw date. Pick 3
Midday October14 is 18:13Z and retains repeated digits 2,7,7. Keno/Racetrax
must retain actual draw times; next-draw metadata can be stale and is not a
source verification date. Strict parsing and source-display cross-check remain
required before feed promotion.

Next implement strict bounded result parsing, local-date provenance and exact
family/variant/session validation, then literal schedule/catalog UI and atomic
publication/native acceptance. No generated public data, app build, simulator,
Gmail or acceptance changed. Release deadline remains October 19 at 19:40 ET;
no extension. Private captures are research evidence, not validated app output.


## October 14, 21:42 ET — Strict Pick 3 and Super Kansas Cash results

Implemented tooling/kansas_draw_results.py for Pick 3 Midday/Evening and Super
Kansas Cash. Six bounded results from retained public captures validate; all
supplied rows are checked before selecting two per group. Number identity,
order, ranges, repeats/leading zeros, result association, completion/variant,
page counts, unique draw IDs/dates, descending timestamps and session-local
hours are guarded. UTC source timestamps/dates remain separate from derived
America/Chicago draw dates, with explicit warnings on evening date differences.

Seven focused Python tests pass, including thirteen malformed row variants,
page/date/duplicate/future failures, cash-ball limits and rejection of a bad
older row beyond the selected window. Unverified raw share counts, share amounts
and advertised jackpot fields are deliberately absent from this result output;
changing those fields cannot create Kansas winner counts or paid payouts.
Advertised jackpots and literal schedules still require separate integration.

Private normalized evidence is work/kansas_scope/validated-local-results.json;
three bounded public-response fixtures are tracked for reproducibility. This
is retained-capture parsing, not a fresh network importer or public feed.
Next extend to the other families with exact variants/types/team mapping, then
literal schedules, atomic refresh and app/native integration. Kansas remains
unaccepted; October 19 at 19:40 ET deadline unchanged. No build/UI/Gmail.


## October 14, 22:42 ET — Five multistate result groups validated

Extended the strict parser to Powerball base and Double Play, current Mega
Millions, Lotto America and Millionaire for Life. Ten retained results validate
across these five groups, in addition to the prior six local results. Public
CMS rules establish each normal/special ball range. Exact variant flags,
current game IDs, unique normal balls and required Power Play/All Star Bonus
multipliers validate; Double Play and current per-play Mega Millions reject a
fabricated draw-wide multiplier. Historical MM ID2/pre-April8 rules are excluded.

Opaque public result IDs remain sourceExternalId, not displayed draw numbers;
numeric local-game draw numbers remain separate. Date provenance and warnings
are unchanged. No raw share counts, actual payouts or advertised jackpots are
promoted. Literal schedule and advertised-prize integration remains pending.

Ten Python tests pass, including variant mismatch, all four special-ball limits,
missing/boolean/invalid multipliers and historical MM rejection. Five bounded
public fixtures are tracked; private normalized output is
work/kansas_scope/validated-multistate-results.json. Powerball fixtures separate
the two actual variants from the retained mixed response; the future collector
must request each variant explicitly and preserve two per group.

Next 2by2, Xs & Os exact team mapping, Keno and Racetrax, then schedules and
atomic collector/app integration. This is retained-source parser evidence,
not fresh feed publication or acceptance. No build/UI/Gmail/deadline change.


## October 14, 23:43 ET — All twelve result groups validate

Extended strict result parsing to 2by2, Powerball Xs & Os, Keno and Racetrax.
The retained official rules establish 2by2's two 1–26 groups, Keno's 1–80 range
and Racetrax's twelve horses/ordered finishing positions/allowed bonus values.
2by2 permits overlap across groups but rejects duplicates within each; Tuesday
multiplier 2 is validated against the derived local weekday and accompanied by
its qualifying consecutive-day-play limitation. No universal doubled payout is
inferred. Racetrax retains FIRST/SECOND/THIRD/FOURTH order and source bonus 1
without manufacturing a prize amount.

Keno retains all twenty source numbers in original order with the one SPECIAL
marker explicitly preserved; frequent results may share a local date but must
have unique identities and strictly descending timestamps. No live-stream or
all-day-history claim is made. Fetched the site's public game-number/15 mapping
without authentication; all 32 unique mapping IDs and labels must validate before
the eight Xs & Os values receive official team abbreviations. Team images and
unneeded mapping fields are excluded from the small tracked mapping fixture.

Thirteen Python tests pass, including missing/duplicate/wrong-game team mappings,
number ranges/types, special-marker multiplicity, finishing-order types and
bonus/day mismatches. All retained fixtures now produce **24 results across
12 groups / 10 families**, privately saved in
work/kansas_scope/validated-all-results.json. This remains parser evidence, not
an atomic fresh importer or public feed. No share counts or payouts are promoted.

Next literal schedule/qualification extraction and separately labeled advertised
prizes, then atomic collection/regression guards, app loader/UI and native
acceptance. Kansas release remains due October 19 at 19:40 ET; no extension,
Gmail, build, simulator or state acceptance change.


## October 15, 00:45 ET — Eight families' literal schedules extracted

Added strict Next.js detail CMS extraction and schedule parsing for Powerball,
Mega Millions, Lotto America, Millionaire for Life, Pick 3, Super Kansas Cash,
2by2 and Xs & Os: nine tables / 66 literal rows from retained official captures.
Exact game/session IDs, table/column order and row identities are required;
missing cells/rows/qualifications fail closed. Rules, source disclaimers,
table descriptions/footers and prize qualifications remain distinct. Lifetime
awards, free tickets, base/Double Play columns and Mega Millions' multiplier-odds
table are preserved without calculated payouts or winner totals.

CMS values containing doubled dollar markers are retained verbatim with an
explicit warning. Pick 3 source prose and table disagree on Any Order box
descriptions; both are retained with a separate source warning, not silently
repaired. Required qualification phrases guard pari-mutuel/shared jackpot,
Power Play/Double Play exclusion, lifetime cash-option source text and Tuesday
eligibility. Quoted source cash options are not computed conversions.

Seventeen combined Kansas Python tests pass, including schedule identity/schema,
missing/partial qualification and ambiguous Next.js payload rejection. All eight
retained HTML pages parse; private normalized schedules are saved under
work/kansas_scope/validated-schedules.json. System Python lacked lxml during an
inspection; the established dependency runtime completed extraction/tests.

Keno/Racetrax schedules, separately labeled advertised prizes and collection
assembly remain next, followed by atomic fresh import/publication and app/native
acceptance. This is not a new public feed or accepted state. No build/UI/Gmail;
October 19 at 19:40 ET release deadline remains unchanged, no extension.


## October 15, 01:46 ET — Keno long-text source decoding

Inspection of the remaining Keno schedule found its qualification text stored as
an inline Flight long-text reference (`$14`), rather than direct CMS prose. The
CMS extractor now resolves rich-text leaf references from exactly one text record
using the advertised hexadecimal UTF-8 byte length. Missing/ambiguous references,
truncated text and invalid byte boundaries fail closed. Other CMS strings remain
untouched. The retained Keno capture now yields all three qualification paragraphs,
including progressive 6/7/8-spot awards, ticket limits and the $1,500,000
pari-mutuel threshold; no values were inferred from the reference token.

Eighteen combined Kansas Python tests pass, including Unicode byte lengths and
four malformed reference cases. The resolved qualification evidence is private
under work/kansas_scope/keno-resolved-qualifications.json. Keno's ten schedule
tables and Racetrax's two tables/cards still need strict integration; no public
feed, app acceptance, build or simulator change. Release remains due October 19
at 19:40 ET, without extension.


## October 15, 02:48 ET — Remaining literal schedules extracted

Keno and Racetrax now have strict schedule extraction from the retained official
CMS captures. Keno preserves ten tables / 56 rows, distinct basic and Bull's-eye
columns (including their distinct source keys), spot-game titles, overall odds,
progressive and liability qualifications. Its 6-spot match-one basic prize cell
is literally blank: retained with an explicit warning, never converted to zero.
Progressive bonus amounts are not supplied by these tables.

Racetrax preserves two tables / 17 rows, horse Win/Show odds and returns, bonus
probabilities, four named prize-range cards and their exact official PDF routes,
wager instructions and liability/pari-mutuel notes. Full PDF payout matrices are
not embedded; the output discloses that boundary. No award arithmetic or winner
counts were introduced. Table titles and primary schedule descriptions are now
retained separately from rules and qualifications.

All ten current families parse from retained HTML: 21 tables / 139 literal rows.
Nineteen combined Kansas Python tests pass, including ten new malformed
Keno/Racetrax cases covering titles, blank cells, missing qualifications/cards,
invalid prize ranges and changed PDF routes. Private normalized evidence updated
at work/kansas_scope/validated-schedules.json. Separately labeled advertised
prizes and collection assembly remain next, then atomic fresh import/publication,
app loaders/UI and native acceptance. No new public feed/build/UI/Gmail or state
acceptance; October 19 at 19:40 ET deadline remains unchanged, no extension.


## October 15, 03:47 ET — Bounded collection assembly

Added a pure collection assembler requiring exactly all twelve current result
groups and ten schedule families. Every raw result page, official team mapping
and literal schedule validates before any collection is returned. The output
contains 24 results and ten separately keyed schedules, with explicit associations
for both Pick 3 sessions and Powerball base/Double Play. Keno/Racetrax retain
bounded-snapshot labeling. UTC/local date provenance and all source qualifications
remain intact; raw share counts, actual payout claims, retailer joins and historical
Lucky for Life/raffle results remain excluded.

Twenty-three combined Kansas Python tests pass. New collection checks cover
complete associations, missing/extra groups or schedules, invalid individual
result/schedule/mapping inputs, and missing/too-early retrieval timestamps.
Private fixture assembly is saved as assembled-fixture-collection.json under
work/kansas_scope; it is not a fresh network capture or published dataset.

Separately labeled advertised-prize handling remains pending; the collection
explicitly states it does not yet provide an advertised jackpot feed. Next complete
that source handling and atomic fresh import/regression protection, then scheduled
publication, app loaders/UI and native acceptance. No build/UI/Gmail, public feed
or state acceptance change. October 19 at 19:40 ET deadline remains unchanged.


## October 15, 04:48 ET — Separate advertised jackpot metadata

The collection now validates four separately dated advertised prize records for
Powerball, Lotto America, Super Kansas Cash and current-rules Mega Millions.
Direct source cash values and annuity values remain distinct; cash-only Super
Kansas Cash's zero annuity placeholder becomes no annuity value, never a zero
prize claim. Lifetime, fixed-prize and historical products are excluded from this
jackpot layer and retain their literal schedule treatment.

Raw UTC draw timestamps/source dates and derived America/Chicago dates are
preserved. A source draw time already passed at retrieval is explicitly marked
and must not be presented as upcoming. Advertised values are not actual winnings
or computed cash conversions. Required families, unique game identities, dates
and positive integer amounts validate before collection output.

Twenty-seven combined Kansas Python tests pass, including direct amount/date
provenance, historical/lifetime exclusion, passed-time labeling and ten invalid
metadata cases. This uses retained source fixtures, not a new network capture.
Next atomic fresh importer/regression guards and scheduled publication, then app
loaders/UI and native acceptance. No public feed/build/UI/Gmail or acceptance
change; October 19 at 19:40 ET remains the supported release deadline.


## October 15, 05:47 ET — Atomic fresh collection importer

Added the Kansas importer with explicit Powerball base/Double Play request
filters, twelve result-page requests, ten schedule pages, official team mapping
and advertised metadata. All inputs validate before atomic replacement. Per-group
window regression, changed timestamps on existing result identities, advertised
draw-date regression and retrieval-time regression reject the refresh. Unchanged
content retains prior bytes and retrieval time; failed requests/parses/replacement
preserve the prior file and temporary files are cleaned up.

Thirty-one combined Kansas Python tests pass, including request/parse/storage
failure preservation, unchanged timestamp/bytes, five regression variants and
explicit variant URLs. A fresh official network run succeeded with 24 results,
ten schedules and four advertised-prize records at
2026-10-15T09:47:02.440545+00:00. Private output is
work/kansas_scope/fresh-collection.json. Latest local dates include October 14
for Pick 3 and Powerball, October 15 for frequent-game snapshots and October 11
for Xs & Os; this is a bounded source window, not complete historical coverage.

Next scheduled Scratch/report transaction, staged publication and app loader/UI,
then native acceptance. No public feed promoted, build/UI/Gmail or acceptance
change. October 19 at 19:40 ET deadline remains unchanged, no extension.


## October 15, 06:48 ET — Scheduled collection transaction and publication staging

Kansas now declares Scratch plus the draw collection as a two-output scheduled
transaction. The collection command runs as a Python module from the repository
root. Failure at either importer restores both prior files and dates. The targeted
transaction suite passes with the Kansas failure-at-each-command case added.

The validated 24-result / ten-schedule / four-advertised-prize baseline retrieved
2026-10-15T09:47:02.440545+00:00 is staged in data and the public docs endpoint.
The publisher copies and commits this endpoint alongside existing state feeds.
Publication success and deployed-byte verification are still pending; the first
scheduled two-output success is a separate open checkpoint. App loader/UI and
native adoption remain pending. No build/UI/Gmail or state acceptance change;
October 19 at 19:40 ET deadline remains unchanged, no extension.


## October 15, 07:49 ET — Initial publication failed; repair retry queued

Publisher 38722671385 (049d1be) failed in the Python record/catalog test step;
deployment was skipped. This is not a verified public endpoint. The exact remote
traceback was unavailable through the accessible log endpoint. The full same
Python discovery command passes locally: 282 tests. Inspection identified a
cross-test import through the generic `test` namespace in the new importer tests,
which can collide with Python's installed standard-library test package. Removed
that dependency in 47f86f9 and reran all 282 tests successfully. This is a plausible
portability repair, not a proven remote root cause until CI confirms it.

Replacement publisher 38729732959 was queued on 47f86f9 at last check. Next verify
its result and deployed bytes before closing initial publication; scheduled
transaction success and app/native integration remain open. No acceptance or
deadline change; no build/UI/Gmail.


## October 15, 08:47 ET — Publication recovered and public bytes verified

Replacement publisher 38729732959 completed successfully on repair 47f86f9.
The deployed Kansas collection endpoint exactly matches both the committed data
baseline and docs copy (SHA-256
cbe8c3644e02aee8c3106debb3a9669133d94c31b608698e1a0d9292a7a9ddd9).
It contains 24 results, ten schedule families and four separately dated advertised
prize records; retrieval remains 2026-10-15T09:47:02.440545+00:00.
Public endpoint: https://apollohouser-cpu.github.io/lottery_atlas/kansas_draw_collection.json

Initial publication/recovery checkpoint is CLOSED. CI now passes after removal
of the cross-test namespace dependency; the earlier inaccessible traceback still
does not independently establish its precise failure mechanism. Latest scheduled
run 38728061316 used pre-repair 049d1be and failed before refresh/deployment, so
first successful scheduled two-output transaction remains OPEN. Do not equate
successful push publication with a successful scheduled source refresh.

Next strict Flutter collection validator/cache-remote-bundle loader, then UI and
native acceptance; native adoption is not yet claimed. No build/UI/Gmail or state
acceptance change. October 19 at 19:40 ET deadline remains unchanged.
