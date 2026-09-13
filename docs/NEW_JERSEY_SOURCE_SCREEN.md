# New Jersey source screen — September 13, 2026

## Official sources checked

- [Weekly prize release](https://www.njlottery.com/en-us/newsandevents/newsinput/2026/press-releases/NJL_WeeklyPrizes_090826.html): says **8 players** won draw and Scratch-Off prizes of at least $10,000 during August 31–September 6; published September 8. It is a weekly, thresholded player count, not a complete winning-ticket count.
- [News release index](https://www.njlottery.com/en-us/newsandevents/newsreleases.html): lists weekly releases, with the latest examined release dated September 8. The direct script request returned HTTP 403 on September 13, so a scheduled scraper is not yet reliable.
- [Active Scratch-Off games](https://www.njlottery.com/en-us/scratch-offs/active.html): advertises top prizes available by game. Top-prize inventory is not a count of all Scratch-Off winners.
- [Retailer locator](https://www.njlottery.com/en-us/retailer.html): search by location, not a verified export of all selling retailers or winning-ticket locations.

## Decision

Do not put the weekly player figure into `winningTickets`, and do not shade New Jersey using it. Existing New Jersey retailer-level activity snapshots remain partial and retain their source labels. The weekly release is useful context for a future separate metric with an explicit player/prize definition, but it cannot satisfy the current ticket-total contract.

## Next source request

An inquiry was sent September 13, 2026 from the connected Gmail account to `PublicInfo@lottery.nj.gov`, the address printed on the official weekly release. It asks for an existing machine-readable report or API with counts of winning **tickets** by draw date, game, tier, and New Jersey jurisdiction; Scratch-Off winning-ticket/claimed-ticket counts by game and tier with an as-of date; weekly-release count semantics; correction behavior; retailer identifiers; and update cadence. This is a data inquiry, not a formal OPRA filing. The Lottery's [FAQ](https://www.njlottery.com/en-us/aboutus/faqs.html/) says public-record requests require OPRA submission; use that process if the data team redirects us or does not provide an existing feed.
