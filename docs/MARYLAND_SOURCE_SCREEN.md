# Maryland source screen — September 12, 2026

Maryland is **deferred for the complete verified heat map**. Official game and
result links already in the app remain useful.

- The [official Scratch-Off finder](https://www.mdlottery.com/games/scratch-offs/)
  lists current games, prices and top prizes and advertises an exportable
  current ticket list. Individual ticket pages publish remaining prizes.
- The [official player tools page](https://www.mdlottery.com/player-tools/)
  says there are about 4,400 lottery retailers, but directs users to a
  nearby-retailer search. A complete, current official statewide directory
  with exact addresses and verified coordinates was not established in this
  screen.
- The [official winner stories](https://www.mdlottery.com/category/winners/)
  and weekly winner articles report selected wins. They do not establish
  comprehensive retailer-level winner activity from January 1, 2026 onward.

A slower official publication cadence would be acceptable with a clear source
date and state-specific notice. The remaining blockers are directory and winner
coverage. Recheck for a lottery-published full retailer export and claims feed
before promoting Maryland to testing. Georgia is the next source candidate.

On September 13, 2026, a Public Information Act request was sent to
`seth.elkin@maryland.gov`, the agency's [designated PIA contact](https://www.mdgaming.com/welcome/contact-us/)
also listed in the [Maryland Attorney General's PIA directory](https://oag.maryland.gov/resources-info/Documents/pdfs/Appendix_J.pdf).
It requests existing draw and Scratch-Off winning-ticket counts, selling
retailer links where maintained, a current retailer directory, field
definitions and update cadence. Gmail confirmed “Message sent”; no new
coverage has been verified from this request yet.

On September 15, the agency asked for a date range and prize-tier scope and
said a central-system vendor may be needed. Work beyond two hours may incur a
fee. The agency also confirmed that its Scratch-Off pages update unclaimed
winning-ticket counts daily at every prize tier, but that those counts cannot
show whether an unclaimed ticket has been sold. A reply narrowed the initial
request to August 1–31, 2026, retained all prize tiers for draw and Scratch-Off
games, asked for existing standard reports and future reporting cadence, and
required a written estimate before any paid work. No fees were authorized.

Later September 15, the agency confirmed that it is scoping all winning draw
game tickets sold and Scratch-Off tickets redeemed during August 2026, with
game name, prize amount, claim date, and selling-retailer name and address.
The requester added game type, draw date, retailer identifier and complete
locality fields, and a non-personal record identifier where already maintained.
The reply also repeated the request for update cadence, repeatable future
extracts, an existing retailer-directory export, and an estimate before fees.

## September 21 public catalog audit

The official finder loads its tickets using the public request defined in
`/wp-content/themes/mdlottery/js/scratch-offs.js`: GET `/wp-admin/admin-ajax.php`
with `action=jquery_shortcode`, `shortcode=scratch_offs`, and `atts={"null":"null"}`.
The initial page alone contains promotional slides, not the full catalog.
The ticket response contains 95 unique printed game IDs and 966 prize tiers.
All tiers have nonnegative remaining counts no greater than original counts;
all card top-prize counts match their labeled tier, and each card's all-prizes
remaining count equals its tier sum. All inventory dates are September 19,
2026; preserve that printed date and the agency-confirmed daily cadence.

Game 791 THE BIG SPIN advertises a categorical BIG SPIN top prize, with
separate cash and digital-spin tiers. Game 741 Let's Make a Deal includes
labels such as `250.00 (SPIN)` without a dollar prefix. Preserve these labels
and separate categories; do not coerce BIG SPIN to a cash maximum or merge
same-value cash and spin tiers. Decode source HTML as UTF-8 explicitly.

Claim deadlines are published for a subset; games 733 and 731 have a last
claim date of September 21, 2026. A future importer must include the deadline
itself and exclude them the next local day, independently of positive counts.
A listing or future claim deadline does not prove current retail stock.
Remaining totals may include sold tickets that have not been cashed.

Reproducible audit materials are in ignored `work/maryland_catalog/`:
`list.html`, `source.js`, `tickets.html`, `audit.py`, and `audit.json`.
This is an import candidate only; no Maryland catalog was published in this
pass. The broader August records request remains pending and is separate
from this independently retrieved public inventory.
