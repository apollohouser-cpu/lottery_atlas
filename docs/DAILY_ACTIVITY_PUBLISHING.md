# Daily verified activity publishing

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

## What runs daily

At 11:17 UTC each day, GitHub Actions validates the files listed in
`tooling/approved_activity_sources.json`, builds `docs/activity.json`, and
publishes it to GitHub Pages. It also runs whenever an approved source file is
pushed.

The publisher rejects a record unless it has a game, prize, winning date,
named retailer or official winning location, address, exact coordinates, and a
direct official source link. A failed validation leaves the previously
published feed untouched.

This workflow is intentionally not a generic web scraper. Adding fresh state
data still requires a state-specific official-source importer or an authorized
lottery export. That is what keeps the daily feed accurate rather than merely
frequently refreshed.
