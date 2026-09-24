# Virginia source screen — September 15, 2026

Virginia has a verified partial implementation. The six-hour workflow imports
all 92 retail Scratchers returned by the official [Scratcher search](https://www.valottery.com/scratcher-search?view=0),
including price, top prize and current unclaimed top-prize count validated
against each game page. Remaining prizes are inventory figures and do not
represent actual winning-ticket or claim totals.

The app also queries all 135 county and independent-city options in the
official [retailer finder](https://www.valottery.com/aboutus/findaretailer).
The current directory contains 5,430 unique official retailers: 5,365 have
exact verified coordinates, while 65 unresolved addresses are retained in the
source metadata and excluded from the map rather than estimated.

Winner heat points come from the official [Latest Winners archive](https://www.valottery.com/winnersnews/latestwinners)
and are joined to exactly one current official retailer address. The published
feed contains 105 retailer-level releases from 2024–2026; the launch-window map
uses 62 records from 2026 across 39 localities and 61 retailers through August
26. Online-only releases and records without an exact unique directory match
are excluded. The archive does not publish a structured claim or draw date for
every release, so the stored date is the official publication timestamp. These
selected releases do not establish all-tier winning-ticket coverage.

The Lottery's official [FOIA page](https://www.valottery.com/foiarequest)
identifies its records email, required physical address, fee rules and a five-
business-day response framework. It says Virginia FOIA access is principally
for Commonwealth citizens, while the Lottery may provide an out-of-state
requester with records already published online. A focused August 1–31, 2026
request was emailed September 15 for all-tier draw and Scratcher counts,
retailer joins, definitions, cadence and corrections, while also asking for
exact public URLs or exports if broader records are unavailable to an out-of-
state requester. Gmail confirmed “Message sent.” Private requester contact
information is not stored in this repository.

Virginia is ready for partial-coverage testing now. Testers should verify the
complete current Scratcher catalog, retailer map, filters and timeline, and the
in-app warning that these winner releases are not complete statewide ticket
coverage. Virginia must remain outside any all-tier state ranking until the
broader records are verified.

## September 23 agency response — reviewed September 24

Virginia Lottery replied September 23 that workload prevents fulfilling requests outside its stated Commonwealth citizen/media eligibility categories. Treat this request as declined, not pending. Public-source app development continues; do not assert requester eligibility or require a new request for scoped completion.
