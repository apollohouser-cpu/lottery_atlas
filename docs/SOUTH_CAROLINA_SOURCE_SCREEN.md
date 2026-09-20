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
