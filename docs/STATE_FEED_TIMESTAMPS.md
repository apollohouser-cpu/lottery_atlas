# State feed timestamps

The combined-feed builder preserves each catalog and retailer directory's
`updatedAt` instead of assigning the newest state's timestamp to all states.
An explicit state timestamp takes precedence, followed by the source file's
update/retrieval timestamp. Each output's root timestamp is the latest instant
among its own entries, compared chronologically across offsets. Catalog changes
therefore do not advance the retailer directory's timestamp. Missing timestamps
sort at the Unix epoch; source verification dates are never invented or changed.

Catalog entries carry `timestampScope: state`. The Flutter cache preserves that
scope. Legacy caches may contain inflated aggregate timestamps, so a successful
download with state-specific timestamps permits replacing those timestamps and
choosing the newest trustworthy bundled/downloaded snapshot. Without such a
download, legacy cached data remains available offline. Existing legacy combined
feeds remain usable and retain their legacy scope until their publisher upgrades.
The migration does not clear the cache or interpret retrieval time as prize
verification time.

Regression tests cover independent state dates, separate catalog/directory root
timestamps, time-zone offsets, unknown dates, legacy offline preservation,
authoritative timestamp repair, preference for a newer bundled snapshot, and
legacy publisher compatibility. No catalog games, prize counts, source dates,
or retailer coordinates were changed by this fix.

Validation September 21: 48 Node, 107 Python and 67 Flutter tests passed, along
with five HTTP checks and the macOS debug build. Analysis retained only the 12
existing informational notices. An independent comparison confirmed that the
combined feeds' underlying catalog and retailer data are unchanged. Publishing
verification is separate from these local checks.
