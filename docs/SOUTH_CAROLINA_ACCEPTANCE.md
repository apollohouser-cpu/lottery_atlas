# South Carolina supported-coverage acceptance

Activated September 30, 2026 at 17:03 ET. Release decision due October 3 at
17:03 ET (72 hours). Scope reconciled September 30, before October 1 at 17:03 ET.
Not yet ready for integrated native testing or accepted. Agency records are a
separate outcome; no fees or complete-records prerequisite.

## Per-game scope and gaps

Official pages inspected September 30, 2026. These statewide draw reports are
separate from retailer-linked claimed prizes. Never distribute their totals to
stores or counties, or add them to claims as distinct tickets.

| Game | Verified public scope | Implementation gap / limit |
| --- | --- | --- |
| [Powerball](https://www.sceducationlottery.com/Games/Powerball) | SC tier winners, separate base, Power Play and Double Play columns | Existing claim filter; add statewide report with variants kept separate. September 28 total 10,746 includes all three columns. |
| [Mega Millions](https://www.sceducationlottery.com/Games/MegaMillions) | SC tier counts, prize ranges; September 29 total 10,193 | Existing claim filter; add statewide report. Prize ranges do not support an exact total payout. |
| [Powerball Xs & Os](https://www.sceducationlottery.com/Games/PowerballXO) | SC five-tier report; September 27 total 1,773 | Missing game/filter. Existing import labels two `Xs and Os` groups as Scratch: correct classification and regenerate before release. Preserve source-specific tier amounts rather than assuming current advertised prizes apply historically. |
| [Palmetto Cash 5](https://www.sceducationlottery.com/Games/PalmettoCash5) | Four-tier counts; September 29 total 6,022 | Existing claim filter; add statewide report. Page's multiplier description and displayed tier amounts differ: retain reported values, do not infer multiplied payout. |
| [Pick 3 Plus FIREBALL](https://www.sceducationlottery.com/Games/Pick3) | Midday/evening play-type counts, base and FIREBALL columns | Existing Pick 3 claim filter; preserve session and variant in statewide report. Counts are source-reported winners, not deduplicated tickets. |
| [Pick 4 Plus FIREBALL](https://www.sceducationlottery.com/Games/Pick4) | Midday/evening play-type counts, base and FIREBALL columns | Existing Pick 4 claim filter; same separation and limitations as Pick 3. |
| [CASH POP](https://www.sceducationlottery.com/Games/CashPOP) | Session winner totals and payouts; September 30 midday 2,242 / $102,490 | Existing claim filter; add statewide session report. Published odds tables are not actual tier winner counts. |
| [Scratch](https://www.sceducationlottery.com/Games/PrizesRemaining) | Catalog and estimated remaining prizes; qualifying claims in Winners Report | Verify catalog feed/fallback currency and title joins. Remaining inventory is not store inventory, claims or probability of a store win. |

The app's current “all six” draw-game wording is stale. Public availability is
not the same as imported coverage: no SC statewide draw-report importer was found
in this audit. Report integration is a named supported-draw gap, not a dependency
on the pending agency response.

## Existing claims snapshot and semantics

`data/south_carolina_current_winner_activity.generated.json`, source date
September 30: 10,019 mapped groups / 10,330 reported claims, July 6–September 29.
Source limits to prizes at least $500 and a rolling three-month report;
1,072 claims excluded for lack of an exact Census address geocode.
These are partial counts, never complete statewide totals.

Current group counts: Powerball 59; Mega Millions 136; Palmetto Cash 5 957;
Pick 4 2,684; Pick 3 465; CASH POP 436; currently classified Scratch 5,282,
including the two misclassified Xs and Os groups. Counts describe this snapshot.
The importer groups identical date/prize/game/location fields and retains the
number of report rows; no independent ticket identity is established.

The schema's `drawDate` stores the source **claim date**, with UTC noon used for
date storage. Audit map/timeline/details to ensure they show claim-day precision,
not a draw time or an hourly event. Missing mapped records can also reflect
geocode exclusions; the current coverage-screen claim that absence necessarily
means no qualifying source record must be corrected.

SC-specific retailer feed has no default remote URL and a starter fallback;
verify its route and disclosures against the shared live activity feed. Do not
present starter records as a complete current retailer directory.

## Release checklist

- [x] National/state draw games and Scratch inventoried with official sources.
- [x] Public available data separated from complete agency-records outcome.
- [ ] Correct Xs and Os classification/filter, coverage wording and date semantics.
- [ ] Integrate available statewide draw reports with source, date/session, tiers,
      cadence and limitations; validate totals and preserve prior data on failure.
- [ ] Verify Scratch catalog/fallback and retailer route limitations.
- [ ] Test state/county/game/prize/date filtering, reset, empty states and sources.
- [ ] Observe native layouts/interactions at 800×632 and 1280×900 logical sizes,
      including national and state draws, Scratch and directory/detail routes.
- [ ] Verify offline/cache recovery and reconnection without fabricated freshness.
- [ ] Appropriate automated checks, build and independent live-file verification.
- [ ] Record supported-coverage release decision by the deadline.

September 30 opening check: clean repository, latest publisher 36759391265
successful, no new agency reply beyond the already-handled Texas clarification.
No repeated Kentucky/Texas acceptance tests were run. Pending SC narrowed request
and historical evidence remain in SOUTH_CAROLINA_SOURCE_SCREEN.md.


## September 30 classification and date corrections

Implemented Xs and Os as a distinct draw filter/card using the report's exact
`Xs and Os` title. Corrected importer classification and only the two affected
snapshot game codes; claim counts, coordinates, dates and source freshness are
unchanged. Coverage now lists seven draw games and explains geocode exclusions
instead of asserting that absent mapped data means absent source claims.

Current `sc-winners-` detail records show CLAIM DATE and explain missing draw/time
information. South Carolina's timeline uses the existing whole-day source mode,
preventing synthetic noon timestamps from becoming hourly activity.
Five focused classification/calendar tests pass; changed classification/screens
analyze cleanly. Native verification and independently published data verification
remain pending. Statewide draw-report integration remains the next implementation
gap. No release decision or deadline change.
