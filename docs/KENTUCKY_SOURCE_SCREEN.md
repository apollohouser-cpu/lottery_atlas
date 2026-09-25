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
