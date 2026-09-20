# Verified activity publishing

Lottery Atlas can now host its public activity feed from this repository at:

`https://apollohouser-cpu.github.io/lottery_atlas/activity.json`

The app uses that address by default. If the address is unreachable, it keeps
the last verified local or cached records; it never fills a heat map with
guessed data.

## One-time GitHub setup

After committing and pushing the workflow files, open this repository on
GitHub and make these two settings:

1. In **Settings → Actions → General**, set **Workflow permissions** to
   **Read and write permissions** and save.
2. In **Settings → Pages**, set **Build and deployment → Source** to
   **GitHub Actions** and save.

The repository must be public, or the GitHub plan must support Pages for
private repositories.

Then open the **Actions** tab, choose **Validate and publish lottery activity**,
and click **Run workflow** once. When the run is green, open the feed URL above
in a browser. It should display JSON.

## Refresh cadence and freshness

At 00:17, 06:17, 12:17, and 18:17 UTC, GitHub Actions validates the files listed in
`tooling/approved_activity_sources.json`, builds `docs/activity.json`, and
publishes it to GitHub Pages. It also runs whenever an approved source file is
pushed.
The source import and feed validation run once per workflow; the Pages job
deploys the exact artifact from that successful validation. It does not
repeat live source requests during deployment.

Publishing is restricted to `main`. Each queued run explicitly checks out the
latest `main` branch at job start rather than the older commit captured when
its event was queued. This prevents a scheduled run waiting behind another
publisher from regenerating files on a stale baseline and conflicting with
the preceding feed commit. Workflow concurrency continues to serialize runs.

Lottery Atlas checks refreshable sources every six hours where possible. The
state lottery's own publishing cadence can be slower. A weekly or monthly
official source may be included only with a clear state-specific cadence and
source-date disclosure; it must not be described as live or current-day data.
A successful workflow run or a newly published file does **not** prove the
underlying source changed. Each state-specific importer should retain the
source's actual update time. A one-time export remains a dated snapshot, not
an automatic feed. GitHub's scheduled runs can also be delayed or fail.

The publisher rejects a record unless it has a game, prize, winning date,
named retailer or official winning location, address, exact coordinates, and a
direct official source link. A failed validation leaves the previously
published feed untouched.

New York retailer imports retry temporary service and network failures up to
four times, with a 30-second timeout per request. If the service remains
unavailable, the importer may retain the complete, previously verified New York
directory. It checks the cached source, date, retailer count, unique IDs, required
fields, and coordinates before doing so. The file and its retrieval date stay
unchanged, and the workflow emits a warning that the refresh was deferred.
Malformed responses, incomplete exports, duplicate retailers, permanent HTTP
errors, and invalid caches still fail the update. Retaining the old directory
does not mean that New York's retailer data was refreshed successfully.

This workflow is intentionally not a generic web scraper. Adding fresh state
data still requires a state-specific official-source importer or an authorized
lottery export. That is what keeps the daily feed accurate rather than merely
frequently refreshed.
