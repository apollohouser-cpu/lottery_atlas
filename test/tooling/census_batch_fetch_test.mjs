import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {fetchCensusBatch} from '../../tooling/census_batch_fetch.mjs';

async function withServer(handler, run) {
  const server = createServer(handler);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    await run(`http://127.0.0.1:${server.address().port}/`);
  } finally {
    server.closeAllConnections();
    await new Promise((resolve) => server.close(resolve));
  }
}

test('Census 502 retries preserve multipart address payload', async () => {
  const bodies = [];
  await withServer(async (req, res) => {
    assert.equal(req.method, 'POST');
    assert.match(req.headers['content-type'], /multipart\/form-data/);
    let body = '';
    for await (const chunk of req) body += chunk;
    bodies.push(body);
    res.writeHead(bodies.length === 1 ? 502 : 200);
    res.end('verified response');
  }, async (url) => {
    const form = new FormData();
    form.set('benchmark', 'Public_AR_Current');
    form.set('addressFile', new Blob(['0,123 Main St,City,KY,40000\n']), 'retailers.csv');
    assert.equal(await fetchCensusBatch(url, form, {retryDelayMs: 0}), 'verified response');
    assert.equal(bodies.length, 2);
    for (const body of bodies) {
      assert.match(body, /Public_AR_Current/);
      assert.match(body, /0,123 Main St,City,KY,40000/);
      assert.match(body, /filename="retailers.csv"/);
    }
  });
});

for (const [status, expectedCalls] of [[400, 1], [503, 3]]) {
  test(`Census HTTP ${status} has bounded retries`, async () => {
    let calls = 0;
    await withServer((req, res) => {
      calls++;
      req.resume();
      res.writeHead(status);
      res.end();
    }, async (url) => {
      await assert.rejects(fetchCensusBatch(url, 'lookup', {attempts: 3, retryDelayMs: 0}), new RegExp(`HTTP ${status}`));
      assert.equal(calls, expectedCalls);
    });
  });
}

test('Census timeout includes stalled response body and stops at attempt limit', async () => {
  let calls = 0;
  await withServer((req, res) => {
    calls++;
    req.resume();
    res.writeHead(200);
    res.write('partial');
  }, async (url) => {
    await assert.rejects(fetchCensusBatch(url, 'lookup', {attempts: 2, timeoutMs: 80, retryDelayMs: 0}));
    assert.equal(calls, 2);
  });
});

test('Census malformed UTF-8 is rejected without retry', async () => {
  let calls = 0;
  await withServer((req, res) => {
    calls++;
    req.resume();
    res.end(Buffer.from([0xff]));
  }, async (url) => {
    await assert.rejects(fetchCensusBatch(url, 'lookup', {retryDelayMs: 0}), /encoded data/);
    assert.equal(calls, 1);
  });
});
