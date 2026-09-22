# Rhode Island source screen — September 15, 2026

The Rhode Island Lottery publishes game-specific [Big Wins pages](https://www.rilot.com/en-us/winners/winners-instant-games.html)
with dates, amounts, games, retailers and cities. Individual pages expose
different scopes and update dates; for example, the public Lucky for Life list
is limited to specified higher-tier matches. These are useful verified winner
records, but they do not establish all-tier winning-ticket totals.

The official site also provides winning numbers, unclaimed prizes and a
city/ZIP retailer finder. A complete machine-readable active retailer directory
with stable IDs and a join from every winning ticket has not been verified.
Selected winner stories and tables therefore cannot support a complete state
heat map or ranking.

The Department of Revenue's [APRA page](https://dor.ri.gov/apra-requests)
provides an online request form with a CAPTCHA. A focused request was submitted
through that form on September 16, 2026 to the Division of Lottery for August
2026 all-tier draw and Instant Ticket records, the active retailer directory,
retailer joins, definitions, cadence, corrections and any existing regularly
updated file or API. It excludes personal winner information and requests one
electronic copy. The website confirmed receipt. No fees were authorized.

Rhode Island remains suitable only for clearly labeled public subsets until an
official all-tier source and complete retailer join are obtained. It is not
ready for full-state testing.

## September 21 partial delivery and fee estimate

The Lottery supplied `Active Retailer List Report as of 9-15-2026.xlsx` and
Valerie Morozov's September 21 two-page response to the September 16 APRA request.
The original attachments are preserved privately under ignored
`work/rhode_island_records/`; the letter was visually reviewed in full.

The workbook has one sheet, `Active Retailer List Report`, with headers on row 7
and 1,119 data rows (8–1126). All 1,119 retailer IDs are unique, all statuses are
Active, and all records have name, address, city, state and ZIP. ZIP values are
text and retain leading zeroes. No coordinates, county, game-specific licenses,
or winning-ticket joins are supplied. Do not invent locations or infer product
eligibility from name suffixes. Exact coordinate validation remains necessary
before a map layer is ready.

The letter says no existing record matches the requested winning-ticket format,
but the agency could assemble it from several sources for an estimated 14 hours
at $15/hour, totaling $210. It says the free hour has already been used, actual
cost may exceed the estimate, and no further work starts without response and
payment. Ticket/record identifiers would be withheld; other redactions may apply.
This is a partial delivery, fee-conditioned assembly offer, and partial withholding,
not a blanket refusal of every requested record. No fees are authorized.

A reply thanked the agency for the directory, kept paid work on hold, and narrowed
the remaining request to existing no-cost aggregate August game/tier reports or
public downloads without custom compilation, personal data, identifiers or
retailer joins. Gmail confirmed sending. The app now has a Rhode Island notice
explaining the available directory and unavailable winning-ticket data. The
user's limited-data completion policy permits continuing with these disclosures.

The reproducible private audit `work/rhode_island_records/audit_retailers.py`
produced `validated_retailers.json` with the workbook SHA-256 and source row
numbers. Three records have out-of-state addresses: 100143 (Walmart Chain Head,
Arkansas), 100291 (BJ'S WHOLESALE, Massachusetts), and 100358 (PRICE RITE -
WAKEFERN FOOD CORP, New Jersey). These are flagged for address review, not mapped
as Rhode Island storefronts. Eleven exact address/city/ZIP groups have multiple
records; preserve their distinct agency IDs pending interpretation. Thus 1,119
active records must not be represented as 1,119 distinct Rhode Island physical
stores. All ZIP strings satisfy the supplied five-digit/ZIP+4 format.

## September 21 retailer geocoding staging audit

The 1,116 Rhode Island address rows from the delivered directory were submitted
to the official [Census batch geocoder](https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.html)
using `Public_AR_Current`. The three previously flagged out-of-state addresses
were excluded. Original retailer IDs and leading-zero ZIP codes were preserved;
repeated addresses were not merged. The response was saved September 22 at
01:54:31 UTC (September 21 locally), separately from the directory's September
15 source date.

The response contains every submitted ID exactly once:

- 963 matches classified Exact by Census;
- 84 Non_Exact matches;
- 68 No_Match results;
- one Tie result.

Of the Exact matches, 957 also have matching house numbers, state and ZIP, and
fall in exactly one bundled Rhode Island county polygon. Six Exact matches fail
unique county containment (IDs 100161, 100474, 2019, 2140, 2454, 7073) and remain
under review. No coordinate is moved to a nearby polygon or substituted for an
unmatched address. Review-reason counts can overlap: all 84 Non_Exact matches,
25 ZIP differences, four house-number differences/unverified numbers, six county
containment exceptions, and 69 unmatched/tied records.

Census explicitly describes these coordinates as **calculated along an address
range**. Exact is an address-match classification, not proof of a precise store
entrance or parcel. All 1,116 staging records carry `publishable: false`; the
957 address candidates are not new verified store pins. No winning-ticket
records or retailer joins were supplied, so this audit cannot enable a winning
retailer heat map or ranking. Product eligibility remains unverified as well.

The raw request/response, benchmark metadata and audit stay under ignored
`work/rhode_island_records/`. `tooling/audit_census_retailer_geocodes.py` validates
response completeness, unique IDs, unchanged submitted addresses, coordinate
ranges, Census segment references, address components and polygon containment.
It retains source hashes and the original directory date. The five regression
tests exercise exact-versus-publishable handling, unmatched/tied records, missing
or duplicated IDs, mismatched input, non-exact/ZIP/house/county exceptions,
invalid coordinates, overlapping polygons and polygon holes. All 123 Python
tests passed. No app assets, public directory or map activity changed.
