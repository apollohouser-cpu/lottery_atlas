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
