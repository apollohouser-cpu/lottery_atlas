# North Carolina source screen — October 8, 2026

North Carolina is now the sole active state. See NORTH_CAROLINA_ACCEPTANCE.md
for fresh October 8 source evidence and the October 9 scope / October 13 release
deadlines (10:38 ET). Earlier correspondence notes below remain historical; no
new agency response or complete dataset is implied by this activation.


The [NC Education Lottery Scratch-Off Prizes Remaining](https://nclottery.com/scratch-off-prizes-remaining)
page publishes prize tiers, totals established at printing, and prizes
remaining, with a daily as-of date. It calls remaining prizes “not yet
claimed.” The difference between total and remaining may describe claimed
prizes for listed games, but its treatment of reorders, game endings, and
all-tier completeness must be validated before publishing any derived count.
Printed totals alone are not winning tickets actually sold or claimed.

The official [Winners pages](https://nclottery.com/WinnersAll?g=PB) show
claims of $5,000 and up and say they update weekly. They include retailer
names for some rows, but explicitly include unavailable/non-retailer cases.
This is a high-prize subset, not a complete all-tier heat map or statewide
winner total. No all-tier draw export or complete retailer join was verified.

The Lottery's [contact page](https://nclottery.com/contact) lists
`PlayerInfo@lotterync.net`. On September 14, an inquiry was sent there for
routing to the records/data team, requesting existing all-tier draw and
Scratch counts, a retailer directory and public winner joins, source dates,
corrections, cadence, fees, and the proper filing route. Gmail confirmed
“Message sent.” No substantive response or complete dataset has arrived;
North Carolina is not ready for full-state testing.

Later September 14: Player Service directed the inquiry to
`https://records.lotterync.net` for a public records request. The form has
required name, email, description, and request-type fields; its address and
phone fields are shown without a required marker. A formal request was not
successfully submitted during this screen, so no case number exists yet.

On September 16, the portal's embedded form was retried in the in-app browser
and Chrome. Its email and request-type controls did not reliably retain input,
so no portal submission was claimed. A complete written August 2026 request
was instead emailed to `publicinfo@lotterync.net`, the public-records contact
provided in Player Service's reply. It asks the custodian to accept and assign
a tracking number or provide a working alternative route, discloses potential
commercial use, and asks for a fee estimate before paid processing. Gmail
confirmed “Message sent.” Acceptance and responsive data remain pending.

## October 8 supported-scope review

Full product scope is closed in NORTH_CAROLINA_ACCEPTANCE.md; release remains due
October 13 at 10:38 ET. Fresh official report pages distinguish per-tier NC wins
from combined Pick 3/4 winners and Cash Pop session summaries. The dated Pick
3/4 detail payout schedules do not provide per-tier winner counts. Preserve these
source distinctions in the forthcoming integration; no report totals were
promoted by this review. Scratch Reordered status increases printed prize counts,
so inventory differences must not become claimed-ticket totals.

## October 8 directory collision audit (12:40 ET)

Fresh official directory capture contains 7,528 rows and 7,494 normalized
name/city keys. Twenty-eight keys contain 62 rows. The existing archive matcher
silently kept the last branch for repeated keys; 107 activities in the retained
snapshot have one of those ambiguous keys. Those positions are not validated
joins. Counts describe this audit, not a newly accepted statewide directory.

The importer now excludes every repeated normalized name/city key from archive
matching, including third occurrences and identical duplicates. Three focused
Node tests cover uniqueness, order independence and normalization collisions.
The raw directory and collision details remain private in
work/north_carolina_scope/directory-audit.json. No public snapshot was regenerated
or promoted during this audit; previously published positions remain pending
correction through the validated refresh pipeline. News fuzzy matching and the
global date-based archive/news overlap heuristic still require separate repair
or exclusion before NC acceptance. NC remains unaccepted and the October 13
10:38 ET release deadline is unchanged.

## October 8 mapped-activity correction (13:45 ET)

Excluded 107 archive records with ambiguous name/city branches and both existing
news records from the retained NC snapshot, leaving 17,874 records. These are
retained source records, not a new distinct-ticket total or full fresh import.
All surviving records and source dates are unchanged. The public activity
publisher validated 23,937 records; 35 excluded records were within its 2026
window. All non-NC activity remains unchanged.

Removed news supplementation from the importer: fuzzy branch scoring and a
publication-date cutoff do not establish identity or prevent archive overlap.
News remains an official source route, with no mapped-record promotion. Four
Node tests now run under the existing CI test glob, including an importer fixture
that excludes ambiguous branches, rejects any news request and preserves the
output bytes on request failure. Private before/removed evidence is retained in
work/north_carolina_scope. This fixes the known joins without claiming the
remaining pagination, date/unit, directory or full NC acceptance audits are done.
Publication verification follows the correction commit; push alone is not proof.

Correction deployment verified: release `d892565`, publisher run `37818483881`
completed successfully. The public activity.json bytes match the locally
validated corrected file exactly (private checksum evidence recorded). Known
ambiguous archive records and unverified news records are absent from the public
feed. This closes the correction publication checkpoint, not NC acceptance or a
native remote-adoption check. No simulator/user-review state was changed.

## October 8 strict Scratch importer (14:42 ET)

Implemented a separate literal catalog parser and atomic importer. A fresh
private fetch validated 83 listed games / 896 prize tiers across $1, $2, $3, $5,
$10, $20, $30 and $50 price groups, with source date October 7. Source labels,
printed odds, total/remaining counts, game status and official detail links are
retained. No subtraction into claims, cash-option inference or retailer stock.

Four focused Python tests pass, including malformed columns/counts/dates/URLs,
duplicate identity, request-failure byte preservation, unchanged-date reuse,
source-date regression, identity/tier changes, future dates and literal reorder
increases. The importer rejects unexpectedly small catalogs and material drops.
Private snapshot: work/north_carolina_scope/scratch-catalog.json. This is parser
validation only: no public catalog promotion, scheduled refresh wiring, app
loader/UI replacement or NC acceptance yet. Next integrate the catalog schema
and strict draw reports; existing static NC UI is still the older snapshot.
Release deadline remains October 13 at 10:38 ET. No simulator or Gmail changes.

## October 8 bundled literal catalog and Flutter loader (15:45 ET)

Added the validated 83-game / 896-tier October 7 source-date catalog as an app
asset, plus a dedicated strict cache/remote/bundle loader. Validation retains
literal prize/odds/status/definition fields and rejects malformed counts, dates,
URLs, duplicate games/tiers, identity/tier changes and material catalog drops.
Cold-cache remote responses are checked against the reviewed bundle. Failed
requests or invalid remote responses retain the prior validated snapshot and
its dates; valid remote data survives a cache-write failure. Reorder increases
remain literal inventory changes, never calculated claims.

Four Flutter tests pass, including eleven remote-defect variants, offline
fallback, cold-cache continuity, reorder changes and persistence failure.
Two-file analysis is clean. No full build, simulator interruption or native
acceptance was performed. The new loader is not yet connected to the existing
NC Scratch UI; remote endpoint staging and scheduled transaction remain pending.
No refreshed public catalog endpoint or user-visible replacement is claimed.
Next connect the literal UI and validate compact/wide behavior, then implement
strict draw reports and refresh publication. NC deadline remains unchanged.

## October 8 literal Scratch inventory UI (16:45 ET)

The NC Scratch menu now opens the dated 83-game catalog with name/number search,
ticket-price filter, game selection and all literal prize/printed-odds/total/
remaining rows. Source date, retrieval time, reorder definitions, coverage limits
and official game/list routes remain visible. Existing favorite-game keys are
preserved, and map-context selection explicitly filters retained high-prize
claims; inventory counts do not create map positions. Removed the old static
remaining-prize list from the desktop NC panel. Both the compact map Scratch
action and state source screen reach the new inventory sheet.

Three widget tests pass: all 83 selections render and reach the footer at
390×844 and 1400×1000, plus search/price empty-result recovery. Four-file analysis
has only the existing live-map line 288 informational brace notice. No full
build, simulator navigation, native/source-return acceptance or remote endpoint
publication was claimed. Scheduled catalog integration and draw reports remain
pending; October 13 release deadline unchanged. User simulator review untouched.

## October 8 Cash Pop report parser (17:45 ET)

Implemented strict Cash Pop aggregate-session parsing with all five official
session names and printed times. Fresh official history validates two latest
reports per session (ten reports, October 6–8). Morning Buzz October 8 prints
633 winners / $21,908; October 7 prints 741 / $30,259. These remain private
source observations, not promoted app totals. Each report preserves the Pop,
source winner count, payout label and exact payout cents; no tier counts,
distinct-person totals, retailer joins or map locations are fabricated.

Four Python tests pass: bounded latest selection from unsorted rows, malformed
fields/dates/counts/columns/session times, duplicates/missing sessions, zero and
fractional payout handling. Every supplied history row is validated before
selecting the recent window. Unrelated odds/promotion tables are excluded by the
specific history structure. Private capture/results are under
work/north_carolina_scope/cash-pop-fresh.html and cash-pop-reports.json.
Remaining seven draw families, combined atomic refresh and app report UI are
still pending. No public report output, native verification, Gmail or deadline
change; North Carolina remains unaccepted.

### October 8 — Pick 3/4 bounded combined-summary validation

Captured the four latest detail links from each official Pick 3/Pick 4 history
page privately. Strict parsing confirmed two Daytime and two Evening reports
per game (Daytime October 8/7, Evening October 7/6). The accessibility label on
the official date identifies **Daytime Draw** or **Evening Draw**; no session is
inferred from sequential draw identifiers. The source labels its totals
**Total Combined Winnings**. The parser preserves those totals and ordered
winning digits, without converting printed payout schedules into tier winner
counts. Literal schedule extraction remains pending. Private captures and
`pick-summary-reports.json` are under `work/north_carolina_scope`; no public
report publication or native adoption is claimed.

### October 8, 19:46 ET — Pick schedule structure validated

The eight captured Pick details now retain both literal base and Fireball
schedules (16 tables / 128 rows). Wager headings remain 50¢ Base Play and $1 Base
Play; combo cells retain their separate play-cost labels. Explicit rowspans are
expanded for display without creating new observations. Match combinations are
separated as printed digits rather than concatenated into a number. Fireball's
qualification about the chosen numbers and play type is retained. N/A remains
N/A, not a zero-dollar payout. No schedule row has a fabricated winner count.
The strict combined-report parser requires these schedules; private validation
and eleven passing parser tests do not establish publication or native adoption.

### October 8, 20:47 ET — Cash 5 dated tier evidence

The official Cash 5 history links dated `cash5?dd=10/07/2026` and
`cash5?dd=10/06/2026`; both detail pages were captured privately and validated.
Each contains four base and four Double Play tiers under Match / Prize / Wins.
The base and Double Play logos identify their separate numbers and tables;
Double Play shares the page's dated draw context. The parser requires that date
to match the requested dated URL. Official how-to-play text specifies five
numbers from 1 to 43 for both variants. Advertised rollover estimates remain
literal prize labels plus source footnotes, never computed payout totals.
This adds private parser evidence only, not public feed or native adoption.

### October 8, 21:46 ET — Millionaire for Life tier validation

Official history links for October 7 and October 6 were normalized only by
removing spaces in their date query, then fetched privately. The response's
printed date must exactly match the requested date. Each detail contains nine
Match / Prize / Wins rows and explicitly limits the table to North Carolina;
out-of-state jackpots are excluded. The first two prize labels remain
$1 Million/year for life and $100,000/year for life. No annuity cash values or
statewide distinct-person counts are inferred. The how-to-play source confirms
five numbers from 1–58 and Millionaire Ball 1–5. Private parser validation and
passing tests do not establish public publication or native adoption.

### October 8, 22:46 ET — Xs and Os bounded report evidence

Fresh official history links yielded dated October 4 and September 27 details.
Date-query spaces were removed; response dates were checked against the URL.
Both expose Match 8 through Match 4, Cash Prize* and Wins, plus eight team labels.
The parser retains the source qualification that jackpots are shared, lower
prizes may become pari-mutuel, and the table covers North Carolina only.
No prize-by-count total, nationwide win count or map location is inferred.
Two reports / ten tiers are privately validated; publication remains pending.

### October 8, 23:47 ET — Powerball source-label discrepancy retained

Fresh October 7/5 dated reports each contain nine base tiers, eight separately
printed Power Play tiers and nine Double Play tiers, all scoped to North
Carolina. The Double Play four-white-ball row displays no red Powerball but
carries the source accessibility label `4+PB`. The parser preserves that label
alongside the independently checked visual match identity `4` and a warning;
no silent correction or reassignment of Wins occurs. The future app report must
show the warning. Other label/symbol disagreements fail validation. No separate
Power Play jackpot count, paid total or national count is inferred. Private
validation and 24 passing tests do not establish live or native acceptance.

### October 9, 00:46 ET — Mega Millions multiplier evidence

Two fresh dated reports (October 6/2) retain all printed X10/X5/X4/X3/X2 prize
and Wins entries, plus the jackpot without a multiplier. Source heading
Megaplier remains literal. The source explicitly limits these to North Carolina.
The displayed one-white-ball plus Mega Ball row conflicts with its accessibility
label `2`; both are retained with a required UI warning. No count is reassigned
or summed into a distinct-ticket/person claim. Strict structural/multiplier tests
pass; private report validation does not establish publication or native adoption.

### October 9, 01:47 ET — Unified private report retrieval

A fresh bounded collection run validated all eight supported families and all
14 session groups, two reports each. The collection's September 27–October 8
range reflects weekly and daily draw schedules, not a continuous all-game
claims history. All details came through the family-specific strict parsers;
Powerball and Mega Millions source-label warnings remain present. Private
atomic refresh, missing-group/regression checks and failure preservation now
have automated coverage. Scheduled publication and app/native adoption remain
unverified; no public report feed was promoted by this checkpoint.
