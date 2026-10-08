# North Carolina source screen — October 8, 2026

North Carolina is now the sole active state. See NORTH_CAROLINA_ACCEPTANCE.md
for fresh October 8 source evidence and the October 9 scope / October 13 release
deadlines (10:38 ET). Earlier correspondence notes below remain historical; no
new agency response or complete dataset is implied by this activation.


The [NC Education Lottery Scratch-Off Prizes Remaining](https://nclottery.com/scratch-off-prizes-remaining)
page publishes prize tiers, totals established at printing, and prizes
remaining, with a daily as-of date. It calls remaining prizes “not yet
claimed.” The difference between total and remaining may describe claimed
prizes for listed games, but its treatment of reorders, game endings, and
all-tier completeness must be validated before publishing any derived count.
Printed totals alone are not winning tickets actually sold or claimed.

The official [Winners pages](https://nclottery.com/WinnersAll?g=PB) show
claims of $5,000 and up and say they update weekly. They include retailer
names for some rows, but explicitly include unavailable/non-retailer cases.
This is a high-prize subset, not a complete all-tier heat map or statewide
winner total. No all-tier draw export or complete retailer join was verified.

The Lottery's [contact page](https://nclottery.com/contact) lists
`PlayerInfo@lotterync.net`. On September 14, an inquiry was sent there for
routing to the records/data team, requesting existing all-tier draw and
Scratch counts, a retailer directory and public winner joins, source dates,
corrections, cadence, fees, and the proper filing route. Gmail confirmed
“Message sent.” No substantive response or complete dataset has arrived;
North Carolina is not ready for full-state testing.

Later September 14: Player Service directed the inquiry to
`https://records.lotterync.net` for a public records request. The form has
required name, email, description, and request-type fields; its address and
phone fields are shown without a required marker. A formal request was not
successfully submitted during this screen, so no case number exists yet.

On September 16, the portal's embedded form was retried in the in-app browser
and Chrome. Its email and request-type controls did not reliably retain input,
so no portal submission was claimed. A complete written August 2026 request
was instead emailed to `publicinfo@lotterync.net`, the public-records contact
provided in Player Service's reply. It asks the custodian to accept and assign
a tracking number or provide a working alternative route, discloses potential
commercial use, and asks for a fee estimate before paid processing. Gmail
confirmed “Message sent.” Acceptance and responsive data remain pending.

## October 8 supported-scope review

Full product scope is closed in NORTH_CAROLINA_ACCEPTANCE.md; release remains due
October 13 at 10:38 ET. Fresh official report pages distinguish per-tier NC wins
from combined Pick 3/4 winners and Cash Pop session summaries. The dated Pick
3/4 detail payout schedules do not provide per-tier winner counts. Preserve these
source distinctions in the forthcoming integration; no report totals were
promoted by this review. Scratch Reordered status increases printed prize counts,
so inventory differences must not become claimed-ticket totals.

## October 8 directory collision audit (12:40 ET)

Fresh official directory capture contains 7,528 rows and 7,494 normalized
name/city keys. Twenty-eight keys contain 62 rows. The existing archive matcher
silently kept the last branch for repeated keys; 107 activities in the retained
snapshot have one of those ambiguous keys. Those positions are not validated
joins. Counts describe this audit, not a newly accepted statewide directory.

The importer now excludes every repeated normalized name/city key from archive
matching, including third occurrences and identical duplicates. Three focused
Node tests cover uniqueness, order independence and normalization collisions.
The raw directory and collision details remain private in
work/north_carolina_scope/directory-audit.json. No public snapshot was regenerated
or promoted during this audit; previously published positions remain pending
correction through the validated refresh pipeline. News fuzzy matching and the
global date-based archive/news overlap heuristic still require separate repair
or exclusion before NC acceptance. NC remains unaccepted and the October 13
10:38 ET release deadline is unchanged.

## October 8 mapped-activity correction (13:45 ET)

Excluded 107 archive records with ambiguous name/city branches and both existing
news records from the retained NC snapshot, leaving 17,874 records. These are
retained source records, not a new distinct-ticket total or full fresh import.
All surviving records and source dates are unchanged. The public activity
publisher validated 23,937 records; 35 excluded records were within its 2026
window. All non-NC activity remains unchanged.

Removed news supplementation from the importer: fuzzy branch scoring and a
publication-date cutoff do not establish identity or prevent archive overlap.
News remains an official source route, with no mapped-record promotion. Four
Node tests now run under the existing CI test glob, including an importer fixture
that excludes ambiguous branches, rejects any news request and preserves the
output bytes on request failure. Private before/removed evidence is retained in
work/north_carolina_scope. This fixes the known joins without claiming the
remaining pagination, date/unit, directory or full NC acceptance audits are done.
Publication verification follows the correction commit; push alone is not proof.

Correction deployment verified: release `d892565`, publisher run `37818483881`
completed successfully. The public activity.json bytes match the locally
validated corrected file exactly (private checksum evidence recorded). Known
ambiguous archive records and unverified news records are absent from the public
feed. This closes the correction publication checkpoint, not NC acceptance or a
native remote-adoption check. No simulator/user-review state was changed.
