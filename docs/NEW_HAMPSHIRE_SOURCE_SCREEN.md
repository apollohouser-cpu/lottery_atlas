# New Hampshire source screen — September 14, 2026

The [official current Scratch game schedule](https://www.nhlottery.com/Games/Scratch-Tickets/Current-Scratch-Game-Schedule)
lists game number, price, on-sale date, end/close date, and prize expiration
for tickets whose unclaimed prizes have not expired. It is a game catalog,
not a count of actually won or claimed tickets. The [Prizes Remaining](https://www.nhlottery.com/prizes/prizes-remaining)
page is a filtered public view, but the screened response displayed zero
results; its complete game/tier coverage and machine-readable access were
not established.

The [winning-numbers page](https://nhlottery.com/winning/winning-numbers)
publishes results for checking tickets and says official validation controls
winner verification. Winning numbers alone do not give winning-ticket counts
by New Hampshire sales, game and prize tier. The [retailer finder](https://www.nhlottery.com/find-retailer)
is a city/ZIP search; a complete stable-ID statewide export and public
winning-ticket retailer joins were not established.

No complete all-tier national, state-draw and Scratch claim dataset or
retailer-linked heat-map feed was verified in this initial screen. The
[official contact page](https://www.nhlottery.com/contact-us) lists
`webmaster@lottery.nh.gov` for Lottery headquarters. A routing and data
inquiry was sent there September 14 asking for existing all-tier counts,
Scratch claims or remaining, retailer directory and public winner joins,
source definitions, cadence, fees, and the formal records route. Gmail
confirmed “Message sent.” The recipient's role as records custodian is not
established; no complete records have arrived. New Hampshire is not ready
for full-state testing.

## September 21 browser and source audit

The prizes page's initial HTML still says zero results, but its hydrated browser
view displays **59 games** after loading/filtering, including explicit zero
remaining top prizes. It reports **September 20, 2026, 11:06 PM** as the last
update; no timezone was established. Its footnotes distinguish annuity totals
from cash alternatives: $1 million over 25 years / $700,000 cash; $2 million
over 30 years / $1,350,000 cash; $3 million over 30 years / $1,750,000 cash.
Tickets may remain on sale after all top prizes are claimed. These are inventory
figures, not dated winning-ticket or retailer activity counts.

The official HTML embeds CMS metadata for 95 scratch games and data-service
metadata for 78 retail instant games; only 59 CMS scratch entries join to the
retail identities. Do not treat either larger set as a reconciled current
catalog. The separate current schedule supplies printed IDs, prices and
sale/close/expiration dates, including ended but claimable games; it requires
an explicit identity/date reconciliation before import. Example: game 1670 has
a malformed close-date string `7/22026`, which must not be silently guessed.
Source files are retained under ignored `work/new_hampshire_catalog/`.

A CSV export control is visible, but this audit did not capture a usable export.
The next step is to establish a reproducible inventory source and reconcile it
with the schedule and advertised original top prizes. No New Hampshire catalog
has been imported or declared ready for testing in this pass.
