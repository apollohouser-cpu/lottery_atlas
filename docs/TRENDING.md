# Trending

Owner requested November 26, 2026: replace the homepage Stats destination with
Trending for states, counties, cities, games and retailers. This is shared app
work and does not activate another state or close Connecticut acceptance.

Trending consumes the same filtered map snapshot as Top Five, including its
selected timeline and geographic scope. It does not record click history.
The selected inclusive calendar-date range is divided into up to ten consecutive,
non-overlapping windows, with integer-day boundaries and window lengths differing
by at most one day. A one-day selection has one window and cannot establish a
repeated appearance. Exact selected start/end timestamps are preserved.

Each window uses the existing Top Five ticket-total ordering (published prize
total, then label, for ties). Trending orders entities by number of Top Five
appearances, then average position in the windows where present, then stable key.
At least two appearances are required; the page displays the leading five.
Empty windows remain in the denominator and the number of windows containing
matching published records is disclosed. Missing records do not mean zero wins.
National county comparisons qualify identity by state; city and retailer labels
include location context. Existing Top Five behavior is preserved.

All five category selectors retain the map filters. Users change timeline and
filters on the map, then return to Trending. Available published activity is not
complete claims coverage and these rankings do not predict future winning odds.

Validation: 12 focused Flutter tests pass, covering sustained lower placement,
frequency tie-breaking, sparse and one-day periods, geographic identity/scope,
all categories, absent retailers, navigation, snapshot updates, and a landscape
2x text harness. Targeted analysis is clean. Harness results do not establish
physical iOS Larger Text or native lifecycle acceptance. The signed 103.2MB iPhone release built successfully and passed deep/strict
signature verification. After the owner connected the phone, in-place installation
and CLI launch succeeded on November26. The owner was told the update is installed
and may disconnect. Physical interaction review remains pending. Private build
and device evidence is under work/owner_iphone/trending_20261126.
