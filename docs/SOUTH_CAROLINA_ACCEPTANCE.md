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
| [Scratch daily claims](https://www.sceducationlottery.com/Games/DailyInstantWinners) | Daily statewide claimed-prize tiers, distinct from the rolling $500-plus retailer report | Existing Scratch screen uses this source, not remaining inventory. Restore reliable refresh; preserve source day and grouped duplicate-title semantics. |
| [Scratch remaining inventory](https://www.sceducationlottery.com/Games/PrizesRemaining) | Estimated remaining prizes | Separate official source, not the existing daily-claims feed; do not label daily claims as remaining prizes. |

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


## September 30 publication and fallback audit (20:00 ET session)

Publisher 36789068922 succeeded for 67b9213. Independently fetched the public
GitHub Pages activity.json: all 10,019 local SC activity objects match by ID and
full object value, including both Xs and Os entries as state-draw. This closes
that publication check; native interaction verification is still pending.

Correction to the initial scope description: the SC-specific Scratch screen
loads **DailyInstantWinners**, not PrizesRemaining. Its built-in snapshot is dated
August 17, 2026; the screen labels built-in/saved/published status and snapshot
date, and explicitly describes daily claimed tiers. The configured external
south-carolina-scratch-offs.json endpoint returned HTTP 403 in this session.
There is no matching daily-Scratch publisher in the repository. This is a named
refresh gap: wire the existing daily-claims schema into the maintained publishing
pipeline, preserving the actual source day and prior valid data on failure.
Do not call the old snapshot current or infer inventory from claimed counts.
The official daily source is available; the web-reader copy inspected was dated
September 27 (updated September 28), so do not treat its crawl as today's data.

Retailer fallback audit: no default remote retailer feed is configured. Built-in
records carry cityLevelPlacement=true and are explicitly a starter subset; the
list says it is not every retailer. The repository has no source update date,
and its phrase “recently reported” is misleading for retained starter records.
Map markers use these city coordinates, although details disclose city-level
placement. Before acceptance, prevent these from being represented as precise
store positions or used as precise nearby distances; use verified shared-feed
locations or an explicit non-map address list. No invented replacement locations.

No new agency response was found. Statewide draw-report integration remains
open, with the original October 3 at 17:03 ET release decision unchanged.


## September 30 retailer-position correction (21:00 ET session)

The retained retailer subset is mixed: some entries have cityLevelPlacement=true,
while its later address-level entries are marked false. This clarifies the prior
fallback audit; not every starter row is approximate. Added a shared mappable
subset that excludes city-level positions from map pins and nearby-distance
results. The address list remains intact, and map-action counts use only eligible
positions. Saved approximate-retailer navigation opens details without a store
zoom. Native verification and provenance review of retained address-level entries
remain pending; this change does not certify every existing coordinate.

Two regressions cover exclusion of approximate starter records and mixed-feed
retention of address rows. Publisher 36797307567 was successful at the opening
check; no new agency reply. Scratch refresh and statewide draw integration remain
open. No change to the October 3 release-decision deadline.

## September 30 daily Scratch refresh implementation (22:00 ET session)

Added a maintained official DailyInstantWinners importer and a baseline for
September 29 claims, published by SCEL September 30 at 10:00:03 EDT: 31 grouped
titles. Payout arithmetic, table boundaries, integer values, source dates and
regressing claim days are validated. Duplicate source titles retain summed tier
counts and the number of grouped source entries. Output is written only after
validation. This snapshot is statewide daily claims, not remaining inventory,
retailer totals or a current sales catalog.

The existing South Carolina transaction now includes this output, preserving its
previous file alongside the rolling claims file if either importer fails. The
publisher stages south_carolina_daily_scratch.json; the app uses that GitHub Pages
URL instead of the HTTP403 endpoint and exposes claim day separately from source
publication date. Cached failures retain both dates. Five parser regressions and
a Flutter network-failure/cache regression pass. Analysis reports two existing
string-interpolation infos in the Scratch screen. Live publication and native
checks remain pending; statewide draw reports remain the next implementation gap.

## September 30 daily feed verification and draw parser (23:00 ET session)

Publisher 36804028771 succeeded for 1477dc6. Independently fetched the public
south_carolina_daily_scratch.json and confirmed a byte-for-byte match to the
committed snapshot. Native Scratch screen verification remains pending.

Staged a validated Mega Millions draw-report importer and five official recent
draw tables in data/south_carolina_draw_reports.generated.json. September 29
reconciles to 10,193 statewide winners. Each report requires nine distinct tiers,
exact columns, integer nonnegative counts, a matching SC scope date and a
reconciled total; duplicate/unordered dates and date regression are rejected.
Prize ranges are retained verbatim and reportedPayout/sourcePublicationDate are
null, rather than inventing totals or treating retrieval as source publication.
Six regressions pass, including count/date mismatch and duplicate rejection.

This is staged data, not an app report release: remaining national/state games,
the report view, transactional refresh and public report publication still need
integration. The existing retailer feed remains separate and unchanged. No new
agency response, state acceptance or deadline change.

## October 1 additional draw parsers (00:00 ET session)

Extended staged reports to Powerball Xs & Os and Palmetto Cash 5: 12 reports
across three games. Latest counts reconcile to 1,773 for Xs & Os September 27
and 6,911 for Palmetto September 30. Exact tier names, columns, totals, date order
and per-game non-regression are checked. Xs & Os requires a matching SC scope
date; its historical tier values are preserved. Palmetto's Winners and Total
columns must agree and are never added together; payout remains unknown.
Eight parser regressions pass. An initial strict span matcher rejected the Xs &
Os page's class attribute without overwriting prior data; it now accepts span
attributes while retaining date/scope validation.

Regular Powerball variants, Pick 3/4 FIREBALL sessions and CASH POP remain to be
implemented, followed by app/report publication integration and native checks.
Publisher 36808635720 succeeded at the opening check, with no new agency reply.
The staged reports are not yet exposed as a completed app feature. Deadline
remains October 3 at 17:03 ET.
