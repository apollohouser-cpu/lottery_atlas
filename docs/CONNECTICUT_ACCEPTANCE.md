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

- [ ] Fix full product/game scope and supported/unavailable matrix within24hours.
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
