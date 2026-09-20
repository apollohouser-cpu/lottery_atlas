// Only temporary transport/service failures may use a previously verified feed.
export class SourceUnavailableError extends Error {}

export async function fetchSourceJson(url, {
  fetchImpl = fetch,
  wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms)),
  attempts = 4,
} = {}) {
  let lastError;
  for (let attempt = 1; attempt <= attempts; attempt++) {
    try {
      let response;
      try {
        response = await fetchImpl(url, {
          headers: {
            accept: 'application/json',
            'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
          },
          signal: AbortSignal.timeout(30000),
        });
      } catch (error) {
        if (!(error instanceof TypeError) &&
            !['TimeoutError', 'AbortError'].includes(error.name)) throw error;
        throw new SourceUnavailableError(error.message, {cause: error});
      }
      if (!response.ok) {
        const ErrorType = [408, 429, 500, 502, 503, 504].includes(response.status)
          ? SourceUnavailableError : Error;
        throw new ErrorType(`HTTP ${response.status}`);
      }
      // Malformed JSON is a data failure, not permission to reuse old data.
      try {
        return await response.json();
      } catch (error) {
        if (!(error instanceof TypeError) &&
            !['TimeoutError', 'AbortError'].includes(error.name)) throw error;
        throw new SourceUnavailableError(error.message, {cause: error});
      }
    } catch (error) {
      if (!(error instanceof SourceUnavailableError)) {
        throw new Error(`${url} failed: ${error.message}`, {cause: error});
      }
      lastError = error;
      if (attempt < attempts) await wait(attempt * 750);
    }
  }
  throw new SourceUnavailableError(`${url} failed: ${lastError.message}`, {
    cause: lastError,
  });
}
