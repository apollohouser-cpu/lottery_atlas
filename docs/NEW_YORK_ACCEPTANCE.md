# New York supported-coverage acceptance

Activated October 2, 2026 at 19:00 ET as the sole active state after Virginia's
acceptance. Existing working imports qualify for 72 hours. Full game-scope
reconciliation is due October 3 at 19:00 ET; release decision is due October 5
at 19:00 ET. Not yet accepted.

## Opening inventory and bounded gaps

- 106 Scratch-Off catalog games; official catalog source retained.
- 13,161 mapped official directory entries, zero unresolved in the generated file.
- 1,601 public winner activity rows (111 Scratch-Off, 1,490 draw), source date
  October 2, 2026. This is selected published activity, not statewide all-tier claims.
- Existing state schedules include NUMBERS and Win 4 midday/evening, Take 5
  midday/evening, Quick Draw, Pick 10, LOTTO and Millionaire for Life; Powerball
  and Mega Millions are also required scope. Reconcile Money Dots, add-ons and
  historical Cash4Life against current official sources before closing scope.

## Acceptance checklist

- [ ] Complete national/state draw and Scratch scope reconciliation, including
  available actual winner/tier reports, source cadence and explicit unavailable data.
- [ ] Audit winner category and date semantics, distinguishing publication,
  processing and draw dates; do not infer ticket counts from ambiguous records.
- [ ] Integrate supported reports and source routes with cache/bundle fallback.
- [ ] Native compact/wide catalog, retailer, map, filters/reset, details/source/return.
- [ ] Request failure/reconnection and preserved data semantics.
- [ ] Focused automated validation, ordinary build and independent live evidence.
- [ ] Consolidated release decision within deadline.

## October 2 opening defect correction

The winner importer used a loose prose capture for Scratch titles absent from the
current catalog. It produced 38 malformed titles, including sentences and personal
names. Unknown titles now display `New York Scratch-Off (game name unverified)`;
no prose span is used as a fallback title. Catalog-matched titles remain unchanged.

A fresh private official import produced 1,601 rows. An exact comparison verified
that only those 38 titles changed: every ID, category, date, count, prize, position,
retailer and source field remained identical, as did all top-level metadata.
The corrected generated activity was promoted and the combined publisher validated
23,921 records across 19 states. Private evidence is in work/new_york_acceptance.
Deployment verification remains pending; this closes only the malformed-title gap,
not the broader category/date audit or release acceptance.

## Private records remain separate

The 159,140 FOIL rows cover prizes of at least $600 from September 2025 through
August 2026. Repeated rows are preserved and are not established as distinct tickets.
The latest source-screen clarification says claim date is processing date, prize
amount is full prize amount, and agent identifiers are consistent/not reassigned
but indicate current locations. Historical selling-address correspondence is not
established. Scratch game numbers and update/correction semantics remain gaps.
No private claims layer or candidate retailer join is published by this change.

Opening mailbox check found no new agency replies. Latest successful publisher
37058132001 was a push, not proof of scheduled Nebraska/Texas recovery; that
bounded maintenance checkpoint remains open. Accepted states are not reopened.

## October 2, 20:00 ET — publication verification and date gap

Publisher 37075962240 succeeded; independent public activity JSON bytes match the
committed corrected feed. No new agency mail or scheduled recovery transaction
was found in the opening check. Nebraska/Texas scheduled recovery stays pending.

The importer audit confirms all `ny-winner-` Scratch rows use the archive
publication date, although the detail card previously called it DRAW DATE.
The card now says PUBLICATION DATE and explains that selected retailer-matched
releases do not establish draw/claim dates or complete statewide ticket counts.
Changed-file analysis passed. Native verification remains pending.

Draw press releases have different semantics: `officialDate` extracts a drawing
date when matched but silently falls back to publication date otherwise. This
needs a separate explicit date-kind audit before acceptance; the Scratch label
fix does not resolve press-row ambiguity or whole-day timeline behavior.

The [official Money Dots page](https://nylottery.ny.gov/money-dots) establishes a
separate wager/draw every four minutes, excluding 03:30–04:00, and separates it
from Quick Draw EXTRA. Add Money Dots and EXTRA explicitly to reconciliation.
The [official draw index](https://nylottery.ny.gov/draw-games/) links current game
information and the winning-number route. Direct HTML retrieval returned HTTP403;
the extracted winning-number page was a JavaScript shell. Neither proves actual
tier reports unavailable. Next bounded source inspection should use the working
official API/browser route to establish reports, jurisdiction and units for each
game, rather than treating odds tables or a cached zero as actual winner counts.

## October 2, 21:00 ET — official report API unlocked

Official HTML/JavaScript retrieval works with the existing importer user agent.
The site's app bundle calls `/nyl-api/games/all/draws`; this returns draw status,
results and upcoming entries, which must not be treated as published payouts.
The winning-number page instead calls
`/drupal-api/api/v2/winning_numbers?_format=json&nid=ID&page=0`.
Private responses and the actual rendering JavaScript are saved under
work/new_york_acceptance. Each inspected report endpoint returned 25 rows:

| Product | Official page ID | Latest report date observed |
| --- | --- | --- |
| Powerball / Power Play | 21 | September 30 |
| Mega Millions | 16 | September 29 |
| LOTTO | 26 | September 30 |
| Take 5 | 36 | October 2 |
| NUMBERS | 41 | October 2 |
| Win4 | 46 | October 2 |
| Pick 10 | 56 | October 1 |
| Quick Draw / Money Dots | 400 (Money Dots UI maps 401 to 400) | October 2 |
| Millionaire for Life | 374901 | October 1 |
| Historical Cash4Life | 31 | February 21 |

Responses separate local and national winners and multiplier fields. The official
renderer explicitly labels NY Winners, but also uses national counts and state
names in particular national-game summaries. For example, Powerball has a Texas
second-prize winner in national metadata while its local second-prize count is
zero. Do not treat the whole response as NY-only or add overlapping fields.
Power Play has a separate local_multiplier_winners array. Mega Millions exposes
additional per-tier multiplier arrays; reconcile their units and overlap next.
Quick Draw includes Money Dots secondary result/prize fields; no count inferred
from a drawn prize value. Seasonal Raffle appears in the live draw index but its
report route/period still needs reconciliation. API discovery alone does not
close scope or constitute app integration. Date-kind audit remains open.

Opening mail check was empty. Scheduled publisher 37082771578 (bot bb3b223)
succeeded. Nebraska completed unchanged and Texas updated its full five-file
transaction after the repairs. Independent public activity, catalog, directory,
Texas report and refresh-status bytes all match; that recovery checkpoint closes.
The same run newly retained South Carolina after failure: its three source files
are byte-identical to 24390d7. Investigate the named importer failure next session;
accepted UI coverage and stored data remain intact. No deadline changes.

## October 2, 22:00 ET — Powerball variants validated privately

The official rendering code selects base `local_winners`, Power Play
`power_play_local_winners`, and Double Play `dp_local_winners` separately.
The legacy `local_multiplier_winners` duplicates Power Play and must not be added.
A bounded parser now validates exact tier identities/counts (9/8/9), valid dates,
draw identity and multiplier, rejects missing/duplicate/conflicting tables, and
excludes national summary metadata and location fields. It preserves prize labels,
including the source's zero jackpot placeholder; no aggregate payout is inferred.

Three focused parser tests pass. Five captured official reports parse successfully;
September 30 totals are 37,530 base, 7,603 Power Play, and 4,432 Double Play
source-reported NY winners. These are separate variant totals, not a claim map or
verified distinct-ticket aggregate. Staged output stays private under
work/new_york_acceptance/powerball-reports.json; no report app integration yet.

Remaining semantics now explicitly include NUMBERS/Win4 winning-share wording:
the official renderer states shares use a combination of $1 and $0.50 wagers.
Do not label those source counts distinct tickets. Take 5 free plays and MFL annual
prizes require literal labels. MM multiplier arrays, Quick Draw/EXTRA/Money Dots,
seasonal Raffle and press-date provenance remain bounded reconciliation tasks.

SC maintenance diagnosis ran all three importers against copies of the retained
baseline: 10,215 mapped claim groups, 30 daily grouped titles for October 1 and
35 draw reports validated. No failure reproduced and no private output promoted;
this does not identify the scheduled failure's cause or prove deployed recovery.
Await the next scheduled transaction; if it fails again, inspect that run's failing
command before changing validation. Opening publisher/mail status was unchanged.

## October 2, 23:00 ET — Mega Millions multiplier tables

Official `da`/`gr` rendering code explicitly displays `prize_winners` as NY
Winners for each built-in multiplier; `mm_national_winners` is a separate national
summary. The parser preserves the local jackpot once and eight non-jackpot tiers
for each 2X/3X/4X/5X/10X group. It rejects missing, duplicated or unknown
multipliers and unavailable counts rather than filling zeros. Source prizes
already include their multiplier and are not multiplied again. National counts,
location metadata and inferred aggregate payout are excluded.

Five parser tests pass, including invalid-table cases. Five captured official
Mega Millions reports now stage privately alongside five Powerball reports.
September 29 non-jackpot NY counts reconcile independently across tier sums
0/0/11/38/803/620/4775/10928 to 17,175; the local jackpot count is zero.
No app/public report integration yet. Remaining state-game/seasonal scope and
press-date audit continue toward the unchanged October 3, 19:00 ET checkpoint.
Opening publisher 37088445239 succeeded (push, not scheduled SC recovery); no
new agency replies. No accepted-state maintenance checkpoint was repeated.
