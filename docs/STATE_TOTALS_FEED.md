# Official state winning-ticket totals

The map and ranking card can now display **state-level** counts independently
of retailer heat points. `data/state_winning_ticket_totals.json` is intentionally
empty until a verified ticket count is imported. The app also checks the public
`state_winning_ticket_totals.json` feed every six hours. A 404 or invalid feed
does not create counts.

Each row must contain a two-letter `state`, nonnegative integer
`winningTickets`, inclusive `periodStart` and `periodEnd` dates, a `sourceDate`
no earlier than the end of that period, an official HTTPS `sourceUrl`, and a
plain-language `coverage` description naming included games and prize tiers.
There can be only one row per state in a feed. A row is a source-specific
count, **not** an assumed all-game total. Do not sum game snapshots unless the
source definitions and time windows are disjoint and complete.

State shading uses the count without placing an artificial pin. The ranking
card labels these as official state totals, displays their coverage and source
dates, and keeps location-verified rankings separate. A statewide count cannot
be filtered to a county, retailer, or arbitrary timeline period unless the
source provides that breakdown. Retailer locations remain unverified where
the official source provides only aggregate counts.

New Jersey's September 8, 2026 release reports **8 players** winning draw or
Scratch-Off prizes of at least $10,000 from August 31 through September 6.
It does not establish a winning-ticket count, so this figure is not published
in the ticket-total feed. Six-hour feed polling cannot make a weekly source
fresher.
