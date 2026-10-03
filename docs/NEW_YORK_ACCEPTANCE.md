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
