# Idaho source screen — September 16, 2026

The [official Scratch catalog](https://www.idaholottery.com/games/scratch)
shows remaining prizes by game and tier, including lower tiers on its “View all
prizes” display, plus percent sold. These are **remaining prizes**, not a
dated count of winning tickets claimed or validated. The screen did not expose
the original inventory or a stable historical snapshot for each tier, so
claimed tickets cannot safely be inferred from this page alone.

The [Idaho Cash game page](https://www.idaholottery.com/games/draw/idaho-cash)
has an “Idaho Winners” table with counts by match/prize tier for its latest
drawing. This is a promising official all-tier **single-game, single-draw**
count, including free-ticket wins. The page also lists past winning numbers,
but this screen did not establish historical winner counts for every draw or
similar coverage across every Idaho-sold draw game. The free-ticket tier must
be labeled as such rather than assigned a cash prize.

The [official retailer finder](https://www.idaholottery.com/pages/find-a-retailer)
searches by city, ZIP and map. It does not establish a complete exportable
active-retailer directory with stable IDs or a join from every winning ticket
to its selling store. The Lottery's
[public-records request form](https://www.idaholottery.com/images/uploads/general/Request_For_Records_Fillable_updated2025_email2.pdf)
is a potential route for the missing existing records; no request is claimed
as filed in this screen.

Idaho can show the currently published Idaho Cash draw-tier counts and current
Scratch remaining-prize snapshots only with exact game, drawing or source date,
count definition and coverage notices. It is not yet ready for a complete
statewide winning-ticket total or retailer heat ranking. Historical access,
refresh cadence and correction handling require verification.

September 17: a written 2026 year-to-date public-records request was sent to
`info@lottery.idaho.gov`, the email printed on the Lottery's official request
form. It asks for Idaho-sold all-tier draw-game counts, Scratch prize/claim
inventories, an active retailer directory, any maintained retailer joins, and
source cadence and correction definitions. An August 2026 sample is acceptable
for initial routing, but does not replace the requested year-to-date period.
Gmail confirmed the message was sent; agency acknowledgment and records are
pending. No fees were authorized.

## September 19 API and directory audit

The current official site's date-picker JavaScript exposes the public route
`https://www.idaholottery.com/api/v1/drawgame/idaho-cash/YYYY-MM-DD`.
`tooling/import_idaho_cash_draw_tiers.mjs` retrieved and validated every one of
**261 consecutive daily drawings from January 1 through September 18, 2026**.
It checked each response's game and requested date, five distinct numbers in
range, all four unique tier labels, and nonnegative integer counts. Tier
labels, rather than response ordering or `weight`, identify the prize tier.
The four sums are 5 jackpot-tier wins, 989 $200-tier wins, 38,046 $5-tier wins
and 476,082 free-ticket-tier wins. These are **published prize-tier winner
counts**, not verified distinct tickets or players. Idaho Cash offers two
plays on a $1 ticket, so adding tier counts must not silently become a count
of distinct tickets. Free tickets are not assigned a cash amount.

The dated audit is stored in `data/idaho_cash_draw_tiers.audit.json`, with a
direct official source URL for every drawing. It is not registered in the
public activity or state winning-ticket-total feeds, and it is not an
all-game Idaho total. The importer checks the latest published winner-table
date and rereads the complete year-to-date sequence when run; it has not been
added to the recurring publisher pending source-definition review. Daily
drawings do not establish an API publication SLA or correction policy.

The same official site's retailer-map JavaScript directly loads
`https://id-lottery-public.s3.us-west-2.amazonaws.com/Drupal-Site/Retailers/retailers.json`.
On September 19 this file contained **1,368 unique retailer IDs** with names,
addresses, city, state, ZIP, game types and coordinates. The response's
Last-Modified timestamp was **2026-09-19 10:00:29 UTC**, which is file metadata,
not proof of when each retailer record changed. There are 1,135 entries
listing Draw or Scratch games, 68 with no listed game type, and other entries
covering Tab games. All rows label their state `ID`; 137 have a zero latitude
or longitude, and 12 additional entries fall outside coarse Idaho bounds.
County-polygon and address checks remain necessary before map integration.
Do not assign nearby coordinates or describe this as a fully verified active
Draw/Scratch directory merely because the export is statewide.

A local point-in-polygon audit against the bundled 44 Idaho Census counties
found 1,216 of all entries in exactly one county, 137 with missing coordinates
and 15 outside those polygons. Within the 1,135 Draw/Scratch entries, 1,020
matched one county and 115 had missing coordinates; none were assigned to a
nearest county. This verifies containment of the published points, not an
independent street-address match. The working audit is retained locally in
`work/idaho_retailer_coordinate_audit.json` for the directory integration step.

The September 17 records request remains pending. A defined distinct-ticket
measure, winner-to-selling-retailer joins, publication/correction timing and
coordinate exceptions are still unresolved. Idaho is **not yet ready for
retailer heat-map testing**. The new API access advances historical-source
availability without removing those coverage limits.
