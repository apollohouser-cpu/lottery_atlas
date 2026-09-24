// Census address lookup is read-only, so the same multipart body can be retried.
export async function fetchCensusBatch(url, body, {
  attempts = 4,
  timeoutMs = 120000,
  retryDelayMs = 1000,
} = {}) {
  if (!Number.isInteger(attempts) || attempts < 1) {
    throw new RangeError('attempts must be a positive integer');
  }
  for (let attempt = 1; attempt <= attempts; attempt++) {
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'},
        body,
        signal: AbortSignal.timeout(timeoutMs),
      });
      if (!response.ok) {
        await response.body?.cancel();
        const error = new Error(`Census batch geocoder returned HTTP ${response.status}`);
        error.retryable = [408, 429, 500, 502, 503, 504].includes(response.status);
        throw error;
      }
      // Fatal decoding keeps malformed data from being mistaken for an outage.
      const bytes = await response.arrayBuffer();
      return new TextDecoder('utf-8', {fatal: true}).decode(bytes);
    } catch (error) {
      const transport = error instanceof TypeError && error.message === 'fetch failed';
      if (!(error.retryable || transport || ['TimeoutError', 'AbortError'].includes(error.name)) ||
          attempt === attempts) throw error;
      await new Promise((resolve) => setTimeout(resolve, retryDelayMs * attempt));
    }
  }
}
