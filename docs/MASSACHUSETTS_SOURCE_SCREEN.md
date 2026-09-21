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

## September 21 full Scratch inventory audit

The official application's published JavaScript identifies these read-only
public endpoints:

- `/api/v1/games`: 132 Scratch listings, separate from 23 e-Instant, nine Draw
  and two Rapid listings.
- `/api/v1/instant-game-prizes/special`: the same 132 Scratch identifiers, with
  132 TOP and 44 SECONDARY rows.
- `/api/v1/instant-game-prizes?gameID=NUMBER`: each game's complete published
  inventory, totaling 1,429 tier rows across the 132 responses.
- `/api/v1/games/rules/IDENTIFIER`: game rules, including printed game numbers.

All 132 game IDs, names, identifiers, prices and API start dates join across the
catalog, summary and detail feeds. The detail rows reconcile original quantities
as paid plus remaining, and the special rows agree with the corresponding detail
rows. Rules identify all 132 printed game numbers. These checks establish a
usable public source, but do not establish a dated winning-ticket metric,
retailer joins, or the meaning of every prize-value field.

Prize semantics require further handling before publication:

- Games 517, 512, 505 and 485 retain descriptions of depleted $200,000,
  $200,000, $50,000 and $10,000 tiers, respectively, but those rows have numeric
  `prizeAmount: 0`, zero remaining, and type REGULAR. Their TOP-tagged rows name
  smaller prizes. Do not treat the TOP tag as the original maximum or the zero
  numeric amount as the prize's face value.
- Of the 132 TOP descriptions, 64 are plain currency and 68 describe annuities
  or lifetime payments. Numeric fields are not consistently an advertised total:
  game 452 exposes 6,500,000 with a $10,000,000 annuity description, while game
  559 exposes 2,400,000 with a $20,000/month/10-year description. No explicit
  cash-option text was found in the 132 rules responses. Do not infer an annuity
  cash value by applying a generic percentage.
- Two catalog entries, 522 and 453, use `topPrizeDisplay` instead of numeric
  `topPrize`; these are representational differences, not missing game records.
- Rules and catalog launch dates differ for game 381 (April 29 versus May 5,
  2025) and games 467, 468 and 476 (January 7 versus January 6, 2025). Rules did
  not expose a matching Start Date text field for 524, 546 and 523. Preserve
  disagreements rather than selecting a date silently.

Thirty-five games carry `Expiring Game` and an `expirationDate`. The site's
own GameNotice code explains that these games are no longer for sale and that
this date is the last day to redeem a prize. All 35 dates are still in the future
at this audit, including September 30, 2026. They must not be labeled currently
on sale or discarded as already claim-expired. No inventory verification date
or publication/correction cadence was established; retrieval time must not fill
that gap.

The complete source responses, frontend bundle, repeatable read-only audit,
and semantic audit are retained under ignored `work/massachusetts_catalog/`.
No Massachusetts public catalog or map count was changed. This state is not yet
ready for catalog testing: cash/annuity semantics and explicit date conflicts
need handling first, independently of the outstanding broader records request.

A no-fee clarification was sent September 21 in the original public-records
email thread, requesting receipt acknowledgment and existing documentation for
the specific prize-value fields, date conflicts, inventory timestamp and update
cadence. Gmail returned sent message `1a0c665ccadea454`. It reiterates that no
custom compilation, fees or paid processing are authorized. Agency reply pending.
