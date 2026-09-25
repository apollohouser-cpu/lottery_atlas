import {readFile, writeFile} from 'node:fs/promises';
import {validateKentuckyTierFeed} from './import_kentucky_draw_tiers.mjs';
const [input,output]=process.argv.slice(2);
if (!input || !output) throw Error('Input and output required');
const raw=await readFile(input,'utf8');
validateKentuckyTierFeed(JSON.parse(raw));
await writeFile(output,raw);
console.log('Published two validated Kentucky statewide tables with original dates.');
