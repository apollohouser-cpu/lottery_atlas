# Kentucky source screen — September 17, 2026

Kentucky has **partial-coverage map data ready for testing**. The current
published feed includes an official catalog of 81 available Scratch-off games,
3,377 precisely located retailers out of 3,472 distinct official directory
entries returned across 120 counties, and 32 current winner notices matched
to a unique verified retailer point. The importer excludes 95 retailer
addresses without precise coordinates and four winner notices without an
unambiguous retailer match. These selected winner notices are not complete
2026 winning-ticket counts or a statewide retailer ranking; no Kentucky
all-game winning-ticket total is published.

The [Kentucky Lottery's Open Records page](https://www.kylottery.com/apps/about_us/openrecords)
lists residency categories. The requester is a South Carolina resident and
cannot certify Kentucky residency. The Lottery's
[media page](https://www.kylottery.com/apps/about_us/media.html) permits a
written email request to its records custodian. On September 17, a candid
nonresident inquiry was emailed to the published custodian for existing 2026
year-to-date all-tier draw counts, Scratch prize/claim inventories, retailer
directory and maintained winner joins, definitions, publication cadence and
public download links. Gmail confirmed “Message sent”; no paid work was
authorized. Await the agency's reply on permissible access and the records.

Current partial data can test source labels, retailer location display and
selected-winner points. It cannot validate a complete statewide winning-ticket
heat map or an all-tier comparison with other states.

### September 24 Census transport failure

Publisher 35939079754 attempt 2 stopped at this directory's Census batch lookup
with HTTP 502. The previous live directory remains available. Census multipart
lookups now retry temporary service failures up to four times, with a 120-second
whole-request limit per attempt. Permanent errors still fail immediately;
exhausted retries still stop publication. Existing address matching and county
validation rules are unchanged. Five new Node HTTP regression tests passed as
part of the 55-test suite. Deployment recovery remains to be verified separately.

### September 24 verified publishing recovery

Publisher 35945318934 attempt 2 succeeded at 03:21 UTC. All four live JSON
feeds were independently checked and match published commit 55b9631. This
resolves the refresh interruption described above; the bounded Census retry
change is included in the successful run. Existing coverage limitations and
pending agency definitions remain unchanged. No user intervention was needed.

### September 25 acceptance scope update

The September 17 counts above are historical snapshots. Current generated
imports include 36 current notices and eight retained 2024–2025 notices, plus
a separate initial record; they must not be summed into a complete statewide
winning-ticket count. The native source screen now explains selected coverage,
separate retailer locations and unconfirmed agency cadence. Source date precision
is under active acceptance review: current and historical importers encode
date-only headings at noon, which is not a verified event time.

### September 25 Kentucky scope and per-game gap inventory

Scope is all supported physical lottery games and official result information,
not Scratch alone. Release deadline remains September 28, 6 PM ET. This is an
initial inventory; open source/interaction gaps below must be resolved or evidenced
before acceptance. Official sources inspected September 25:

- https://www.kylottery.com/apps/ — current game menu and results headings.
- https://www.kylottery.com/apps/winners/index.html — current winner stories and
  date-grouped retailer notices (latest notice heading September 23).
- https://www.kylottery.com/apps/draw_games/pastwinning.html — official results
  destination; web reader timed out this session, so details remain unverified.

| Game/product | Existing verified app evidence | Required acceptance work |
| --- | --- | --- |
| Scratch | Catalog, separate directory, 35 current selected notices plus retained history | Catalog/reset, location/details, date/provenance, offline and final visual checks |
| Powerball, including any Double Play coverage | Two retained Powerball records; current official winners page also links Powerball stories | Inspect current stories for selling-store evidence; verify national-game selection and latest mapped date; distinguish Double Play |
| Mega Millions | Official current game/results presence; no record in the current/retained KY imports inspected | Review official result/winner sources; import supported selling-store evidence or explicitly document missing evidence, then exercise empty-state/source flow |
| Millionaire for Life | One current selected retailer notice; schedule configured | Verify game matching, annual-prize semantics (not a lifetime/cash total), date and source |
| Cash Ball 225 | Separate initial activity record and configured schedule | Verify provenance/date and game selection against official results |
| Pick 3 / Pick 4 | Midday/evening schedules configured | Verify official schedule/results, winner-count/location availability and honest empty-state flows |
| Keno / Cash Pop | Recurring schedules configured; homepage says every four minutes | Verify schedule window and source/result access; no fabricated map records |
| Fast Play | Official game menu/winner story presence | Review store-versus-online evidence and supported information flow; do not invent a draw schedule |
| Powerball xno homepage label | Separate current homepage result heading/link observed | Establish official product identity and applicability before mapping it to a game or treating it as unsupported |
| Online instant games | Official stories exist, including online-only prizes | Exclude from physical-retailer heat points; no inferred store or residence coordinates |

Current imported counts are selected rows, never statewide ticket totals. The
current importer contains 36 rows (35 Scratch, one Millionaire for Life), retained
history has eight rows (six Scratch, two Powerball), plus a separate initial Cash
Ball record. Records need overlap/semantic review before aggregating any display.

Fixed one concrete acceptance defect: current and retained Kentucky notice rows
were labeled DRAW DATE in individual details. These imported ID families now show
NOTICE DATE; the initial Cash Ball record keeps its separate draw-date semantics.
The timeline already uses date-only Kentucky labels. This label fix still needs
native details inspection in the next acceptance pass; no checklist is falsely
marked complete by a build alone.

Startup repository clean, no matching new agency mail, publisher 36121391338
successful; activity/catalog/directory feeds independently matched local copies.
Next work: inspect current Powerball stories and the official result pages, then
exercise Kentucky native game/date/detail flows. Texas remains closed.

Kentucky generated-data checks and the macOS debug build passed after the notice-date label correction. Public data is unchanged; this native UI change does not require a feed deployment.

### September 25 Powerball story audit and official results access

Advanced the current Powerball selling-store evidence gap. Three official story
pages were inspected directly and compared with the current verified directory:

- https://www.kylottery.com/apps/winners/all/LaGrangeWomanWinsPowerballPrize
  describes July 15, 2026 and a $50,000 prize; its winners-card summary instead
  says $150,000. The body identifies Smart Shop in Pendleton as seller, but no
  verified directory entry matches that store name. Hold this candidate.
- https://www.kylottery.com/apps/winners/all/PitStopPayDay describes August 1,
  2026 and $150,000 including Power Play, while its summary card says $50,000.
  It identifies Pilot Travel Center in Franklin, where the directory has three
  plausible stores (#046, #661, #438). Do not choose one from proximity or names.
- https://www.kylottery.com/apps/winners/all/CampbellsvillePowerballWinners
  describes two separate $50,000 tickets. The Lexington Kroger address has a
  malformed ZIP and abbreviated directory candidate. T-MART Campbellsville has
  one directory candidate, but the article gives only a relative draw date for
  that ticket and omits the year from the other ticket's April 18 date. Neither
  is ready for a dated map point without additional official evidence.

All candidates remain unpublished. Local originals are staged in ignored
work/kentucky_story_review. Summary cards cannot safely supply prize amounts or
winner residence as selling location; no new retailer coordinates were invented.
This review resolves why these visible stories cannot simply be auto-imported;
it does not imply absence of other usable official records.

The official past-winning-numbers page now loads. Its payout disclaimer explicitly
limits displayed payouts to Kentucky, separate from national results. Replaced
the app's generic Kentucky homepage result link with this direct verified page
and a scope-aware subtitle. Dynamic result rows still require inspection before
any statewide count import. The page explicitly identifies Powerball Xs & Os,
resolving the earlier opaque 'xno' label; this is a distinct product requiring its
own applicability/results review, not ordinary Powerball activity.

Source: https://www.kylottery.com/apps/draw_games/pastwinning.html
Next named gaps: inspect dynamic per-game results/definitions (especially Mega
Millions and Xs & Os), then Kentucky native notice-date/game-selection acceptance.
No new agency mail. Scheduled publisher 36135693365 succeeded; fast-forwarded the
clean checkout to 2bac915 and verified live activity matches again. The initial
mismatch was the scheduled refresh, not deployment failure. Deadline unchanged.

### September 25 Kentucky statewide tier source unlocked

Inspected the actual public results page's request code, then used its read-only
WinningNumbers.xhtml requests: infoRequest 11 for history and 17 plus drawNumber
for details. Game 26 is Mega Millions; game 24 is POWERBALLXO (distinct Xs & Os).
The current response contains 51 Mega Millions draws and two Xs & Os draws; this
is only the returned window, not a complete archive. No retailer fields supplied.

Latest reviewed Mega Millions draw 2380 (September 22) reconciles 2,465 reported
Kentucky winners and $49,433 payout across separate tier/multiplier rows. Xs & Os
draw 2 (September 20) reconciles 831 winners and $14,738. Draw timestamps encode
the Eastern calendar date; they are not evidence of exact event time. Source
publication dates remain unavailable. Official page disclaimer scopes payouts
to Kentucky: https://www.kylottery.com/apps/draw_games/pastwinning.html

Added a bounded parser and real-response regression fixtures for these two
layouts. It preserves base prize/multiplier fields and rejects wrong games,
unreviewed groups, inconsistent totals, duplicate tiers and jackpot-winner rows
requiring separate payout treatment. All 71 Node tests pass. No statewide totals
have been mapped onto stores or added to the public ranking/feed.

Next concrete acceptance work: connect these validated statewide results to a
separate Kentucky table view, inspect other game layouts, and exercise native
selection/notice-date flows. This resolves the earlier inability to inspect the
dynamic response; Mega Millions statewide data is available even though retailer
locations are absent. Kentucky deadline unchanged.

### September 25 statewide table integration and native acceptance

Kentucky Drawings now opens a separate Statewide prize tables sheet for the two
reviewed layouts, Mega Millions and Powerball Xs & Os. The latter remains distinct
from ordinary Powerball. Source draw dates, unavailable publication dates, base
prizes, multipliers, Kentucky winner counts and reconciled tier payouts are visible.
The sheet explicitly excludes retailer locations and complete historical claims.
Other games remain under review; this is not Kentucky's final release decision.

The new importer discovers each latest returned draw from official history,
requires matching detail identity/date/totals, rejects missing/unknown tiers and
source regression, and writes only after both reports reconcile. Scheduled
six-hour refresh joins Kentucky's existing transaction: a failed Kentucky command
restores its previous validated files and dates. Unchanged reports retain the
original feed timestamp. Publication revalidates source responses and their
rendered tables. The public feed contains only official draw-level responses;
no ticket identifiers or inferred store coordinates are involved.

Native 800×632 acceptance passed: Kentucky selection → Drawings → Statewide prize
tables; Mega Millions September 22; horizontal and vertical scrollbar navigation
to totals 2,465 / $49,433; switching to Xs & Os resets scroll positions and shows
September 20, with totals 831 / $14,738. Coverage and official-source controls are
visible without overflow. Offline bundle/cache, malformed remote, persistence
failure and game switching have six passing Flutter checks. All 74 Node checks
pass; macOS debug build passes; analysis remains at 12 existing infos.

Next acceptance gaps remain other draw-game layouts and integrated Kentucky
activity/date/favorites flows. Scope reconciliation and release deadlines remain
September 26 06:58 ET and September 28 18:00 ET respectively. No new agency reply
beyond the already recorded Texas acknowledgment was found this session.

Deployment evidence: commit c4ddf57 published successfully in run 36152041101.
Independent HTTPS retrieval of kentucky_draw_tiers.json matched the checked-in
feed byte-for-byte (SHA-256
1dea651e67136bf331376c76dcab08459854e17a9803c06607939fa46c0cab6b).
The native debug build's two-game table flow is ready for testing; the live JSON
feed is published, not a new mobile-store or web-app binary release.

### September 25 remaining draw-game scope reconciliation

Queried the official results page's listed game IDs (not guessed endpoints), using
its documented read-only history/detail requests. Private raw responses are in
work/kentucky_story_review/history-{game}.json and details-{game}.json. The
following scoped implementation gaps are now explicit:

| Game | Direct evidence inspected | Remaining acceptance gap |
| --- | --- | --- |
| Powerball / Power Play | September 23 draw 4245: 7,152 Kentucky winners, including 1,324 Power Play winners; $55,894 reported payout | Connect reviewed parser to tables and native acceptance. Power Play is a subset, not additional winners. |
| Powerball Double Play | Separate nine-tier group: 704 winners, $7,032 | Keep its own counts, identity and table; never combine with base Powerball. |
| Mega Millions | September 22 table already integrated and accepted for testing | Included in final integrated Kentucky pass. |
| Powerball Xs & Os | September 20 table already integrated | Distinct product; confirm applicability/schedule separately. |
| Millionaire For Life | September 24: nine tiers reconcile 958 winners / $10,569 | Import with explicit top-prize annuity/cash semantics; do not flatten source top amounts into guaranteed cash. |
| Pick 3 | September 24 contains both MIDDAY and EVENING identities; midday 983 / $91,340 | Fetch and validate both sessions, not max(date) selecting the first tied row. |
| Pick 4 | September 24 contains both MIDDAY and EVENING identities; midday 22 / $6,900 | Same two-session requirement. |
| Cash Ball 225 | September 24 base tiers reconcile 2,637 / $9,778; separate EZ totals 685 / $2,219 | Preserve base versus EZ scope; EZ has no tier group in reviewed response. |
| Keno | Inspected draw 1416942, September 25: 3 / $7; empty tier group | Draw IDs matter because many draws share date. Treat aggregate-only response separately; do not manufacture tiers or exact times. |
| Cash Pop | Inspected draw 748335, September 25: 2 / $12; empty tier group | Same aggregate-only and draw-identity requirement. |
| Fast Play / online instant games | Not represented in this official past-results dropdown | Explicit unavailable claims/retailer activity scope until a reviewed official source supports it. |
| Scratch | Existing catalog and selected notices remain supported | Finish catalog, notice-date, source and favorites acceptance; selected notices are not statewide claims. |

The Powerball page template labels TIER_SPECIAL_DRAW as KY Power Play Winners.
The reconciled payout is base prize × total winners plus the Power Play uplift
for that subset; match-five uses 2X. Double Play uses its separate field prefix
and published totals. Added a real-response fixture and bounded parser that
rejects unknown groups, missing tiers, impossible subsets, inconsistent totals
and unreviewed top-prize winners. These additional games are not yet published
in the two-game table feed. This is source/layout reconciliation, not final
Kentucky release acceptance. Remaining data have no selling-retailer locations.

### September 25 Powerball and Double Play table integration

Expanded the Kentucky statewide feed/sheet to four reports: Mega Millions,
Xs & Os, Powerball, and Powerball Double Play. Power Play has a visibly labeled
subset column; a per-report note explains the draw's multiplier and match-five
2X treatment. Double Play has its own report and totals. Both preserve September
23 source draw dates and unavailable publication dates. Existing two-report cache
remains readable during rollout; failed imports retain validated prior data.
Six focused Flutter tests pass including selection of both new reports and their
separate counts. All 76 Node checks pass. Other state games and final integrated
Kentucky acceptance remain outstanding; the September 28 deadline is unchanged.

Native 800×632 acceptance passed for both new reports: scrollbars reach Powerball
7,152 total / 1,324 Power Play subset / $55,894 payout and Double Play 704 / $7,032;
game switching resets scroll position, source date and explanatory note correctly.
macOS debug build passes; analysis remains at 12 existing infos. Commit d1970e6
published successfully in run 36164788118; independent live retrieval of
kentucky_draw_tiers.json matches the checked-in four-report feed byte-for-byte.
The expanded table flow is ready for testing, not final Kentucky acceptance.

### September 25 state-game parser acceptance

Added reviewed real-response fixtures and a bounded parser for Millionaire For
Life, Cash Ball 225, and both Pick 3/4 sessions. Fetched the official September
24 evening detail records directly: Pick 3 draw 22608 reconciles 434 reported
winners / $52,200; Pick 4 draw 21036 reconciles 180 / $113,100. All six inspected
state-game reports reconcile their source tier counts and payouts.

The session selector explicitly returns MIDDAY and EVENING separately, rejecting
missing or ambiguous sessions rather than selecting the first record tied on a
calendar date. Cash Ball EZ totals remain a separate aggregate, not extra base
tier rows. Millionaire For Life preserves source-listed amounts and rejects any
top-two-tier winner pending annuity/cash review. No source publication time or
retailer location is inferred. Negative/unsafe counts, missing tiers, unknown
groups and inconsistent totals fail closed.

All 79 Node checks pass. This is parser/fixture acceptance only: the public sheet
still has four reports. Next step is integrating these six reports with session
labels, source dates, separate EZ scope and top-prize limitations, followed by
native acceptance and live verification. No new agency response arrived during
this session; existing four-report deployment remains healthy and byte-matched.

### September 25 six state reports integrated

Expanded the separate statewide feed from four to ten reports with Millionaire
For Life, Cash Ball 225, Pick 3 MIDDAY/EVENING and Pick 4 MIDDAY/EVENING. Each
session selects its own latest returned date and identity; sessions can therefore
have different dates. The publication validator reconstructs all ten reports from
source responses and enforces the session order. Earlier two/four-report caches
remain readable during rollout. State refresh remains transactional.

Millionaire For Life's top-tier amounts are displayed as basis unverified rather
than as verified cash awards. Cash Ball EZ aggregate counts and payouts appear in
a separate note, explicitly excluded from base totals. Keno, Cash Pop and instant
game layouts remain outside this table scope. No statewide totals become map
points. Seven focused Flutter checks and all 79 Node checks pass. Native visual
acceptance and independent live verification are recorded separately below.

Native 800×632 review verified the expanded ten-item game/session menu, visible
Millionaire For Life top-prize limitation and Cash Ball's separate EZ note.
Switching Pick 3 MIDDAY to EVENING correctly changes September 25 to September
24, rather than applying one date to both sessions. Automated interaction checks
exercise all six new reports, including both Pick 4 sessions. macOS debug build
passes; analysis is back to the 12 existing infos. A concurrent scheduled data
commit (08a2a8d) was preserved through rebase; no source files were discarded.
Publisher 36177493029 succeeded at ee76851. Independent HTTPS retrieval confirms
the live ten-report Kentucky feed matches checked-in bytes. These six new reports
are ready for testing; Kentucky's overall acceptance remains open for aggregate-only
games and the remaining integrated app checklist.

### September 25 aggregate-only games prepared

Resolved latest-record selection for Keno and Cash Pop. Official page code indexes
history rows by DRAW_ID and reverses the order; selecting the first maximum-date
row is wrong when many draws share one date. Fresh history/detail requests inspect
Keno draw 1417102 (79 reported winners / $240) and Cash Pop draw 748496 (2 / $19),
both September 25. These are individual draw snapshots, not daily totals or a live
stream. The returned window contains 101 records per game, not complete history.

Both detail responses have TIER_LIST=[[]]. Added real-source fixtures and a parser
that preserves aggregate totals while explicitly leaving tiers and exact draw
time unknown. No claim of tier reconciliation is made. The selector uses the
highest draw ID and rejects duplicate IDs, future dates and date-order inversions.
An unexpected tier layout requires review rather than silently changing semantics.
All 82 Node tests pass. These games are prepared for a distinct aggregate-only
presentation; the published ten-report table feed has not changed. Next step:
connect those summaries with prominent draw ID, scope and snapshot freshness,
then finish integrated Kentucky acceptance. Deadline unchanged.

### September 25 aggregate collection safeguards

Added an injectable Keno/Cash Pop collector, keeping aggregate snapshots separate
from reconciled prize-tier reports. It selects the verified latest draw identity,
requires history/detail dates and totals to agree, rejects regression, and retains
snapshot update time when the returned reports have not changed. A failed second
game cannot return a partially collected replacement. Fifteen focused Kentucky
Node checks pass, including disagreement, regression, unchanged reconnection and
transport failure. No public feed or UI changed; presentation/integration remains
the next named acceptance gap, followed by integrated Kentucky flows.
Startup publisher 36183713245 succeeded; live Kentucky table bytes match the
checked-in ten-report feed. Release deadline remains September 28 at 18:00 ET.
