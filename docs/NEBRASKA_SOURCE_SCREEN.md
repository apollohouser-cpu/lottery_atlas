# Nebraska source screen — September 18, 2026

Nebraska is **not yet ready for a complete verified heat map**. Its existing
official source links and draw schedule remain in place.

- The [official retailer search](https://nelottery.com/homeapp/retailers/search)
  filters by city or ZIP. The Lottery says its retailer network has more than
  1,200 locations, but a complete published active directory with exact
  addresses and verified coordinates was not established.
- The [official Scratch prizes remaining page](https://m.nelottery.com/homeapp/scratch/prizesremaining/web)
  publishes game, price, top prize tiers and counts. Nebraska Lottery says
  this page updates weekly.
- The [official unclaimed Lotto prizes page](https://nelottery.com/homeapp/lotto/unclaimedprizes)
  identifies retailers, towns, games, draw dates and prizes, but only for
  *unclaimed* prizes; it also says it updates weekly. This is not the full
  retailer-level winner history.
- The [recent winner notices](https://nelottery.com/homeapp/landing)
  show named selling locations and exact addresses for selected recent
  winners. They are useful verified points, but do not establish complete
  claims coverage from January 1, 2026 onward.

Weekly official data is allowed with a state-specific notice; the app now
shows one for Nebraska. To complete Nebraska, verify a full official active
retailer directory and comprehensive retailer-level winner feed, preserving
each source's real publication date and cadence.

The Lottery's [public-records page](https://nelottery.com/homeapp/about/publicrecords)
identifies `lottery@nelottery.com` for written requests addressed to Director
Brian Rockey. A request was sent September 13, 2026 for existing draw-game
winning-ticket counts, Scratch game/tier original and claimed counts,
retailer records where public, source definitions, and update cadence. The
request provided a name and reply email and asked for notice before any fees.

On September 16, Lottery counsel Jordan Mruz confirmed receipt and asked for a
concrete example to route the request. A reply narrowed the initial period to
August 2026 and described example rows for Nebraska-sold draw-game winning
counts by drawing and tier, Scratch prize counts by game and tier, the active
retailer directory, and any releasable selling-retailer link. It accepted
existing standard reports and partial production with clear coverage, and
requested an estimate before billable work. Gmail showed the sent reply.

On September 18, counsel said he was still coordinating with multiple people
to determine what records are publicly available. He identified the current
[Scratch catalog](https://nelottery.com/scratch), whose game details give prize
tiers and total winners for each game; a separate
[prizes-remaining report](https://nelottery.com/images/media/Scratch_Prizes_Remaining.pdf);
[closing-game notices](https://nelottery.com/scratch-games-closing); and
[draw-game results](https://nelottery.com/lotto-detail?gamename=Mega+Millions),
which he described as showing only the latest draw. These sources may support
a dated catalog and cumulative game inventory, but they do not by themselves
establish January 1, 2026-to-current validated winning-ticket counts or
selling-retailer joins. The request for those records remains open; no fee
estimate or responsive extract was provided in this message.

## September 20 catalog and inventory reconciliation

Retrieved the current official catalog and all 25 linked detail pages. They
contain 630 prize-structure rows under `Prize / Odds / Winners**`. Prize amounts
can repeat within a game (different winning combinations). These rows must
not be treated as dated claims or as remaining inventory. The source cautions
that quantities can vary with omissions, unsold tickets, reorders and unclaimed
prizes. A URL's `gameid` is a routing identifier, not the printed game number:
for example `gameid=1035` displays game 1335, Pocket Change 5X. Join using the
printed identity, not arithmetic on routing IDs.

The separate one-page remaining-prizes PDF was downloaded, text-extracted,
rendered and visually inspected. It is explicitly dated September 13, 2026
and shows selected top prize tiers for 25 games, not every prize tier. The
report and current catalog overlap on 24 printed game numbers. Current game
1344 Power Play is absent from the report; report game 1357 50X is absent from
the current catalog. Missing remaining counts must stay unknown, never zero.
The September 13 closing page also separates closing dates from expiration
(last claim) dates. The PDF explains that tickets can remain on sale during
the closing process; a closing notice does not establish retailer stock.

Audit materials are in ignored `work/nebraska_catalog/`: official PDF,
listing/closing HTML, 25 detail pages, reproducible detail audit script,
`catalog_audit.json` and `join_audit.json`. No public Nebraska feed changed
in this pass. Next implementation should preserve the weekly report date,
selected-tier scope, distinct printed and routing IDs, closing/claim dates,
and the unmatched Power Play count while testing joins and repeated prize
amounts. The agency's request for broader records remains pending.

### Verified catalog import

The September 20 import validates all 25 current catalog games and joins 24
top-prize counts from the visually reviewed September 13 PDF. Power Play
1344 keeps an unknown remaining count. The reviewed JSON records the PDF's
SHA-256, date and manual-review method; counts require a new document review
to update. The automatic six-hour job refreshes catalog details only, never
changes the report date, and does not imply current inventory verification.
Each game displays its dated inventory or explicitly unknown count.

The importer checks printed identities, listing/detail names, explicit ticket
prices, structure-column labels, and matching top-prize amounts before writing.
Repeated prize amounts remain separate structure rows. Free-ticket and mixed
cash/ticket combinations retain their labels without a guessed cash value.
The combined feed and offline bundle both include Nebraska. This is catalog
and dated top-prize coverage only, not a fully developed state or claims heat map.

## September 21 publisher repair

Runs 35634946372 and 35638874764 failed because the Scratch page added two
promotional navigation links with no catalog prices. The importer had included
all detail links. It now excludes only the explicit `sbm_contain_all` navigation
container and retains strict price/name and duplicate checks for actual catalog
cards. A regression test covers navigation duplicates and malformed real cards.
A fresh import validated the same 25 games and 24 dated report counts. The
manually reviewed inventory date remains September 13; this repair does not
refresh those counts or invent prices for promotional cards.

Repair validation passed 107 Python tests and 64 Flutter tests. Analysis found
only the 12 existing informational notices; the macOS debug build passed.

## September 22 catalog changes and publisher repair

Publisher 35727865287 stopped because two new catalog names contained nested
`New!` badges. The importer now removes only that exact separate badge, retains
actual name text and strict listing/detail matching, and accepts explicit numeric
cash amounts in the source's Prize column with or without a dollar sign. Original
labels remain in the prize structure; structure winners never become inventory.

The fresh source has 25 listings. **24 validate**, including Buffalo Blitz 1403
with unknown remaining inventory. Pocket Change 5X and Power Play are no longer
listed; 50X 1357 is listed again. The other 22 previously published games retain
identical fields. There are 23 counts from the same manually reviewed September
13 report; that report and its date were not changed.

Black Diamond Blowout is excluded because its detail heading says **1417**, while
its ticket-art filename says **1416**. The ticket image confirms the name and
$10 price but does not resolve the number. Neither identity is guessed. The
importer checks heading/art-file identity for every entry, records this specific
conflict in excludedGames and visible catalog coverage, and will restore the
entry when those identifiers agree. Missing/malformed artwork, changed columns,
name mismatches, and other validation errors still stop publication. A minimum
catalog-size check still applies; exclusions are not silent successful imports.

The offline snapshot and combined feed use these 24 verified entries and disclose
the exclusion. Three new Python regression tests cover badges, numeric prize
labels, explicit identity exclusion/restoration, and continued failure on invalid
source data. The offline Flutter test verifies the new unknown count, preserved
September 13 inventory, and absence of the conflicting game.

Validation: 130 Python, 50 Node and 70 Flutter tests passed, plus five HTTP checks.
Live publication of this repair is checked separately from local validation.
The macOS debug build also passed; analysis reported only the 12 existing
informational notices. Other states in the combined catalog were unchanged.

September 22 deployment verification: publisher 35741615131 succeeded after the
Connecticut follow-up repair. All four live feeds matched published commit
9936bdf. Nebraska's 24 games and explicit identity exclusion are live and ready
for catalog testing; inventory still carries September 13. This does not establish
a complete claims heat map.

## September 23 transient source timeout

Scheduled publisher 35827366105 attempt 1 stopped fetching the Nebraska listing:
curl exited 28 after its bounded timeout retries. This was a transport timeout,
not a schema or identity validation error. A subsequent live request succeeded,
and the importer parsed all 25 listing entries. No parser, inventory counts,
reviewed report date or cache timestamps were changed for this transient failure.

All four existing live feeds still matched the repository. The failed GitHub
jobs were explicitly retried after source recovery (API accepted the request).
Verify attempt 2 before claiming that scheduled refresh completed. No user
action or new agency response was required at this check.

Retry outcome: attempt 2 succeeded. All four live feeds were verified against
publisher commit e6340ee on September 23. The transient outage is resolved;
the manually reviewed September 13 inventory date remains unchanged. The
subsequent 35 targeted tests for the six integrated retailer states, rankings,
offline data and calendar timeline passed. This does not replace visual
interaction acceptance or establish all-tier state completeness.

### September 25 remaining-request clarification

Jordan Mruz asked which requested records were not covered by his public links
(message 1a0d9f767d9b4d0f). Replied that the existing Scratch catalog/inventory
sources have been reviewed and need not be reproduced. Narrowed the outstanding
request to existing August 2026 Nebraska draw-tier winning-ticket counts and an
existing active retailer ID/name/address export, with any already-maintained,
releasable selling-retailer linkage optional. Existing standard reports and partial
fields are acceptable; no new report or paid work is authorized. Sent reply
1a0da2bafebffbf0. Await a response; no additional data or map coverage established.


## October 3 correspondence follow-through

October 2 agency message 1a0fe3f9f58ad1e1 delivered Active_Retailers.xlsx (65,036 bytes), explaining that the retailer search is affected by the website backend transition and that remaining requested information requires customized reporting. Acknowledged receipt and explicitly declined custom reporting or fee-bearing work. Contents remain unaudited; no new public data or positions. Remaining requested report is not a promised delivery. Gmail confirmed sent in the existing thread: 1a1008e44fd0b5a4.

## October 6, 15:03 ET — receipt acknowledgment

The agency thanked the requester for confirming receipt, identified the employee
responsible for the response and cited Neb. Rev. Stat. §84-712.03 regarding review
rights. This records the agency's notice, not an independent legal interpretation
or an instruction to seek review. Current thread history confirms the October 3
acknowledgment was sent. No new records, question, fee, deadline or promised
follow-up was supplied, so no duplicate reply was sent. The retailer workbook
remains pending private audit; custom reporting remains declined and is not an
expected delivery. Private check evidence is retained in work/agency_email_checks.


## October 16, 11:58 ET — Sole active supported integration

Nebraska activated after Kansas acceptance, with scope due October 17 at 11:58 ET
and supported release due October 21 at 11:58 ET (fresh 120 hours). See
NEBRASKA_ACCEPTANCE.md. Existing broad heat-map requirements above do not override
the current supported-coverage standard. Fresh public home and Pick 5 captures
are private; full product/session/source scope remains open. No agency workbook
rows, inferred counts or joins have been promoted. Custom reporting stays declined.


## October 16 — Ten official draw detail pages captured

Fresh public HTML for all ten current draw families and a structured table
inventory are retained privately under work/nebraska_scope (detail-0 through
 detail-9 and detail-inventory.json). These are server-rendered public pages;
no authenticated endpoint or agency records are needed for the observed tables.
This is source discovery, not a published feed or accepted parser.

The pages show seven recent number selections per family except Xs & Os, which
currently shows two. Powerball has separate base and Double Play number tables.
Pick 3 and Pick 4 describe one nightly drawing, not Kansas's two sessions.
MyDaY uses month/day/two-digit-year fields and calendar validity rules; Xs & Os
uses eight team abbreviations, not numeric balls. Preserve those distinct types.

Each page includes a latest-draw prize table explicitly headed “in Nebraska.”
This is stronger geographic evidence than the Kansas source, but “Winners” is
still the source unit: do not relabel it unique people, claims, or selling-retailer
wins, and do not aggregate overlapping option tables. Only the latest draw has
an observed prize report; older number rows must not inherit its winner counts.
A historical report request has not been established.

Options requiring separate handling: Power Play and Double Play, Lotto America's
All Star Bonus (report heading says All Star Factor), Mega Millions per-play
multiplier, and 2by2 Tuesday eligibility. The 2by2 page prints a Tuesday option
table even for Thursday October 15, with zero cells; treat applicability explicitly
rather than claiming an eligible Tuesday drawing occurred on Thursday. Mega
Millions embeds base-prize labels and multiplier-specific winner rows alongside
its current prize-range schedule; keep these literal and validate their relation.
The Power Play table also needs a literal-prize/multiplier audit before publication.
Free quick-pick prizes stay categorical. Advertised future jackpots, cash options,
annuity terms and prize-liability qualifications must remain separate from results.

Next: finish historical/non-draw/retailer route inventory and current Scratch
schema audit, close the supported/gap matrix, then implement strict per-family
parsing with dated report association. No public data, app build, emulator change,
agency correspondence or acceptance in this checkpoint. Deadlines unchanged.


## October 16, 14:00 ET — Scope closed before deadline

Scope is closed for the supported release; implementation and acceptance remain
open. The official ten-family menu and number-search form agree on current
products. No additional current family is evidenced in those inventories. This
does not assert that Nebraska has never offered other games.

| Product / feature | Supported release scope | Explicit boundary |
| --- | --- | --- |
| Powerball | Two recent base and two Double Play results; latest dated base/Power Play/Double Play source tables and literal schedules | Separate option units, no summing tables; base jackpot advertisement never applied to Double Play |
| Mega Millions | Two recent results, latest dated multiplier-specific source table, current prize ranges and per-play multiplier explanation | No invented multiplication of winner counts or cash conversion |
| Pick 5 | Two recent results and latest four-tier dated report | Free quick-pick play categorical; jackpot and pari-mutuel qualifications retained |
| Lotto America | Two recent results, latest base/All Star Factor tables and All Star Bonus explanation | Preserve source naming and literal multiplier expressions |
| Millionaire for Life | Two recent results, latest nine-tier report and literal annuity/cash schedule | No computed cash equivalents; sharing/pari-mutuel qualifications retained |
| Pick 3 / Pick 4 | Two nightly results each, latest nine/sixteen-row reports and complete bet schedules | One daily session each; overlapping bets are not unique-person totals |
| 2by2 | Two recent red/white results, latest source tables and complete regular/Tuesday schedule | Tuesday eligibility explained; off-Tuesday option zeros are not actual Tuesday winner observations |
| MyDaY | Two recent month/day/year results and latest seven-tier report | Validate calendar including source leap-year rule; preserve two-digit year |
| Powerball Xs & Os | Two weekly team results, latest five-tier report, cash/pari-mutuel qualifications | Team outcomes are random draws, not NFL scores; promotions separate |
| Scratch | All validated current catalog prize-structure rows, literal odds/structure winners, retained reviewed top-prize inventory and identity exclusions | Structure winners are not remaining counts or dated claims; report-only games excluded, stock unknown |
| Historical numbers | Official date-range search route | No ten-year import or historical winner-report claim; older number selections never borrow latest report counts |
| Closing games / unclaimed prizes | Official closing and unclaimed source routes | Source-only: no complete claims layer, automatic retailer joins or win heat |
| MVP / ticket promotions | Official MVP/contest and Xs & Os promotional routes | No account access, entry, promotion inventory or purchase flow |
| Retailers | Explicit unavailable in-app directory/map coverage pending private workbook audit | Legacy search route returned HTTP 404 today; do not advertise it as a usable finder or publish agency rows/coordinates |
| Other/historical products | Disclose outside the bounded current menu and offer official home/search routes | No invented current Keno, raffle, Pull-Tabs or Lucky for Life coverage |

Target number window is **22 results across 10 families / 11 groups** (Powerball
base and Double Play separate), two per group. Latest report tables are separately
dated; no second historical report is promised. Non-applicable option cells need
explicit handling. Unsupported source claims must fail validation, not be filled.

Fresh existing Scratch importer run succeeded privately: **24 games / 594 physical
prize-structure rows**, 22 matched dated top-prize counts, one conflicting-identity
exclusion. Inventory remains the manually reviewed **September 13** report;
current retrieval does not make that inventory newer. Repeated prize amounts are
separate physical rows. No public feed was changed. Official closing page is dated
October 11; current unclaimed page is a selected outstanding-prize list, not a
claims history. Private captures: search.html, closing.html, unclaimed.html,
scratch.html and current-scratch.json under work/nebraska_scope.

Next implement strict result/report parsing and schedule extraction, then atomic
publication and app integration. Private retailer workbook audit can establish a
separate bounded directory only after schema/identity review; it does not block
this supported scope. Release remains October 21 at 11:58 ET; no extension.


## October 16 — Strict bounded number parser

Implemented tooling/nebraska_draw_results.py for all ten families / eleven
result groups. All ten retained official HTML pages parse to the intended 22
bounded results; private output is work/nebraska_scope/parsed-results.json.
Validates exact family/group columns, full displayed window before truncating,
local date order/future/weekday restrictions, numeric cardinality/ranges,
distinct ball sets, ordered repeated Pick digits, Power Play allowed multipliers,
MyDaY calendar rules and eight distinct named Xs & Os teams. Date-only values
retain America/Chicago semantics without invented UTC draw times.

Eight focused Python tests pass, including malformed numbers/dates/groups,
multiplier and team rejection, repeated-digit preservation, year00 leap-day and
older-row validation. This parser intentionally does not attach latest report
winners to older number results. Prize reports, schedules, atomic collection,
app/native and private retailer audit remain pending. No public feed/build/UI,
Gmail or acceptance change; release deadline unchanged.
