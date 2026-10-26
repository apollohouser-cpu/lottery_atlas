# New Mexico source screen — September 14, 2026

The [official Winners page](https://www.nmlottery.com/winners/) says it lists
winners of $5,000 and above. Some entries name a retailer and street address,
but this selected high-prize threshold cannot establish an all-tier
winning-ticket count or complete retailer ranking.

The [Scratchers top-prizes-not-yet-claimed page](https://www.nmlottery.com/games/scratchers/top-prizes-not-yet-claimed/)
explicitly calls its remaining counts estimates and warns that winning
tickets may have been sold but not yet redeemed. Its top-prize scope and
claim lag prevent treating it as an actual all-tier winning-ticket total.
Draw results and the retailer section also do not establish a complete
retailer-linked ticket feed in this screen.

The Lottery's [Public Records page](https://www.nmlottery.com/lottery-info/public-records/)
lists `publicrecords@nmlottery.com` and says a formal written request must
include requester name, mailing address, and telephone number. On September
14, an email **process and data-availability inquiry** was sent to that
address seeking existing electronic all-tier counts, Scratch claims, public
retailer records, definitions, cadence and fees, and clarification of the
contact requirements for electronic delivery. Gmail confirmed “Message
sent.” This inquiry is not a formal filed records request. No responsive
data or complete state coverage is verified; New Mexico is not ready for
full-state testing.

On September 16, after the requester supplied the required mailing address
and telephone, a formal written IPRA request was emailed to the Lottery's
published records custodian. It asks for existing August 2026 all-tier draw
and Scratchers validation/claim records, the public retailer directory and
available winner-to-retailer joins, definitions, corrections, cadence and
recurring sources. It excludes private winner identifiers, discloses possible
commercial use and asks for a fee estimate before paid work. Gmail confirmed
“Message sent.” Agency acknowledgment and responsive records are pending.

## September 20, 2026 inventory and ending-date audit

The official top-prizes page loads its table from
`https://nmlotteryscratchers.sks.com/ScratchersPrize/GetTopPrizesHtml`, an endpoint
explicitly referenced in the public page's JavaScript. The response contains
63 unique game numbers with explicit ticket cost, game name, top prize and
estimated remaining count. Its source timestamp is September 20, 2026,
03:17 PM; the displayed timezone is unspecified. Preserve that literal source
time and date without inventing a timezone or equating it to retrieval time.
The official disclaimer calls the counts estimates and warns that tickets may
already have been sold or not redeemed.

Joining game numbers to the official [Games Ending page](https://www.nmlottery.com/games/scratchers/games-ending/)
identifies nine inventory entries whose claim deadlines have passed: 631, 632,
633, 637, 639, 641, 653, 664 and 669. Ten more have ended sales but remain
redeemable: 581, 601, 638, 648, 657, 658, 659, 660, 661 and 668. Thus 54 of the
63 inventory entries are not expired under these notices; only 44 have no
matched passed sales-end date. Do not describe all 63 as active games or infer
store stock from a nonzero estimated remaining count. Use explicit claim
deadlines, not a calculated 90-day approximation.

Two historical closing rows outside the current inventory have inconsistent
dates: game 525 lists an end date in 2204 but a claim deadline in 2024; game
551 lists an October 2024 end with a January 2024 deadline. Do not silently
correct those records. A future importer should validate matched game dates,
quarantine unrelated historical anomalies, and stop if an included game has
an impossible chronology. Original spellings can also differ across sources;
join by verified game number rather than requiring exact titles.

Read-only audit materials are in ignored `work/new_mexico_catalog/`:
source-page HTML, inventory HTML, ending-page HTML, reproducible `audit.py`,
and `audit.json`. All price/count fields and unique identities passed checks.
No public New Mexico feed changed during this pass. The IPRA request remains
pending; no duplicate request or fee commitment was made.

### Validated import

A fresh import validates 54 unexpired report entries and excludes the nine
expired games listed above. Ended-but-redeemable entries retain both official
dates in their data and visible inventory note. Every game labels remaining
counts as estimates and warns about sold/unredeemed tickets. The literal
source timestamp is preserved with a null timezone; no UTC offset is guessed.

Five regression tests cover zero/invalid counts, estimate labels, inclusive
claim-deadline boundaries, future source dates, matched impossible dates,
unrelated historical anomalies and changed table headers. An offline app test
checks expired-game exclusion and visible deadline/estimate notes. The importer
validates before atomic file replacement. Six-hour publication now includes
this catalog; it remains top-prize inventory coverage, not all-tier dated claims
or a fully developed state.

## September 21 formal acknowledgment

The Custodian of Records acknowledged the September 16 August 2026 IPRA
request in a one-page letter dated September 21, delivered at 01:05 UTC on
September 22 (September 21 locally). The letter repeats all four requested
categories: draw-game counts, Scratcher claims or dated inventories, retailer
directory/joins, and definitions/cadence/corrections. It states that the Lottery
will respond **by October 1, 2026**. This is a promised response date, not a
promise that all records will be delivered by then.

The acknowledgment contains no denial, dataset, fee estimate, assigned case
number, or request for clarification. No user action or fees are required.
Continue monitoring through October 1, then follow up if no substantive response
arrives. The validated existing public Scratcher catalog remains available.

The original letter is preserved privately at
`work/new_mexico_records/2026-09-21-acknowledgment.pdf`; its full page was rendered
and visually reviewed. Gmail message: `1a0c6a60df62c11d`. The letter and requester
contact information are not included in published data.

## October 1 agency response

Message 1a0f98004eb94107 delivered 2026-10-01_Apollo-Houser-Draw-Records.pdf
(271,067 bytes), satisfying the promised October 1 response date. Connector
extraction says the agency points to public records for draw counts, Scratch
information and a current retailer list; it explicitly says it has no record
including prize-tier details and no documents fitting the requested definitions,
cadence/correction/feed information. It also says future records requests are
not allowed. This records the agency response, not independent legal advice.

The PDF links appear as “here” in extraction; link-target inspection and private
archival remain pending. No structured workbook or new claim layer has been
verified or published. Do not treat this response as complete all-tier delivery
or continued waiting for the promised response. No fee is stated in the extracted
response. Public-source work remains viable without activating New Mexico.


## October 3 correspondence follow-through

Acknowledged October 1 PDF receipt, public-source referrals and unavailable portions. No further work requested pending inspection of the linked sources. Attachment archival/link audit remains unfinished; no complete delivery asserted or fees authorized. Gmail confirmed sent in the existing thread: 1a1008e3e10da3c9.

## October 25, 18:38 ET — New Mexico activated

New Mexico is the sole active state after Oklahoma acceptance. Full supported
scope/gap matrix due October26 at18:38ET; supported release decision due October30
at18:38ET. Fresh120elapsed hours for substantial all-game draw/rule/app work;
no extension used. Existing estimated top-prize Scratch import is a partial
foundation, not all-game acceptance. Seventeen states accepted;28 unfinished.

Four opening official pages captured privately with retrieval timestamps and
SHA256 hashes at22:38:27–22:38:30UTC in work/new_mexico_scope/opening-manifest.json.
The [games navigation](https://www.nmlottery.com/games/) links Scratchers,
Powerball, Mega Millions, Lotto America, Roadrunner Cash, Pick3 Plus and Pick4
Plus. This is an opening list; exhaustive current/retired scope remains pending.
[Drawing Results](https://www.nmlottery.com/drawings/drawing-results/) embeds
an official-linked nmlotterydynamic.sks.com pastdrawings page. Both Pick Plus
pages embed separate result endpoints and describe Day/Evening drawings in
Mountain Time. Session/date identities, Plus variants, report geography/count
units and history boundaries must be verified from payloads before import.

Scratch counts remain estimated top prizes, not all-tier claims or retailer
stock; source timestamp timezone remains unspecified. Review current ending and
claim deadlines, preserve unknowns and quarantine unrelated historical anomalies.
October1 agency response and October3 acknowledgment remain closed correspondence;
private PDF/link audit is outstanding. Do not resend, request supplied contact
information or authorize fees. Missing agency records will remain explicit gaps.

Next capture embedded results and all game/rule pages, fix the complete product/
history/gap matrix, then strict parsers, coupled atomic publication and app/native
acceptance. No new public all-game feed, app build or acceptance at activation.

## October 25 evening — embedded source and history reconnaissance

Private scope-manifest.json captures 22 pages; embed-manifest.json captures 16
linked payloads; history-manifest.json captures all ten archive selectors for
October22–25. All include actual retrieval times, byte lengths and SHA256 hashes
under ignored work/new_mexico_scope. No public feed changed.

Six current draw families plus Powerball Double Play have linked results.
Pick3 Plus/Pick4 Plus payloads explicitly label DAY/EVE; retain leading zeroes
and key by date/session, never source row order (some dates list DAY before EVE).
Current Pick Plus rules describe Straight/Box/Combo and pair plays, not a separate
bonus-number drawing. Prizes are subject to pari-mutuel reductions with a stated
per-tier maximum payout of $125,000 from June27,2021. Exact rule validation remains
open. PB, DP, MM and Lotto America tables explicitly label New Mexico results;
count units and disjoint base/add-on semantics still need validation. These are
candidate reports, not accepted imports. MM tables distinguish five per-play
multiplier groups. Current draw results and future jackpot estimates are separate.

Archive selectors also include Hot Lotto, legacy Pick3/Pick4 and Lucky Numbers
Bingo. The first three return no results for the requested current window, which
does not establish historical absence. Lucky Numbers returns a JavaScript search
shell, not validated results. Rules navigation also lists Fast Play!; its current
status/catalog must be resolved before scope closure. Historical overview mentions
Mega Match4 and a New Year's Eve Raffle. These remain explicit research items.
The archive's static default iframe queries March/April2015 despite a current
visible date range; do not import that default as current. That retained response
also includes April15 beyond its April14 end parameter, so filter/validate actual
row dates independently of requested bounds. Full history completeness unverified.

Fresh Scratch endpoint shows67 rows at literal October25,2026 03:18PM, timezone
unpublished. Existing strict parser joins ending notices and retains57 unexpired
entries, excludes10 passed claim deadlines, and preserves unrelated anomalous
historical rows525/551 as quarantined. Private scratch-audit.json records this
result; not a new publication. Estimated top-prize semantics remain unchanged.
Next resolve Fast Play/Lucky Numbers/retired scope, inspect rule contracts and
report units, then close the full matrix before strict all-game implementation.

## October25,20:38ET — scope/history boundary closed

The full supported matrix is fixed in NEW_MEXICO_ACCEPTANCE.md; implementation
and acceptance remain open. Additional24 official captures (Fast Play/about plus
1996–2017 history pages) are hashed in private retired-manifest.json.
[Fast Play status](https://www.nmlottery.com/games/fast-play/) explicitly marks
six named games ended and announces March2026 endings for Jackpot7s/Red Hot
Jackpot Bingo and a JackpotUSA pause. Retained sales prose does not verify resumed
availability. These products will have explicit historical/availability gaps,
not current inventory or inferred progressive values.

The [FY2021 Lottery financial report](https://www.nmlottery.com/wp-content/uploads/2022/01/New-Mexico-Lottery-Authority-FY-2021-Financial-Audit-Report-Final.pdf)
records Lucky Numbers Bingo ending in March2019 and Pick3 replacement by Pick3
Plus in June2021. Its financial aggregates are not draw-level winner reports.
[Historical pages](https://www.nmlottery.com/lottery-info/lottery-history/)
identify Daily Millions, Mega Match4, 4 This Way!, Hot Lotto, New Year's Eve Raffle,
MONOPOLY MILLIONAIRES' CLUB and earlier Quicksters. All retired/prior-version
history remains unavailable for import, with explicit gaps rather than invented
zeroes. Current PB/MM/LA/DP report units remain a validator gate despite explicit
New Mexico headings. Scope closure does not assert report acceptance.

October25,21:42ET: retained archive captures now drive a strict current-format
result parser and six minimized public-source HTML test fixtures. Eleven tests
pass. The short October22–25 opening window validates21 raw records, bounded to14
across nine groups; it is not a complete two-date collection. Pick digits retain
leading zeroes; rows must match explicit session classes and dates, main/special
ball ranges and current multiplier rules. DP stays separate. All winner reports
remain unavailable until independently validated. No new source retrieval or
publication is claimed; next implement literal rules/report validation and the
wider-window coupled collector.

October25,22:40ET: added literal contracts for all six retained current how-to-play
HTML pages: ten tables/111 physical rows including headings, with span/header/text
semantics and full caveat prose preserved. PB includes Double Play; MM's second
table is per-play multiplier odds, not a draw result. Seven rule tests plus eleven
draw tests pass. Brochure PDFs/images are not claimed visually audited. Exact-date
report validation and atomic coupled collection remain open; no source refresh or
public publication this pass.

October25,23:44ET: the retained official-linked Double Play table now passes
strict exact-date/geography/schema/tier/count/total validation: nine tiers,
664 source Winners / prizes won, $5,967 total prize value for October24. These
are source prizes-won units, not deduplicated people/tickets or paid claims.
Seven report regressions pass,25 focused NM tests together. No new retrieval,
publication or report availability in the app is claimed. Main PB, MM and LA
column validation remains outstanding; historical exact-date gaps stay unavailable.
