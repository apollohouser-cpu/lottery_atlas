// Dates in selected releases are calendar dates, never verified times of day.
export function newYorkReleaseDate(entry, content) {
  const publication = new Date(`${entry.date}T12:00:00Z`);
  if (Number.isNaN(publication.valueOf()) || publication.toISOString().slice(0,10) !== entry.date) return null;
  const fallback = {date: publication.toISOString(), kind: 'publication'};
  const match = String(content).replace(/\s+/g, ' ').match(
    /(?:for|in|from)\s+the\s+([A-Z][a-z]{2,8})\s+(\d{1,2})(?:,\s*(\d{4}))?\s+drawing/i,
  );
  if (!match) return fallback;
  const months = ['january','february','march','april','may','june','july','august','september','october','november','december'];
  const month = months.findIndex(m => m === match[1].toLowerCase() || m.slice(0,3) === match[1].toLowerCase());
  if (month < 0) return fallback;
  let year = match[3] ? Number(match[3]) : publication.getUTCFullYear();
  const day = Number(match[2]);
  let candidate = new Date(Date.UTC(year, month, day, 12));
  if (!match[3] && candidate > publication) {
    year--;
    candidate = new Date(Date.UTC(year, month, day, 12));
  }
  if (candidate.getUTCFullYear() !== year || candidate.getUTCMonth() !== month || candidate.getUTCDate() !== day || candidate > publication) return fallback;
  return {date: candidate.toISOString(), kind: 'draw'};
}
