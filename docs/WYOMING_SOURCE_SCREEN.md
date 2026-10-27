# Wyoming source screen — September 15, 2026

Wyoming is **not ready for complete verified heat-map testing**.

- The official winner list is limited to prizes of $100 or more, so it cannot
  establish all-tier winning-ticket totals.
- WyoLotto currently lists Powerball, Mega Millions, Cowboy Draw, Millionaire
  for Life, 2by2 and Keno. No Scratch product was identified in the official
  game catalog.
- The official retailer finder is interactive; a complete current export with
  stable retailer identifiers and winner joins has not been verified.

The website's earlier Public Records link returned a 404. A request was sent
September 15 to the published media contact, who supplied the corrected
[official public-records form](https://faq.wyolotto.com/support/tickets/new?ticket_form=request_for_public_record).
The public-records request was submitted successfully on September 16, 2026;
the portal confirmed that the ticket was created. It requests an electronic
export for the most recent complete 12-month period, including all-tier draw
and Scratch records where maintained, retailer records and identifiers, joins,
definitions, cadence, and any existing regularly updated report, API, dataset,
or file. It also permits the most recent complete month if the full period is
burdensome. No fees were authorized.

## September 21 agency response and limited-data path

David Stevens, Chief of Security & Enforcement, declined the requested winning-
ticket data citing winner anonymity, declined a retailer-list export, and said
retailer joins are limited to the public winners list. He directed us to
`https://wyolotto.com/wyo-wins`, `/find-retailer`, and `/wyo-wins/winners-list`.
He confirmed that Wyoming offers no Scratch or instant-ticket games and asked
for clarification of definitions/cadence/revisions. No dataset was delivered.
This is an explicit refusal of requested records, distinct from a pending reply.

A September 21 reply clarified that no winner personal information is sought,
accepted existing nonpersonal aggregate August 2026 counts by game/tier and
partial reports, and asked about the public list's date meaning, prize threshold,
completeness, selling versus validating retailer, update frequency and corrections.
No new report or paid work was requested; no fees were authorized. Gmail confirmed
sending. A shared Wyoming data-limitation notice now appears on the map coverage
card and state source screen. App completion can proceed with verified public
information and honest missing-data notices; no complete heat-map coverage is
claimed. The absence of Scratch games is a confirmed product limitation, not a
missing Scratch dataset.

Later September 21, Stevens replied that the narrowed aggregate reports are not
built or available and again referred us to the website's winner information.
No new dataset or field/cadence clarification was supplied. Continue with the
explicitly limited public-source path; no further intervention is needed for
that approach.

## September 28 administrative contact confirmation

WyoLotto Support asked for business name and phone at 19:11 UTC to confirm the existing request. The Sent-confirmed reply supplied Lottery Atlas as the project name, Apollo Houser as
requester, and the phone already provided in prior official records correspondence.
The phone is intentionally omitted from this public source-screen document.

The reply linked this administrative confirmation to David Stevens's existing
responses and explicitly avoided a duplicate request, new compilation or fees.
Email delivery remains preferred. This does not reverse the September 21 refusals
or establish a new substantive review, deadline or data delivery. No user action
is required; preserve the public-source limitations above.

## September 29 administrative forwarding acknowledgment

At 17:22 UTC, WyoLotto Support confirmed receipt of the contact details and said
the correspondence had been forwarded to David Stevens for review (private correspondence references retained locally). No records, revised
substantive decision, response deadline or fee request accompanied this message.
The September 21 refusals remain the latest substantive disposition. Monitor
for a further response; no reply or user action is required for this acknowledgment.
No fees or new compilation are authorized, and no public data changed.

## October 26, 19:00 ET — sole active state

Wyoming activated after New Mexico acceptance. Full supported current/retired
scope and gap matrix due October27 at19:00ET; supported release due October31
at19:00ET, fresh120hours for substantial draw/Keno integration. No extension.
Eighteen states accepted;27 unfinished including Wyoming. See
[WYOMING_ACCEPTANCE.md](WYOMING_ACCEPTANCE.md).

Four official opening captures at23:00:01–02UTC are hashed privately under
work/wyoming_scope/opening-manifest.json. [Current catalog](https://wyolotto.com/games)
links Cowboy Draw, Powerball, Mega Millions, Millionaire for Life,2by2 and Keno.
[Results](https://wyolotto.com/wyo-wins/check-your-numbers) and
[Keno](https://wyolotto.com/games/keno) expose dynamic search/history controls;
this shell alone does not verify payloads, draw dates/IDs, timezones, counts,
prize geography or history depth. Existing agency refusal/no-Scratch evidence
remains authoritative for those limitations; no new correspondence is needed.

Next inspect official result payloads, all rules/add-ons and retired/history
sources, then fix the full matrix before strict parsers/coupled publication/app
work. No new public feed, build or accepted Wyoming coverage is claimed.
Private administrative identifiers were removed from this source screen; the
original audit copy remains private.

## October 26, 20:05 ET — official dynamic contracts located

Captured the five remaining game HTML shells, the site's public JavaScript bundle,
its all-games response and all six rule responses privately. Hashes/timestamps
are in work/wyoming_scope/game-manifest.json and api-manifest.json. The bundle
identifies same-origin `/api/v1/game/all` and `/api/v1/game/rules` (identifier,
platform=web, cmsPreview=false); all seven requests returned success envelopes.
These are research captures, not validated or published app data.

The all-games response contains six current entries: five draw games and rapid
Keno, none marked retired. This does not prove historic scope completeness.
Keno's rule response has ten structured spot tables with38 data rows excluding
headers; the other five game responses link prize/odds images. Those images still
need visual review before literal schedule transcription/validation. Rule prose
and monetary/odds semantics are not yet contract-gated. Never substitute an
estimated jackpot for a dated prize or treat catalog startDate as game inception.

Result and Keno history code uses a separate game-data service. Keno queries
explicit draw-number ranges; standard draw data has primary/secondary result
structures. Exact payload identities, timezones, bonus/color grouping, statuses,
count units/geography and current/historical add-ons remain unverified. Public
client configuration stays in private source captures, not tracked feed/docs.
Next capture bounded result payloads through the official implementation, inspect
five schedule images and history/retired notices, then fix the full scope matrix.
No new feed/build/acceptance, no deadline change; Wyoming remains sole active.

## October 26, 21:05 ET — five schedule images visually reviewed

Official rule-linked schedule images were retrieved with hashes/timestamps in
work/wyoming_scope/schedule-image-manifest.json and visually inspected. Private
literal transcription records39 prize rows: Cowboy Draw4, Powerball9, Mega
Millions9, Millionaire for Life9 and2by2 eight. Keno's ten structured tables
remain38 data rows, separately captured; no claim of completed parser validation.

Preserve distinctions: Cowboy Draw Jackpot is categorical; Mega Millions image
states automatic multiplication of every non-jackpot win, so its printed values
are not a single draw-wide final payout. Millionaire for Life's first two prizes
are annual lifetime amounts, not lump sums.2by2 has separate red/white matches,
base/doubled columns and categorical free plays; its jackpot asterisk requires
rule-prose reconciliation. Powerball image is the base table, not a verified
Power Play/Double Play schedule. No missing variant is inferred from the image.

Official JavaScript also identifies draw-game list/details and Keno date-to-draw-ID
and draw-ID-range endpoints. Actual payload capture, timezone/identity/status
validation and exhaustive retired/add-on scope remain next. No new public feed,
build or acceptance; scope due October27 19:00ET and release October31 19:00ET.
