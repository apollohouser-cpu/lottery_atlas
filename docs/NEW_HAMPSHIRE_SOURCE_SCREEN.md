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

### September 21 reproducible inventory source

The official page's referenced frontend bundle identifies its public game-data
service, `https://prod.game-data.gambytservices.com/v1/instant-game/prizes-remaining`,
with the page's published API configuration. A read-only request returned
**586 tiers for 59 games**, with explicit UTC timestamp
`2026-09-21T03:06:59.475Z`. This resolves the instant behind the browser's
September 20 11:06 PM display without guessing its timezone. No update cadence
has yet been established. The bundle also documents that the CSV uses
`prizeAmountInDollars`, `startingCount`, `remainingCount`, and the data-service
join to printed `gameId`; ticket prices are separately expressed in cents.

`work/new_hampshire_catalog/audit.py` reproduces the saved-source checks. All
59 inventories join to retail scratch CMS records; all 586 remaining counts
are nonnegative and at most their original counts. Prices agree between API,
CMS and matched schedule rows. Advertised top prizes agree after retaining
annuity markers. The schedule has 109 distinct games (plus a duplicate mobile
presentation, which is not another dataset). Inventory game 1698, Double Match
Doubler, has no schedule row. Nine CMS start dates differ by one day from the
schedule on-sale dates: 1636, 1608, 1650, 1629, 1628, 1640, 1643, 1699 and 1651.
Do not silently normalize these disagreements or assume API activation is the
consumer on-sale date. Five games have annuity top prizes: 1621, 1657, 1658,
1687 and 1692. These findings support a future limited catalog import with
explicit date/coverage handling; no app/feed data was changed by this audit.

### September 21 limited catalog implementation

The importer now publishes **58 schedule-matched games and 575 prize tiers**.
Game 1698 is explicitly excluded because its schedule record is missing; each
game's notice discloses that omission. Nine conflicting start dates are retained
as separate CMS and schedule fields, with no normalized start date. Future
launches and expired prize claims are excluded using New Hampshire's local date;
redemption deadlines are inclusive. Price, printed identity, original top prize,
nonnegative counts and remaining/original bounds must validate before writing.

The source UTC timestamp is preserved in each inventory note. Cadence remains
unconfirmed. Five annuity prizes retain their advertised totals and payment terms;
amount-based filters use their published cash alternatives. The importer checks
that the official frontend still contains the verified annuity footnotes. Fresh
CMS metadata for game 1706 labels its top prize `200,000` without a dollar sign;
this explicit top-prize field is accepted only when it matches the API's dollar
amount. It is never derived from the game name.

The generated catalog is included in offline assets and the scheduled combined
feed. Two consecutive fresh imports produced identical catalogs. Validation
passed 106 Python, 39 Node and 64 Flutter tests, plus five bounded HTTP checks.
Flutter analysis reports 12 existing informational notices only. Local readiness
and live publication are tracked separately; this is catalog coverage, not a
complete dated claims or retailer activity dataset.

The macOS debug build also passed. New Hampshire is ready for local catalog
testing with the above limitations. Live deployment verification remains pending
until the publisher completes and its output is checked.

Publication verified September 21 after workflow 35648049856 succeeded: the
live combined catalog exactly matched the repository feed and contained all
58 New Hampshire games. New Hampshire is ready for catalog testing with its
missing-schedule and conflicting-date notices intact.
