# Lottery Atlas standard data request

**Subject:** Request for regularly updated lottery winner-count and game data

Dear Lottery Data / Public Records Team,

Lottery Atlas is building a source-attributed public view of lottery results.
Please provide the existing machine-readable data or report links for the items
below, covering January 1, 2026 to the present and an ongoing update method.
CSV, JSON, an API, or a stable downloadable report is useful; please identify
which fields are authoritative and how often each source is published.

1. **Draw games:** For each state-operated game and each multi-state game sold
   in your jurisdiction, the game identifier/name, drawing date, prize tier,
   number of winning tickets sold in your jurisdiction, and whether the count
   is preliminary or final. Please include correction/revision indicators.
2. **Scratch-Off games:** A complete current game catalog with game number,
   name, ticket price, start/end dates, prize tier, original prize count,
   claimed/validated count, remaining count, and the as-of date for each
   report. Please distinguish printed winning tickets from claimed prizes and
   explain whether remaining counts include unactivated or unsold inventory.
3. **Selling location, where available:** A stable retailer ID, store name,
   street address, city, ZIP, active status, and verified latitude/longitude
   (or the lottery's location identifier). For each publicly releasable winner
   record, please provide game, prize tier/amount, draw or claim date, selling
   retailer ID, and correction status. We do not need player names or contact
   information. If retailer identity is unavailable for some prizes, please
   identify the precise affected games/tiers and provide the aggregate counts.
4. **Access and updates:** Please identify a stable URL, API, scheduled export,
   or subscription for ongoing updates; expected publication cadence; source
   timezone; historical retention; documentation/data dictionary; rate limits;
   and any reuse or attribution terms. If no existing feed contains all items,
   please point us to each existing partial report and state which fields are
   not collected, not public, or require a separate request.

Please provide electronic records in their existing format. A partial response
is useful if its coverage and date are clear. We will label published counts
by game, prize tier, date, and source; we will not infer retailer locations or
present partial totals as all-game totals.

Thank you,

Lottery Atlas project team

## MUSL request / key application text

Use the [MUSL API signup](https://api.musl.com/signup) for a project key. Its
[Winners Tier API](https://api.musl.com/winners-api-by-organization-code)
exposes state/organization winner counts by tier for supported multi-state
draws. The project description can be:

> Lottery Atlas displays source-attributed lottery draw results and winner
> counts by state. We plan to poll the Winners Tier and Draw Report APIs on a
> schedule, cache responses, retain source dates and game/tier definitions,
> and show only the jurisdictions and counts returned by MUSL. We will not
> infer retailer locations from state-level counts.

The signup requires the applicant's real name, email, company/project details,
and acceptance of MUSL's terms. Do not put the issued key in source control;
the app already accepts `MUSL_API_KEY` at run time.
