# New Mexico source screen — September 14, 2026

The [official Winners page](https://www.nmlottery.com/winners/) says it lists
winners of $5,000 and above. Some entries name a retailer and street address,
but this selected high-prize threshold cannot establish an all-tier
winning-ticket count or complete retailer ranking.

The [Scratchers top-prizes-not-yet-claimed page](https://www.nmlottery.com/games/scratchers/top-prizes-not-yet-claimed/)
explicitly calls its remaining counts estimates and warns that winning
tickets may have been sold but not yet redeemed. Its top-prize scope and
claim lag prevent treating it as an actual all-tier winning-ticket total.
Draw results and the retailer section also do not establish a complete
retailer-linked ticket feed in this screen.

The Lottery's [Public Records page](https://www.nmlottery.com/lottery-info/public-records/)
lists `publicrecords@nmlottery.com` and says a formal written request must
include requester name, mailing address, and telephone number. On September
14, an email **process and data-availability inquiry** was sent to that
address seeking existing electronic all-tier counts, Scratch claims, public
retailer records, definitions, cadence and fees, and clarification of the
contact requirements for electronic delivery. Gmail confirmed “Message
sent.” This inquiry is not a formal filed records request. No responsive
data or complete state coverage is verified; New Mexico is not ready for
full-state testing.

On September 16, after the requester supplied the required mailing address
and telephone, a formal written IPRA request was emailed to the Lottery's
published records custodian. It asks for existing August 2026 all-tier draw
and Scratchers validation/claim records, the public retailer directory and
available winner-to-retailer joins, definitions, corrections, cadence and
recurring sources. It excludes private winner identifiers, discloses possible
commercial use and asks for a fee estimate before paid work. Gmail confirmed
“Message sent.” Agency acknowledgment and responsive records are pending.

## September 20, 2026 inventory and ending-date audit

The official top-prizes page loads its table from
`https://nmlotteryscratchers.sks.com/ScratchersPrize/GetTopPrizesHtml`, an endpoint
explicitly referenced in the public page's JavaScript. The response contains
63 unique game numbers with explicit ticket cost, game name, top prize and
estimated remaining count. Its source timestamp is September 20, 2026,
03:17 PM; the displayed timezone is unspecified. Preserve that literal source
time and date without inventing a timezone or equating it to retrieval time.
The official disclaimer calls the counts estimates and warns that tickets may
already have been sold or not redeemed.

Joining game numbers to the official [Games Ending page](https://www.nmlottery.com/games/scratchers/games-ending/)
identifies nine inventory entries whose claim deadlines have passed: 631, 632,
633, 637, 639, 641, 653, 664 and 669. Ten more have ended sales but remain
redeemable: 581, 601, 638, 648, 657, 658, 659, 660, 661 and 668. Thus 54 of the
63 inventory entries are not expired under these notices; only 44 have no
matched passed sales-end date. Do not describe all 63 as active games or infer
store stock from a nonzero estimated remaining count. Use explicit claim
deadlines, not a calculated 90-day approximation.

Two historical closing rows outside the current inventory have inconsistent
dates: game 525 lists an end date in 2204 but a claim deadline in 2024; game
551 lists an October 2024 end with a January 2024 deadline. Do not silently
correct those records. A future importer should validate matched game dates,
quarantine unrelated historical anomalies, and stop if an included game has
an impossible chronology. Original spellings can also differ across sources;
join by verified game number rather than requiring exact titles.

Read-only audit materials are in ignored `work/new_mexico_catalog/`:
source-page HTML, inventory HTML, ending-page HTML, reproducible `audit.py`,
and `audit.json`. All price/count fields and unique identities passed checks.
No public New Mexico feed changed during this pass. The IPRA request remains
pending; no duplicate request or fee commitment was made.
