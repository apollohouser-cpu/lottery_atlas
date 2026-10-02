// Explicit supported game classification; null means unsupported or unverified.
const compact = (value) => String(value).replace(/\s+/g, ' ').trim();
export const gameFrom = (entry, body, scratchGames) => {
  const content = `${entry.Title} ${body}`;
  if (/mega\s+millions/i.test(content)) {
    return {game: 'mega-millions', gameName: 'Mega Millions'};
  }
  if (/powerball/i.test(content)) {
    return {game: 'powerball', gameName: 'Powerball'};
  }
  const drawPatterns = [
    ['Millionaire for Life', /millionaire\s+for\s+life/i],
    ['Cash4Life', /cash\s*4\s*life/i],
    ['Bank a Million', /bank\s+a\s+million/i],
    ['Cash 5 with EZ Match', /cash\s*5(?:\s+with\s+ez\s+match)?/i],
    ['Cash Pop', /cash\s+pop/i],
    ['Pick 5', /pick\s*5/i],
    ['Pick 4', /pick\s*4/i],
    ['Pick 3', /pick\s*3/i],
    ["Virginia's New Year's Millionaire Raffle", /new year'?s millionaire raffle/i],
    ['Keno', /\bkeno\b/i],
  ];
  for (const [gameName, pattern] of drawPatterns) {
    if (pattern.test(content)) return {game: 'state-draw', gameName};
  }
  // Print 'n Play can share a title with a retail Scratcher.
  if (/print\s*['‘’]?\s*n\s*play/i.test(content) ||
      /print\s*&(?:amp;)?\s*lsquo;n\s*play/i.test(content)) return null;
  const normalizedContent = content.toLowerCase().replace(/[^a-z0-9]/g, '');
  const scratch = scratchGames.find((game) => {
    const name = game.name.toLowerCase().replace(/[^a-z0-9]/g, '');
    return name.length >= 5 && normalizedContent.includes(name);
  });
  if (scratch) return {game: 'scratch-off', gameName: scratch.name};
  if (!/\bscratcher(?:s)?\b|\bscratch[ -]off\b/i.test(content)) return null;
  const titleMatch = entry.Title.match(
    /(?:top prize in|playing|in)\s+(.+?)(?:\s+scratcher(?:\s+game)?|\s+game|[.!]|$)/i,
  );
  return {
    game: 'scratch-off',
    gameName: compact(titleMatch?.[1] ?? 'Virginia Scratcher'),
  };
};
