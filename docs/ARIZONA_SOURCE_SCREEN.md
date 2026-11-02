# Arizona source screen — September 13, 2026

Arizona is not ready for a complete verified winning-ticket total or
retailer heat map. Its [official draw-game page](https://www.arizonalottery.com/draw-games/)
and [Scratcher catalog](https://www.arizonalottery.com/scratchers/) provide
game information. Individual Scratcher pages list prize tiers and prizes
remaining, but those are outstanding prizes rather than a count of tickets
won in a selected period. The [winner gallery](https://www.arizonalottery.com/winners)
is a selection of stories, not a complete record of winning tickets.

The [Where to Play locator](https://www.arizonalottery.com/where-to-play)
supports location search; this screen did not verify a statewide current
retailer export with stable identifiers and coordinates or a complete
retailer-linked winning-ticket feed. Do not infer full coverage from a locator
or use remaining prizes as claimed winners.

The [Lottery contact page](https://www.arizonalottery.com/contact-us)
links to a public-records portal. Its [instructions](https://feedback.arizonalottery.com/recordsrequest/instructions.aspx)
require a commercial/noncommercial-use attestation under penalty of perjury.
No attestation or request has been submitted. Determine the appropriate use
classification and a supported contact route before sending a formal request;
continue screening other states in the meantime.

September 20 source-access check: a direct local HTTPS fetch of the official
Scratchers page returned HTTP 403. The browser-search reader could access the
page, but several listing cards exposed a blank top-prize amount; details would
need independent validation. No automated Arizona import was enabled and no
records-use attestation was made. Continue with accessible official sources
while preserving this limitation.

## November 1 — active scope opening

Arizona activated at09:15EST with scope due November2 at09:15EST and supported
release due November6 at09:15EST. See ARIZONA_ACCEPTANCE.md. Direct draw-game
and Scratchers requests again returned403; private failed-response manifests are
retained. Web-reader access supports initial product discovery only, not recovered
production transport. No formal attestation, fees, new correspondence or feed.

### November 1 Quick Draw review

The eight linked game pages now have a product-by-product discovery matrix in
[ARIZONA_ACCEPTANCE.md](ARIZONA_ACCEPTANCE.md#november-1-quick-draw-source-screen).
Critical boundaries are hourly Draw ID/time identity, Lucky Links' distinct daily
schedule, ordered digit/dice results, and wager-unit reports ($2 for Pick Your Bet,
$1 on several other pages). These are not accepted person/ticket counts. Reader
result cells remain blank; no production transport recovery or source collection
is claimed. Scope closure and existing deadlines remain unchanged.

### November 1 supported scope fixed

Full supported scope was fixed at16:22EST, before the November2 09:15EST scope
deadline. See ARIZONA_ACCEPTANCE.md#fixed-supported-scope--november-1-at-1622-est
for every reviewed product, nineteen result-identity targets and explicit gaps.
Capture/parsers, publication and native acceptance remain open. Release remains
November6 at09:15EST; no extension, feed or acceptance is claimed.

## November 1 Powerball DOM evidence parser

Retained structured, populated browser DOM tables from the official Powerball
page, with acquisition timestamp, in private work/arizona_scope and an observed
fixture. The two tables share an HTML ID; exact column headers distinguish
Powerball from Double Play without relying on table order. The strict parser
validates 77 Powerball and 60 Double Play date-only rows, including the latest
October 31 and October 28 results. These are observed rows, not the full Arizona
scope target or complete historical coverage. Nested prize details are retained
as source evidence but no counts/reports are promoted: geography and units remain
unverified. No draw timestamps are fabricated.

Twelve focused Python tests pass across draw and catalog navigation parsers,
including blank templates, invalid ranges, duplicate/out-of-order dates, cadence,
changed table structure, source provenance and table-order independence. Browser
DOM access is not direct HTTP recovery or a scheduled collector. Remaining game,
rule/detail, refresh continuity, coupled publication, app and native gates remain
open; no Arizona feed/build/acceptance. November 6 09:15 EST release is unchanged.

## November 1 Fantasy 5 structured evidence

Captured the populated official Fantasy 5 result table through ordinary browser
DOM observation and retained timestamped evidence privately plus a source fixture.
Strict parsing validates 179 consecutive date-only rows, latest October31/30;
blank templates, missing daily rows, duplicate numbers, out-of-range values and
changed source/table structure fail closed. Nested prize details are retained but
not promoted to counts or reports; instant EXTRA is not a separate draw result.
Twenty-two focused Arizona parser tests pass. This is parser development, not
HTTP transport recovery, a scheduled collector, new public feed or acceptance.
Other game/rule/detail capture and publication/native gates remain open. Arizona
remains sole active with unchanged November6 09:15EST release deadline.

## November 1 Triple Twist structured evidence

Captured 180 populated daily Triple Twist rows from the official browser DOM,
latest November1 and October31. Added explicit six-of-42 validation using a shared
daily-lotto parser with Fantasy5's separate five-of-41/source contract. The three
rows on a purchased ticket are not three drawings. The latest source detail row
contains zeros; these are not promoted to verified zero winners or counts.
All report statuses remain unavailable pending semantics/timing validation.

Twenty-six focused Arizona parser tests pass, including cross-game source rejection,
exact number cardinality/ranges and missing daily results. Retained capture is
DOM evidence, not HTTP recovery or scheduled collection. No public feed, app build
or acceptance; remaining capture/rules/publication/native gates and November6
09:15EST release deadline are unchanged.
