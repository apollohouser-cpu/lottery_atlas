# South Carolina source screen — September 15, 2026

The South Carolina Education Lottery's official [Winners Report](https://www.sceducationlottery.com/Games/WinnersReport)
publishes claimed draw-game and Scratch-Off tickets with claim date, prize
amount, game, county, retailer name, retailer address and city. SCEL describes
the report as prizes of $500 or more from the past three months, so it is a
useful retailer-linked activity feed but not a complete all-tier winning-ticket
total. The page showed a September 14, 2026 update during this review.

The official [Prizes Remaining](https://www.sceducationlottery.com/Games/PrizesRemaining)
page and individual Scratch-Off game pages publish tier-level prize inventory.
SCEL warns that these are estimates and do not guarantee that a prize remains
available because tickets may already be sold or claimed. They cannot be
substituted for actual validated winning-ticket counts. The statewide retailer
finder also does not establish a published machine-readable active-retailer
directory with stable location identifiers.

SCEL's official [contact page](https://www.sceducationlottery.com/Lottery/Contact)
specifically routes Freedom of Information Act requests through its contact
form and links the agency's [FOIA fee schedule](https://www.sceducationlottery.com/documents/lottery/FOIAFeeSchedule.pdf).
A focused August 1–31, 2026 request was submitted through that form on
September 16, 2026 for all-tier
draw and Scratch-Off records, a complete retailer directory, retailer joins,
definitions, cadence and corrections. It excludes claimant personal
information in light of SCEL's published lottery-prize-winner information
exemption. The website confirmed receipt and said the Lottery would review the
information and respond within 48 business hours. No fees were authorized.

South Carolina can show the public $500-plus activity with that limitation and
the source update time. It is not ready for full-state testing until the request
is submitted and responsive records establish all-tier coverage or the app is
explicitly tested as a partial-coverage state.

### September 20 source timeout recovery

Scheduled run 35529179544 stopped at a Winners Report connection timeout;
the subsequent run succeeded. The importer now uses a bounded HTTP helper:
four attempts, a 30-second whole-request limit per attempt, and short increasing
retry delays. Only connection/HTTP transport errors, timeouts and temporary
HTTP statuses are retried. Permanent HTTP errors and malformed response encoding
fail immediately. Exhausted retries still stop publication; no dates or claims
are manufactured, and source parsing/geocoding validation remains unchanged.

Five standalone local-HTTP regression checks exercise recovery after HTTP 503,
no retry on 404, exhausted retry bounds, response timeout and invalid UTF-8.
These checks also run in the publisher before imports and need no package
resolution. This change improves availability without expanding data coverage.

### September 24 Census service failure

Scheduled publisher 35939079754 stopped when the Census batch geocoder returned
HTTP 502 during the South Carolina Winners Report import. The failure was in
geocoding transport, not evidence of changed claim data. All four live feeds
still matched the last successful publication, commit 658664c; no incomplete
refresh was deployed. A retry of the failed job was accepted by GitHub on
September 24. Its outcome and all four live feeds must be checked before calling
this recovered. The existing bounded GET helper does not cover this multipart
Census POST; adding bounded retries there remains a reliability follow-up.
No user access, fees, or source-definition changes are required for this retry.

The retry (attempt 2) also failed with Census HTTP 502, this time while importing
Kentucky's retailer directory, before reaching South Carolina. This identifies
a shared external geocoding outage rather than a South Carolina report change.
Both Census multipart lookups now use four bounded attempts with a 120-second
whole-request timeout per attempt and short increasing delays. Temporary HTTP
statuses and transport timeouts may retry; permanent HTTP errors and invalid
UTF-8 fail without retry. Exhaustion still prevents publication. No fallback
coordinates, claim counts, or refreshed source dates are invented.

Validation: all 55 Node tests and six standalone Dart HTTP checks passed,
including multipart body replay, HTTP 502 recovery, permanent errors, exhausted
retries, stalled response bodies, and malformed encoding. Analysis of changed
Dart files reports no issues. All four live feeds still match 658664c. The next
publisher must succeed and its live output must be checked before declaring
recovery; local retry tests alone do not establish service recovery.

### September 24 verified publishing recovery

Publisher 35945318934 attempt 2 succeeded at 03:21 UTC. All four live JSON
feeds were independently checked and match published commit 55b9631. This
resolves the refresh interruption described above; the bounded Census retry
change is included in the successful run. Existing coverage limitations and
pending agency definitions remain unchanged. No user intervention was needed.

## September 24 records response

David Ross replied at 15:31 UTC that SCEL does not maintain the consolidated
report/dataset requested and will not create a new compilation. He invited a
narrower request identifying existing records or maintained fields and offered
assistance determining availability. This is a refusal of the requested form
and detail, not evidence that every underlying record is unavailable. No data
was delivered and no paid work is authorized. Next request should seek existing
report names/field definitions or separate existing exports without compilation;
public-source app coverage continues independently.

### September 25 correspondence follow-through

Sent September 25 narrowed request 1a0da387f9504df7 to David Ross and the original FOIA mailbox. Requested separate existing retailer reports, August 2026 game/prize summaries and existing definitions in their maintained formats; asked for available report names if necessary. Removed any need for custom consolidation, ticket identifiers or new retailer joins. No fees or paid work authorized.


## September 30 supported-scope reconciliation

See [SOUTH_CAROLINA_ACCEPTANCE.md](SOUTH_CAROLINA_ACCEPTANCE.md) for the current
per-game inventory and release checklist. Official pages expose statewide draw
reports for national and state games, including Powerball Xs & Os; these are
separate from retailer-linked $500-plus claims. The current importer wrongly
classifies two `Xs and Os` groups as Scratch. Correction and draw-report
integration are active work, with the October 3 at 17:03 ET deadline unchanged.
The narrowed records request remains pending and does not block app completion.

## October 2 no-fee records delivery — private audit pending

Agency supplied a 248,957-byte retailer workbook and a 20,973,781-byte daily
sales/validation CSV at no charge. The email describes daily retailer/game sales
and validation amounts and counts, warns that Pick 3/Pick 4 counts are affected
by 50-cent wagers, and identifies claims-center cashes as “Pseudo Outlet.”
Receipt and agency description are verified; attachment contents, date coverage,
row counts and semantics are not yet audited. Do not treat validations as selling
retailer claims, infer distinct tickets, or publish new map positions from receipt.

Sent receipt acknowledgment and a bounded no-fee clarification asking whether
validation rows identify cashing/validation or original selling locations, plus
existing date/count/correction/prize-tier definitions. Did not confirm that the
request is fully satisfied. No fees or custom compilation authorized. Supported
app acceptance remains closed; any new layer requires a separate private audit.

### October 2, 22:00 ET bounded refresh diagnosis

All three importers succeeded privately against copies of retained baselines:
10,215 mapped claim groups, 30 daily titles for October 1 and 35 draw reports.
Evidence is ignored under work/sc_refresh_oct2. Nothing was promoted, and this
successful reproduction attempt does not establish the scheduled failure's cause.
Verify the next scheduled transaction; if it fails again, obtain the failing command
before making parser changes. Prior public data and accepted UI coverage remain.

### October 3, 04:00 ET scheduled recovery verified

Publisher 37104043949/ac2b8ac completed the three-file SC transaction successfully.
Independent public activity, SC draw reports, daily Scratch and refresh-status
bytes match. The October 2 retention checkpoint is closed. No validation changes
or private-probe promotion were needed; the original transient cause was not proven.

## October 7, 22:02 ET — validation-record definitions

The agency's October 7 reply states that validation data identifies only the
retailer that validated/cashed the ticket, excludes cancelled tickets, cannot
include prize tiers, and uses tickets as its units. The earlier warning that
50-cent Pick 3/Pick 4 wagers affect reported counts remains in force; the latest
unit description does not establish an exact distinct-ticket conversion.
Cashing activity must not be relabeled as original selling-retailer wins.
Cancellation exclusion does not resolve every reversal/correction rule or the
report's date semantics.

Checked the full conversation and confirmed the October 2 acknowledgment in
Sent before replying. A new bounded acknowledgment of these definitions was
Sent-confirmed, retaining private-audit and completeness reservations. No extra
compilation, report, fee or paid work was requested. No new attachment or
promised follow-up date was supplied. Review the existing delivered files before
raising any specific remaining existing-document question; do not resend either
acknowledgment. Private check evidence is retained in work/agency_email_checks.
No public data layer or accepted supported-app scope changed.

## October 8 existing-record limitation clarified

The agency states that documents containing all requested details do not exist
and that it created the previously delivered partial report to help. This is
the agency's description of its records and response, not an independent legal
conclusion. No new attachment, fee or follow-up date was supplied. Verified the
conversation and October 7 Sent acknowledgment; no redundant reply was sent.
The clarification exchange is complete for now. Privately audit the delivered
records using the known cashing-retailer, cancelled-ticket and Pick 3/4 unit
limitations; do not infer missing tiers, dates, correction rules or selling
locations. No further compilation was requested, and accepted supported-app
coverage and public data remain unchanged.
