/* Builds deterministic multi-state catalog and retailer feeds for the app. */
import {readFile, writeFile} from 'node:fs/promises';

const [catalogOutput, directoryOutput, ...inputs] = process.argv.slice(2);
if (!catalogOutput || !directoryOutput || inputs.length === 0) {
  console.error(
    'Usage: node tooling/build_state_data_feeds.mjs CATALOGS.json DIRECTORIES.json INPUT.json...',
  );
  process.exitCode = 1;
} else {
  try {
    const catalogs = [];
    const directories = [];
    const timestamps = [];
    for (const path of inputs) {
      const root = JSON.parse(await readFile(path, 'utf8'));
      if (Array.isArray(root.catalogs)) catalogs.push(...root.catalogs);
      if (Array.isArray(root.directories)) directories.push(...root.directories);
      for (const timestamp of [root.updatedAt, root.retrievedAt]) {
        if (timestamp && !Number.isNaN(Date.parse(timestamp))) timestamps.push(timestamp);
      }
    }
    catalogs.sort((left, right) => left.state.localeCompare(right.state));
    directories.sort((left, right) => left.state.localeCompare(right.state));
    if (new Set(catalogs.map((item) => item.state)).size !== catalogs.length) {
      throw new Error('Duplicate state Scratch-Off catalogs');
    }
    if (new Set(directories.map((item) => item.state)).size !== directories.length) {
      throw new Error('Duplicate state retailer directories');
    }
    if (catalogs.length === 0 || directories.length === 0) {
      throw new Error('Both catalogs and directories are required');
    }
    const updatedAt = timestamps.sort().at(-1) ?? new Date(0).toISOString();
    await writeFile(
      catalogOutput,
      `${JSON.stringify({
        source: 'Lottery Atlas verified official state Scratch-Off catalogs',
        updatedAt,
        catalogs,
      }, null, 2)}\n`,
    );
    await writeFile(
      directoryOutput,
      `${JSON.stringify({
        source: 'Lottery Atlas verified official state retailer directories',
        updatedAt,
        directories,
      }, null, 2)}\n`,
    );
    console.log(
      `Built ${catalogs.length} state catalogs and ${directories.length} retailer directories.`,
    );
  } catch (error) {
    console.error(`State data feed build stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
