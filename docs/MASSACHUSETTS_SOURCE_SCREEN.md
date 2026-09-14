# Massachusetts source screen — September 13, 2026

The official [Winners page](https://www.masslottery.com/tools/winners)
describes its rows as draw and instant-game prizes over $600 since December
15, 2020, plus draw-game grand prizes since January 2003. Its game, date,
prize, and location filters expose selling-retailer names and towns for some
rows, and `Online` for others. The web application's same-origin
`/api/v1/winners/query` endpoint accepted `start_index`, `count`,
`date_from`, and `date_to` on September 13. A query for September 12 returned
`totalNumberOfWinners: 645` and records with `date_of_win`, `identifier`,
`name`, `prize_amount_usd`, `retailer`, and `retailer_location`. An unfiltered
query returned `totalNumberOfWinners: 1056682` at screening time. These are
mutable endpoint observations, not ticket totals for publication.

The public page's threshold excludes smaller prizes. The field is labeled
*winners*, while the requested app metric is winning **tickets**; the source
does not establish distinct ticket identity, claim/draw semantics, or a
complete all-tier count. Its retailer names and town-level locations do not
provide a verified street-address and coordinate link for heat points.
Massachusetts is therefore not ready for a complete ticket-total ranking or
retailer heat-map test. A future scoped subset must state its threshold,
date definition, online coverage, and observed source date explicitly.

The Lottery's [public-records help article](https://support.masslottery.com/support/solutions/articles/63000261430-public-records-request)
lists `publicrecords@masslottery.com`. On September 13, 2026, a written
request was sent there for existing electronic all-tier national/state draw
and instant counts, retailer joins, definitions, historical coverage,
correction policy, and a daily-capable access method. It specifically asks
whether `totalNumberOfWinners` represents distinct tickets and discloses
potential public/commercial use. Gmail confirmed “Message sent.” No response
or complete count has been verified yet.
