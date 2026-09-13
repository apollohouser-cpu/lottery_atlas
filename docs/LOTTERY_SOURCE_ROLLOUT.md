# Lottery Atlas source rollout

## Acceptance rule

For each jurisdiction, record the game and tier coverage, count definition
(winning tickets, claims, or prizes remaining), period, source publication
date, official URL, update cadence, and whether retailer locations are
available. Publish a state-level total only when the component counts are
non-overlapping and the label explains exactly what is included. A source with
unknown completeness remains a partial count. County/retailer heat points
still require separately verified selling locations.

## Current queue — September 13, 2026

| Batch | Jurisdictions | Immediate work |
| --- | --- | --- |
| National | MUSL participating jurisdictions | Obtain API key and confirm `tiers` versus `topTiers`, state organization codes, game list, correction behavior, and historical draw access. Do not treat top tiers as all winners. |
| 1 | Pennsylvania, Iowa | Use the standard request for full state draw counts, Scratch-Off claim/remaining counts, retailer availability, and stable refresh mechanism. Their earlier heat-map blockers do not prevent verified aggregate counts. |
| 2 | Wisconsin, Missouri, Nebraska, Florida | Recheck existing official pages for exportable full counts; state the weekly/monthly or actual source date. |
| 3 | Oregon, Maryland, Georgia, Tennessee | Review published game-level reports and request any missing aggregate fields. |
| 4 | Remaining lottery jurisdictions | Apply the same request and importer contract, prioritizing official machine-readable feeds. |

Iowa open-records request sent September 13, 2026 to the email address listed
on the Lottery's official open-records page. It requests existing draw-game
winner counts, Scratch-Off prize counts, retailer records where public, and
the cadence/access method. Pennsylvania's formal request is pending a mailing
address required by its Department of Revenue process.

New Jersey has an official weekly partial count: 8 players won draw/Scratch-Off
prizes of at least $10,000 for August 31–September 6, published September 8.
This cannot be represented as a verified winning-ticket total. The source is
weekly and excludes smaller prizes. Its retailer data is not
complete enough to infer statewide retailer rankings. Direct scripted access
to the release index returned HTTP 403 on September 13; retain the dated
snapshot and pursue a supported machine-readable feed or permissioned access
before claiming automatic weekly updates.

The app registry contains 45 lottery jurisdictions; Alabama, Alaska, Hawaii,
Nevada, and Utah are marked as having no state lottery. The District of
Columbia is not in `allStates` and needs its own explicit jurisdiction decision
before it can enter nationwide rankings.

## Response processing

1. Save the original official URL, file/API response metadata, source date,
   license/terms, and data dictionary. Do not replace a dated source with the
   current polling time.
2. Validate game IDs, prize tiers, dates, nonnegative integer counts, and
   corrections. Reconcile subtotals against any lottery-published grand total.
3. Separate draw-date winning-ticket counts from claim-date Scratch-Off
   counts. Do not add the two under an unlabeled “total winners” number.
4. Publish a correctly scoped row through
   `data/state_winning_ticket_totals.json` and the six-hour Pages workflow.
   If all-game coverage cannot be proved, identify the subset in `coverage`.
5. Run the feed validator, Flutter tests, and macOS build. Mark a state ready
   for testing only after the displayed disclaimer matches the source gaps.

Official contact discovery: [NASPL member list](https://www.naspl.org/members)
and [media/contact directory](https://www.naspl.org/media-room). For Iowa,
the [Lottery's open-records page](https://ialottery.com/Pages/Legal/OpenRecords.aspx)
identifies its request channel. Use each lottery's own records/contact process
for submission and retain request dates and response identifiers here.
