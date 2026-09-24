# Kentucky source screen — September 17, 2026

Kentucky has **partial-coverage map data ready for testing**. The current
published feed includes an official catalog of 81 available Scratch-off games,
3,377 precisely located retailers out of 3,472 distinct official directory
entries returned across 120 counties, and 32 current winner notices matched
to a unique verified retailer point. The importer excludes 95 retailer
addresses without precise coordinates and four winner notices without an
unambiguous retailer match. These selected winner notices are not complete
2026 winning-ticket counts or a statewide retailer ranking; no Kentucky
all-game winning-ticket total is published.

The [Kentucky Lottery's Open Records page](https://www.kylottery.com/apps/about_us/openrecords)
lists residency categories. The requester is a South Carolina resident and
cannot certify Kentucky residency. The Lottery's
[media page](https://www.kylottery.com/apps/about_us/media.html) permits a
written email request to its records custodian. On September 17, a candid
nonresident inquiry was emailed to the published custodian for existing 2026
year-to-date all-tier draw counts, Scratch prize/claim inventories, retailer
directory and maintained winner joins, definitions, publication cadence and
public download links. Gmail confirmed “Message sent”; no paid work was
authorized. Await the agency's reply on permissible access and the records.

Current partial data can test source labels, retailer location display and
selected-winner points. It cannot validate a complete statewide winning-ticket
heat map or an all-tier comparison with other states.

### September 24 Census transport failure

Publisher 35939079754 attempt 2 stopped at this directory's Census batch lookup
with HTTP 502. The previous live directory remains available. Census multipart
lookups now retry temporary service failures up to four times, with a 120-second
whole-request limit per attempt. Permanent errors still fail immediately;
exhausted retries still stop publication. Existing address matching and county
validation rules are unchanged. Five new Node HTTP regression tests passed as
part of the 55-test suite. Deployment recovery remains to be verified separately.

### September 24 verified publishing recovery

Publisher 35945318934 attempt 2 succeeded at 03:21 UTC. All four live JSON
feeds were independently checked and match published commit 55b9631. This
resolves the refresh interruption described above; the bounded Census retry
change is included in the successful run. Existing coverage limitations and
pending agency definitions remain unchanged. No user intervention was needed.
