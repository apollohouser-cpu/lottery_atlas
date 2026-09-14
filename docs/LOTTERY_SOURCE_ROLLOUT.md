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
On September 14, Iowa staff entered that request in the State of Iowa
NextRequest system as **#26-4068**. Its notice says an update is expected
within 10 business days. No records have been supplied yet.

New Jersey has an official weekly partial count: 8 players won draw/Scratch-Off
prizes of at least $10,000 for August 31–September 6, published September 8.
This cannot be represented as a verified winning-ticket total. The source is
weekly and excludes smaller prizes. Its retailer data is not
complete enough to infer statewide retailer rankings. Direct scripted access
to the release index returned HTTP 403 on September 13; retain the dated
snapshot and pursue a supported machine-readable feed or permissioned access
before claiming automatic weekly updates.
The standard New Jersey data inquiry was sent September 13, 2026 to the
Public Information address shown on its official weekly prize release.
The Wisconsin public-records request was sent September 13, 2026 to the
Lottery records custodian identified in the Department of Revenue's current
public-records notice.
The Missouri data inquiry was sent September 13, 2026 to its published
Communications Manager for routing to the data or records custodian.
The Nebraska written public-records request was sent September 13, 2026 to
the address on the Lottery's official public-records page.
The Florida public-records request was sent September 13, 2026 to the
Lottery's published public-records custodian email, requesting existing
electronic winner counts, retailer records, definitions, and cadence.
Florida's Open Government office acknowledged receipt September 14, 2026.
It stated the requested data are not maintained as a public API or download,
but existing-data reports can be supplied if given a date range. An August
1–31, 2026 range and request for report scope, cadence, and fee estimate was
sent the same day. No report or cost estimate has been received.
The Oregon data inquiry was sent September 13, 2026 to the Lottery's
published Public Affairs address for routing to its data or records team.
The Maryland Public Information Act request was sent September 13, 2026 to
the agency's published PIA representative for winner counts and retailer data.
The Georgia data inquiry was sent September 13, 2026 to the Lottery's
published general email for routing to the records or data team.
Georgia replied September 14 under ticket 361412 that the requested
compilation is not an existing record and raised security/equal-chance
concerns about nonpublic prize availability. Its full-coverage route remains
deferred; public subsets retain their source-specific limits.
The Tennessee data inquiry was sent September 13, 2026 to its published
Communications Director for routing to data or records staff.
Arizona's official records portal requires a verified commercial-use
attestation. Source screening is recorded separately; no request was sent.
The Arkansas data inquiry was sent September 13, 2026 to the Lottery's
published contact address for ticket counts and retailer data.
The California Public Records Act request was sent September 13, 2026 to
the Lottery's published PRA coordinator for ticket counts and retailers.
The coordinator acknowledged September 14 that it will process the request;
no records have arrived.
The Connecticut FOIA request was sent September 13, 2026 to the Lottery's
published corporation email for routing to the appropriate records custodian.
The Delaware data inquiry was sent September 13, 2026 to the Director's
published email for routing to the data or records custodian. Its public
Multi-Win Lotto counts are potentially useful only as a scoped subset.
The Illinois FOIA request was sent September 13, 2026 to its published FOIA
Officer email, with potential commercial use disclosed. Its published wins
page covers only tickets over $25,000 and some retailer fields are pending.
Illinois requested a narrower period September 14; an August 1–31, 2026
clarification was sent, with no report or fee estimate received yet.
The Indiana data and APRA-routing inquiry was sent September 13, 2026 to
the public-records email on its portal; a formal portal filing is not yet
confirmed because that form requires login.
The Louisiana data inquiry was sent September 13, 2026 to the Communications
Director in its official press kit for routing to data or records staff.
The Maine FOAA request was sent September 13, 2026 to the DAFS address
published on the Lottery contact page. Its daily instant-prize page reports
unclaimed top prizes and dollars, not complete winning-ticket counts.
The Massachusetts public-records request was sent September 13, 2026 to the
Lottery's published records email. Its official Winners query has a $600
threshold and a `totalNumberOfWinners` field; ticket identity and all-tier
coverage remain unverified, so no statewide ticket count is published.
The Minnesota written data-practices request was sent September 14, 2026 to
the Lottery's published address, seeking existing draw/Scratch counts and
public retailer joins. Its winner releases and unclaimed-prize listings do
not establish a complete all-tier winning-ticket count.
The Mississippi records-process inquiry was sent September 14, 2026 to the
email published in its records policy. A formal request must be mailed with
requestor address and phone unless the agency confirms another route.
Printed Scratch prize counts and selected winner releases do not establish
complete winning-ticket totals.
Mississippi Communications replied September 14 that the requested information
is publicly available on its general website, without identifying the
all-tier actual ticket counts or retailer joins. A follow-up requested exact
report URLs and clarification of the formal email route; no complete dataset
has been established by that reply.
Mississippi then confirmed a physical mailed formal request is required;
requestor mailing address and phone remain necessary for that filing.
The Montana data and records-routing inquiry was sent September 14, 2026 to
the Lottery's published contact address. Formal public-information requests
go through OPIR, whose New Request route required MT.gov sign-in. Published
Scratch odds are not actual winning-ticket totals; see the source screen.
The Lottery later referred OPIR access questions to the state's
`publicrecords@mt.gov`; a new-requester submission-route inquiry was sent
there September 14. Formal filing remains unconfirmed.
The North Carolina routing/data inquiry was sent September 14, 2026 to the
Lottery's published Player Service email. Its daily Scratch prize-remaining
table and weekly $5,000-plus Winners pages are scoped, useful sources, but
do not establish all-tier draw counts or a complete retailer heat map.
Player Service directed North Carolina requests to its official records
portal; no formal submission or case number is confirmed yet.

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
