# Texas source screen — September 15, 2026

Texas has a strong verified partial implementation. The six-hour workflow
imports the complete current [Scratch ticket list](https://www.texaslottery.com/export/sites/lottery/Games/Scratch_Offs/all.html),
including price, top prize and remaining top-prize count. The September 15
run contained 79 current games. Remaining prizes describe inventory, not the
number of winning tickets sold or claimed.

The app also imports the official [Texas Lottery sales-by-retailer open dataset](https://data.texas.gov/See-Category-Tile/Texas-Lottery-Sales-by-Fiscal-Month-Year-Game-and-/beka-uwfq).
The September 15 run found 20,033 current retailer licenses; 19,612 had exact
verified coordinates and 421 unresolved addresses were excluded from the map.
The source supports the retailer directory but does not itself identify every
winning ticket.

For winner activity, Lottery Atlas imports the Lottery's game-specific Scratch
top-prize selling-retailer reports. The current feed contains 5,889 exact 2026
records across 218 counties and 4,500 retailers, through September 13. Each map
record has a claim date, game, top-prize amount and exact retailer joined to the
official directory. Unmatched or ambiguous addresses are excluded. This is a
large, current, verified heat-map dataset, but its scope is Scratch top-prize
claims rather than all prize tiers or draw-game winning tickets.

An August 1–31, 2026 request was emailed September 15 to the official Public
Information Office address published in the [Texas request portal](https://texaslottery.govqa.us/WEBAPP/_rs/supporthome.aspx).
It seeks existing all-tier draw and Scratch counts, complete retailer joins,
definitions, cadence and corrections. Gmail confirmed “Message sent.” The
requester contact information was supplied directly and is not stored here.

Texas is ready for partial-coverage testing now. Testers should see the current
Scratch catalog, verified retailer heat points, filters and timeline, together
with the in-app warning that published records do not establish complete
statewide winning-ticket coverage. Texas must not appear in a complete all-tier
state ranking until responsive records establish that broader scope.

## September 24 processing and date limitation

The game 2678 [official top-prize selling-retailer report](https://www.texaslottery.com/export/sites/lottery/Games/Scratch_Offs/retailerswhosoldtopprizes.html_252699512.html),
opened from the app during native acceptance, states that its rows cover fully
processed Claim Center claims. Filed claims can enter game-page counts before
appearing in the retailer report. Its page-level as-of date was September 23.
The in-app Texas limitation notice now explains this processing delay.

The importer currently sets sourceLastUpdated to the latest included claim
date, not the report footer's as-of date. These dates must not be treated as
equivalent. No date was changed or inferred in this pass. The shared report
as-of metadata path remains a follow-up; the linked official page exposes the
report date. The historical September 15 counts above are snapshots, not current
counts. Final available-coverage acceptance is governed by STATE_COMPLETION_PLAN.

## September 25 UTC acceptance

Texas is ready for testing of its explicitly limited available-data experience.
See STATE_COMPLETION_PLAN.md for native filter, source, layout and offline
evidence and the final automated checks. This supersedes the earlier provisional
readiness statement; it does not establish complete statewide claims coverage.

## September 25 correction: national draw activity

The user rejected Scratch-only sign-off. Texas is active; Kentucky and Virginia
remain on hold. The earlier readiness statement is superseded for full-state
acceptance.

The official Powerball and Mega Millions annual archives link per-draw **Where
Sold** tables. The new importer inspected 114 Powerball and 76 Mega Millions
2026 draw pages, through September 23 and September 22 respectively. It mapped
nine Powerball and one Mega Millions second-tier records using a unique exact
address/city/ZIP join to verified directory coordinates. Source retailer names
are retained, even when the current directory name differs. This verifies the
address, not historical retailer/license identity. Three unmatched addresses
remain excluded; the May 2 Powerball jackpot is excluded because the advertised
jackpot is not evidence of the individual ticket's share.

Each included row has game, prize tier, draw date, source-listed prize amount and
its official report link. Dates are draw dates, not claim or purchase dates.
No validation time, claim time, cash payout or complete all-tier retailer counts
are inferred. The latest inspected draw date is sourceLastUpdated; it is not a
page publication timestamp. The six-hour refresh checks all inspected draw pages
and Texas rollback preserves the prior validated files if any importer fails.

Native acceptance verified both game shortcuts, automatic latest mapped date,
Dallas Powerball August 8 ($2 million), Wichita Falls Mega Millions January 16
($2 million), county summaries, individual records and visible source/date
limitations. A discovered camera issue after county inspection was fixed: game
selection now returns to Texas bounds. All 75 Flutter tests, six new importer
checks and a macOS debug build passed; analysis retains 12 pre-existing infos.

Remaining acceptance work includes the other Texas draw games, full-game filter
and reset checks, and independent live verification of this addition. Official
Lotto Texas pages also expose draw results and tier totals; retailer-level
coverage must be inspected before declaring those games unavailable. The
September 15 August records request remains unanswered in the checked mailbox.

### Additional state draw reports, September 25

Expanded the same 2026 audit to Lotto Texas (114 draw pages), Texas Two Step
(77), Cash Five (229) and All or Nothing (916 individual drawing pages). The
feed now has 144 matched selling-location rows: Powerball 9, Mega Millions 1,
Lotto Texas 3, Texas Two Step 19, Cash Five 106 and All or Nothing 6. Thirteen
rows are excluded: eight unmatched addresses, two ambiguous address joins and
three advertised/shared jackpot amounts. Each state report's top-tier winner
count must match its selling-row count before import. Repeated Cash Five rows
are retained because the official winner count reconciles with the row count.
All or Nothing's named drawing session is preserved in the source label without
inventing an exact event time. Lotto Texas amounts are source-listed nominal
jackpots; cash-value election does not make that nominal amount a cash payout.

September 24 Pick 3 and Daily 4 detail pages were inspected. They provide results
and prize information but no Where Sold retailer table. They remain unsupported
for retailer heat points; this is not evidence of zero wins. Existing official
records correspondence seeks the missing retailer/count evidence. Complete
statewide data remains a separate outcome from acceptance of available features.


Publisher 36099818061 successfully deployed the expanded feed September 25.
Independent live download matched the locally validated activity file exactly,
including all 144 draw records. This addition is ready for testing; final Texas
acceptance remains active in STATE_COMPLETION_PLAN.md. A no-fee follow-up in the
existing August request thread (message 1a0d714b2dc394b0) asks for receipt/status,
existing definitions and missing retailer reports without withdrawing the request.

### Scratch provenance and identifier correction

The current 6,473 mapped Scratch rows now carry the report footer's actual as-of
date in each source label (September 23 in this import), separately from their
individual claim dates. The feed retains latestClaimDate separately and uses
report dates for sourceLastUpdated. Missing report dates are explicitly labeled.
Public IDs are now SHA-256 hashes of the former internal composite identifiers;
pack/ticket components are no longer printed in the current public feed. Legacy
bundled/cached IDs and saved map favorites normalize to the same hash to avoid
double-counting and preserve saved selections in the updated app. Historical
repository versions are not rewritten by this change.

### September 25 statewide prize-table implementation

Added a separate Drawings in Texas → Statewide prize tables view with nine
latest-draw reports across Powerball, Mega Millions, Lotto Texas, Texas Two Step,
Cash Five and the four All or Nothing sessions. Each table retains official tier,
prize and winner columns independently; no rows become retailer map activity.
Mega Millions multiplier partitions are validated against each tier total.
Source publication dates remain explicitly unavailable; draw dates are shown.
Pick 3/Daily 4 are explicitly excluded from this view pending source review.

The importer participates in Texas transactional refresh/rollback and six-hour
publication, with bundled/cache fallback. At 800×632, native acceptance verified
readable wrapped headers, game switching, horizontal scrollbar access to 10X
columns, and vertical access to the final total row. 77 Flutter tests passed
before the scrollbar refinement; the targeted widget test and macOS debug build
passed again afterward. All 66 Node checks pass. Analysis retains 12 prior infos.
Texas remains active; next gap is Pick 3/Daily 4 statewide source review and final
acceptance reconciliation. Complete statewide retailer claims are not asserted.
