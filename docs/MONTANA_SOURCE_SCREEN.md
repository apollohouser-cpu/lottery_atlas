# Montana source screen — September 14, 2026

The [Montana Lottery Scratch games](https://montanalottery.com/scratch-games/)
page publishes games and prize odds. Odds and printed prize inventories are
not actual winning-ticket or claim counts. No complete all-tier draw and
Scratch winning-ticket export, correction contract, or retailer-linked winner
dataset has been verified, so Montana is not ready for a statewide total or
retailer heat ranking.

The [Lottery contact page](https://montanalottery.com/contact/) directs
public-information requests to the state [OPIR](https://doa.mt.gov/opir/)
system. OPIR lists the Montana Lottery among its agencies. The ArkCase
“New Request” route led to an MT.gov sign-in screen on September 14, 2026;
no formal portal request was filed. The contact page also publishes the
general address `montanalottery@mt.gov`.

On September 14, 2026, a data and records-routing inquiry was sent to that
address. It asks for existing electronic all-tier draw and Scratch counts,
their definitions, dates and refresh cadence, retailer directories and public
selling-retailer references, and the supported submission route. It excludes
winner-identifying private information and discloses a public application.
Gmail confirmed “Message sent.” This inquiry is **not** a formal OPIR filing.
No substantive response or complete ticket-count dataset has been received.

Later September 14: The Lottery replied that it does not manage OPIR and
directed portal access issues to `publicrecords@mt.gov`, suggesting an Okta
password reset. No existing Okta account is known. An inquiry to that official
records address asked how a new requester can create an account or use another
accepted filing route, and whether email is accepted. Gmail confirmed it was
sent. This is still not a filed formal request; no ticket-count data arrived.

Later September 14: The OPIR help desk replied that a new requester should
visit `https://login.mt.gov`, scroll to “Don't have an account? Sign up,” and
follow the account-creation instructions. It attached instructions.

On September 16, 2026, the MT.gov account was created and verified, and a
formal request was submitted through OPIR to `LOT - Lottery`. It requests
September 1, 2025 through August 31, 2026 all-tier draw and Scratch records,
retailer records and joins, definitions, cadence, corrections and any existing
recurring source, with a fallback to the most recent complete month. Delivery
is through the web portal; the requester asked for an estimate before any paid
processing. The portal displayed a successful-submission confirmation. Its
confirmation email arrived at 2:58 a.m. Eastern on September 16 and assigned
case `26-PIR-2200` (queue: Intake). No responsive dataset has arrived.
At 11:00 a.m. Eastern, OPIR sent a formal acknowledgment letter confirming
receipt under that same case number. It says OPIR will review the request,
clarify or deny if necessary, or provide records, and will supply a cost
estimate as soon as possible if staff time is billable. The letter includes
general timing guidance, not a committed delivery date for this request.

## September 20, 2026 full listing audit

Fetched all 11 pages of the official Scratch catalog using its published
`e-page-eeedf9c` pagination links. The pages contain 53 unique CMS listings
and 1,032 rows under `WIN / PRIZE / ODDS`. Each listing has one explicit
price taxonomy; every listing has a prize table. These are prize structures
and odds, not remaining inventory, dated winning-ticket counts or claims.
No remaining-count series was established in this audit.

Special prizes require semantic handling. Can-Am lists a vehicle valued at
$53,583, a separate $50,000 cash prize, and a second-chance vehicle row with
`1:0.00` odds. Selecting the largest numeric prize would wrongly flatten
vehicle and second-chance semantics into a cash top prize. Free-ticket rows
use the label `Ticket` and must not be turned into cash. Repeated cash amounts
can represent different winning combinations rather than duplicate rows.

CMS post IDs identify website entries, not printed lottery game numbers.
Some official game-spec image filenames include apparent game numbers, but
those have not yet been independently matched to printed ticket identities
for all 53 entries. Do not manufacture an identity from a CMS ID or assume
all published listings are currently on sale. Verify game identities and
closing/claim notices before publication; remaining counts should stay unknown
unless a separate official inventory source is verified.

Read-only audit files live under ignored `work/montana_catalog/`: all 11
HTML pages, `audit.py` and `audit.json`. No Montana public catalog or activity
feed changed during this pass. OPIR case 26-PIR-2200 remains pending.

### September 25 release notification — documents not yet inspected

Gmail message 1a0d91d1e84517e3 at 15:09 UTC marks 26-PIR-2200 complete and says
released documents are available. The official Open Documents link redirects to
MT.gov sign-in; no released file is attached to the notification. This supersedes
pending-request status but is not yet an inspectable data delivery.
A standard no-fee delivery follow-up was sent to the notification's assigned
contact, celina.clift@mt.gov, requesting the already released files by attachment
or a direct download without a new account. Sent message 1a0d94e847b234fe.
No additional assembly or fees were authorized. Monitor that delivery reply;
Montana implementation remains queued while Kentucky stays active.
