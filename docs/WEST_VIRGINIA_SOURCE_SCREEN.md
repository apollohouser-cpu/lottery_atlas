# West Virginia source screen — September 15, 2026

The West Virginia Lottery's official [Scratch-Off catalog](https://wvlottery.com/games/scratch-offs/)
links game pages that publish game number, launch date, claim end date, ticket
price, overall odds, total tickets and tier-level total and remaining prizes.
These fields can support a refreshable current-game catalog and cumulative paid
count calculated as total minus remaining. They do not identify claim dates or
selling retailers, and closed games require separate historical treatment.

The official recent-winners pages and news releases publish selected prizes and
sometimes identify the selling retailer. The bundled starter snapshot contains
two verified Cash 25 top-prize tickets announced March 23, 2026. It is an exact
two-record subset, not a complete draw-game or Scratch history. The public
winner listing was returning a server error during this review, so it cannot be
treated as a stable complete feed.

The State of West Virginia's official agency directory lists the Lottery at 900
Pennsylvania Avenue, Charleston, WV 25302, `mail@wvlottery.com`, and
304-558-0500. A focused FOIA request was emailed to that official address on
September 15 for existing August 1–31 all-tier draw and Scratch records, the
active retailer directory, winner-retailer joins, definitions, cadence and
corrections. Gmail confirmed “Message sent.” Requester contact information was
supplied directly and is not stored in this repository.

West Virginia is not ready for map testing. Its current verified map data is a
two-ticket Cash 25 subset, and the disclaimer must remain until a current
retailer directory and broader verified winner coverage are available.

## September 21 formal submission

Lottery Web Response replied to the September 15 request and directed it to the
[official FOIA form](https://wvlottery.com/customer-service/customer-resources/FOIA-request-form).
This was routing guidance, not a denial or data delivery. The form was completed
September 21 with the previously supplied requester contact details. Its
500-character description limit required a concise scope incorporating the
September 15 email: August 2026 draw/scratch winning-ticket or paid-prize records,
retailer directory and joins, definitions/cadence/revisions, available partial
records with coverage limits, and an estimate before any chargeable work. No
fees were authorized. The page confirmed: “Your request has been submitted
successfully.” No case number was displayed; agency response remains pending.
Private requester contact details are not stored in this repository.

## September 22 response and data delivery

Courtney Shamblin emailed a signed two-page response and two Excel files at
15:33 UTC. Both PDF pages were visually reviewed; the PDF has no extractable
text. The letter says attached documents respond to the September 21 request
and completes the response. Its general reservation of exemptions is not an
express denial of a particular dataset. It states no prize threshold, fee,
report definition, or missing-record explanation. No appeal or paid work was
authorized. West Virginia is the fourth agency with a directly inspectable
delivery, after Illinois, Rhode Island and New York.

Originals remain private under `work/west_virginia_records`:

- `retailers.xlsx`: Traditional Retailers - 9-22-26.xlsx; sheet Sheet1, header
  row 4, 1,513 data rows with 1,513 unique license numbers, all marked Active.
  Fields include chain number, license number, business/DBA names, county,
  status and location address/city/state/ZIP. There are no coordinates.
- `claims.xlsx`: FOIA Houser.xlsx; sheet Sheet1, 125 data rows dated August
  3–31, 2026. Fields are Date, GameID, AmountWon, Retailer#, Agent, LStreet,
  LCity, LState and LZip. All fields are populated, with 75 distinct retailer
  numbers. Observed amounts range from $777 to $60,000; the minimum observed
  amount is not evidence of a reporting threshold.
- `response.pdf`: signed September 22 response; `audit.json` records file
  SHA-256 values and full-file inspection counts.

The directory contains 1,493 records with state WV, 19 with other state codes,
and one with malformed state ` W` (license 147308, Frankford Food Mart).
Some apparent corporate records have out-of-state location addresses despite
West Virginia county labels. Do not place them at a guessed local store or use
source county alone to force an address into West Virginia. All 1,513 licenses
being active does not prove they are 1,513 physical selling locations.

All 125 prize rows match a directory license number; 114 also match the supplied
street/city/state after case and punctuation normalization, and 11 require
address review. These are candidate joins only. **35 rows** point to license
121855, Claim Only Terminal - Validati, at Lottery headquarters: 19 iLottery
loyalty, 5 eInstant, 10 second-chance, and one Daily 4 row. That terminal must
not become a selling-store heat point. The other records also need selling
versus validation semantics confirmed.

There are 16 identical rows beyond first occurrences, without ticket/claim IDs.
They remain intact because identical values can describe different claims. GameID
contains names and several combined names, not consistently printed Scratch
game numbers. The dates are not yet confirmed as draw, claim, or payment dates.
The 125 rows are not published as a distinct-ticket total or complete physical
lottery coverage. No new retailer coordinates or map activity were imported.

A same-thread follow-up to Shamblin, copying the original agency recipients,
asks for existing row/date/amount definitions and thresholds, selling versus
validation IDs, chain/corporate identification, the malformed state, and existing
game mappings and refresh/correction information. Gmail confirmed the reply as
`1a0c9fa499bcd3d6`. No fees or new paid compilation are authorized. Continue
independent preparation while awaiting those definitions. The existing verified
Cash 25 subset remains available with its limited coverage.

At this check all four live JSON feeds still matched the current repository;
no publishing failure or new user intervention was found. This pass changed
source documentation only, so the previously passing app checks were not rerun.

### Private preparation while definitions are pending

The September 22 staging script `work/west_virginia_records/stage_records.py`
verifies the original attachment hashes and exact spreadsheet headers, then
preserves all 1,513 license rows and all 125 prize rows in private
`staged_records.json`. Source row numbers and raw field labels are retained;
identical prize rows are not removed. Every record is explicitly unpublished.
Review reasons identify the 35 claim-only-terminal rows, digital/promotional
entries, and non-WV or malformed state fields. Counts reconcile to the initial
audit. No coordinates are inferred and no public activity or retailer feed is
changed. This prepares consistent inputs for review once definitions arrive.
