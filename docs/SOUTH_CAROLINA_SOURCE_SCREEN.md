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
