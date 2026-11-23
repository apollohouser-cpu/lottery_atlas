# Connecticut supported-coverage acceptance

Status: ACTIVE, unaccepted. Activated November22,2026 at15:36EST (20:36UTC).
Scope deadline: November23 at15:36EST. Release-decision deadline: November27
at15:36EST (20:36UTC), fresh120elapsed hours, no extension.

## Opening evidence and scope reconciliation

Chosen after Delaware acceptance because a validated scheduled Scratch catalog
already exists while draw/report integration remains substantial. The November21
local catalog contains82 games; its retrieval timestamp is not a new source date.
Preserve game1725 exclusion, annuity/cash validation, ended-but-claimable labels,
per-game inventory dates and unknown/TBD deadlines described in the source screen.

The official homepage inspected November22 redirects from ctlottery.org to
https://ctlottery.com/ and exposes results/source routes for Powerball and separate
Double Play, Powerball Xs & Os, Mega Millions, Millionaire for Life, Lotto!, Keno,
Cash5, and Play3/Play4 DAY/NIGHT. Payout controls are visible for several games;
button presence is not proof of audited count semantics or a working importer.
Play3/Play4 detail routes were opened. Wild Ball/combination fields need explicit
classification; no exact event times or counts are inferred from displayed digits.
Full scope remains pending reconciliation by the scope deadline, including
historical/ended products, add-ons, rules and report units.

Opening source capture and hash: ignored work/connecticut_acceptance_20261122.
No capture has been promoted as validated app data. Current scratch importer:
tooling/import_connecticut_scratch_catalog.py. No dedicated Connecticut draw
importer was found in the opening tooling inventory.

## Required acceptance work

- [x] Fix full product/game scope and supported/unavailable matrix within24hours.
- [ ] Audit structured results, prize/count definitions, dates, sessions and rules.
- [ ] Integrate validated supported draws/reports with source links and disclosures.
- [ ] Reconcile Scratch detail/tier presentation and retained source exclusions.
- [ ] Validate bundle/cache/remote adoption and byte/date retention on failure.
- [ ] Verify compact/landscape/enlarged-text navigation, details and source returns.
- [ ] Verify integrated physical offline behavior; automated tests alone do not close it.
- [ ] Run proportional tests, build, publish and independently verify live bytes.
- [ ] Record evidenced acceptance or concrete unfinished gates by fixed deadline.

## Boundaries and comparison benchmarks

No verified complete retailer-linked claims or geographic activity is established.
The September23 agency response identifies public sources but no existing records
in the requested form linking winners to selling retailers, and no maintained
retailer coordinates. Missing agency records do not block honest supported release.
Do not invent map points, counts, store inventory or zero-activity conclusions.
Texas is the working-coverage comparison; New York is separately the12-month
breadth comparison. Connecticut does not yet match either benchmark. No full-year
history, all-tier statewide claims or complete geographic coverage is claimed.
Agency correspondence remains with its separate automation; no duplicate requests,
fees or new human attestations. Mobile beta gates remain independently open.

## November22 — reproducible structured source inventory

Added tooling/connecticut_source_inventory.py to extract the single embedded
nine-product draw inventory from captured Next.js stream chunks, rejecting
missing/duplicate/changed product sets, ambiguous inventories and unexpected
source routes. Four focused tests pass; the saved official homepage extracts
successfully into private draw_inventory.json. This is reconnaissance tooling,
not a validated result/count importer or public feed.

Observed product identifiers: powerball, xsandos, megamillions, mfl, lotto,
keno, cash5, play3, play4. Play3/Play4 explicitly label the additional digit
Wild Ball, not Fireball; DAY and NIGHT have distinct dates in the same capture.
Generic payout payloads put that digit in fields named powerPlayMultiplier and
multiplier: those keys must not be interpreted as actual prize multipliers.
Cash5 advertises Kicker, requiring separate rule reconciliation. Double Play
is nested under Powerball; its display date is empty and React references remain
unresolved, so do not invent an independent date from that display object.
Xs & Os numbers require verified team mapping. Keno includes a game number and
bonus but no payout rows in this snapshot; this is not proof of zero winners.
The current matrix remains provisional until rules, report units and historical
products are reconciled. Scope and release deadlines are unchanged.

## Supported scope fixed — November22,2026

Scope fixed before November23 15:36EST. Release remains November27 15:36EST.
All nine current draw detail pages were captured successfully and hashed privately;
visible schedules, prize/rule sections and game-specific official PDF links were
inspected. This fixes the release scope, not acceptance of parsers or completeness.

| Product | Bounded release scope | Required distinctions / unavailable coverage |
| --- | --- | --- |
| Powerball / Power Play | Dated results, separate add-on label, audited prize/rule information and source links | Multiplier is not a winning-ticket count; jackpot advertisement is not payout |
| Double Play | Separate dated result group and prize/rule source | Resolve explicit parent draw association; do not borrow an undated display object's date silently |
| Powerball Xs & Os | Dated team results, prize/rule information and promotion source | Verify numeric team mapping before display; promotion awards separate |
| Mega Millions | Dated results and multiplier-aware prize/rule information | Distinguish advertised base amounts from applicable multipliers and actual counts |
| Millionaire for Life | Dated results, literal life-prize labels and rules | Annual amount is not lifetime total or cash payout |
| Lotto! | Dated results, prize/rule information and sources | Preserve variable-prize qualifications |
| Cash5 / Kicker | Dated base results; separately labeled Kicker rules/prizes | Kicker is a player-selected additional number, not an independent drawn bonus; payouts may vary |
| Play3 DAY/NIGHT | Separate latest dated sessions, Wild Ball, wager-specific rules/prize tables | Preserve digit order and leading zeroes; generic multiplier fields actually carry Wild Ball |
| Play4 DAY/NIGHT | Separate latest dated sessions, Wild Ball, wager-specific rules/prize tables | Preserve digit order and leading zeroes; do not combine session dates |
| Keno / Bonus | Bounded dated/game-numbered snapshot, bonus and spot/wager rules | Not a live four-minute service; do not synthesize draw time or ticket counts |
| Scratch | Existing validated catalog plus audited available tier/detail presentation, dates, closeouts and sources | Keep1725 exclusion, annuity/cash checks, TBD omissions; remaining prizes are not retailer stock |
| Fast Play | Explicit bounded rules/source entry from official rules index | Current product inventory/results not established; do not infer active games from retained general rules |
| Historical/ended games | Explicit historical coverage limitation and official source routes where verified | No complete archive or current recurring schedule invented for old products |
| Second Chance / promotions | Separate official routes and scoped explanation | Do not count entries, promotional prizes or sports betting as retail lottery draw activity |

Dated statewide payout reports are included where their source fields and units
validate. Otherwise show a specific unavailable-count explanation alongside the
validated results and prize/rule table; a static prize chart never becomes an
actual winner report. Integration must preserve exact sources, observed dates,
source-versus-retrieval distinctions, and last-good bytes on failure. No full-year
history, complete all-tier retailer joins or new geographic layer is in scope.

Next implementation work: validated result normalization and source reconciliation,
then payout/report endpoint and units audit, bundle/cache/UI integration, and the
existing bounded native/publication acceptance checklist. No agency wait or paid
record request is added as a release prerequisite.


## November22 — initial validated result normalization

Implemented tooling/connecticut_draw_results.py for Powerball, Mega Millions,
Millionaire for Life, Lotto!, Cash5, Keno and separate Play3/Play4 DAY/NIGHT
snapshots. Number pools were checked against retained official detail-page text.
The private homepage replay produces10 result rows, preserving each session's
explicit source date, ordered digits/zeroes, Wild Ball, Power Play and Keno
identity/bonus. Non-Keno rows reconcile visible results with their explicit
API payload dates and numbers; overloaded Wild Ball fields never become payout
multipliers. Missing dates/sessions, future dates, invalid ranges, duplicate
pool numbers and source/payload disagreement fail closed.

Nine focused inventory/result tests pass. Private results_candidate.json remains
unpublished and unintegrated; no current freshness or native display is claimed.
Double Play reference/date resolution and Xs & Os team mapping remain separate
unfinished result requirements. Actual payout reports/units, rules integration,
production packaging and UI/cache/native checks remain open. This adds no claims,
retailer activity, winner counts or full-history coverage; deadline unchanged.


## November22 — Double Play date/reference validation

Double Play now has a separate normalizer using the explicit date on the API
draw that contains its nested result. A missing display date is not replaced by
retrieval time. The only supported Flight reference must target the same product,
display slot and root as the parent; arbitrary/cross-product references fail.
Inline arrays, bonus numbers, ranges and conflicting explicit dates are checked.
Power Play is never copied onto Double Play. Four new focused tests cover dated
association, bad references, inline mismatch and missing/conflicting data;13
Connecticut tests pass overall. Private opening replay now produces11 rows.
Xs & Os team mapping, actual reports/units, production integration and native
acceptance remain open. No public feed changed; deadline remains November27.
