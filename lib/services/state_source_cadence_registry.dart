/// Published update cadence for official state sources when it is known.
///
/// This describes the lottery's source, not how often Lottery Atlas polls it.
class StateSourceCadenceRegistry {
  StateSourceCadenceRegistry._();

  static String? noticeFor(String stateName) {
    switch (stateName) {
      case 'Kansas':
        return 'Lottery Atlas attempts Kansas Scratch and result imports every six '
            'hours. The Scratch source states hourly remaining-prize updates, but '
            'publishes no verification timestamp; retrieval time is not a source '
            'verification date. Source launch metadata/display conflicts remain '
            'unresolved and no normalized launch date is inferred. Result timestamps '
            'retain UTC provenance with local dates derived in America/Chicago. '
            'Advertised draw dates remain separate. Failed refreshes retain prior '
            'verified data and dates; frequent games are not a live service.';
      case 'Louisiana':
        return 'Lottery Atlas attempts Louisiana catalog and report imports every '
            'six hours. Agency publication cadence is unconfirmed. Scratch '
            'inventory uses each game detail timestamp; the top-prize report '
            'timestamp governs candidate discovery only. Draw dates and printed '
            'source update timestamps remain separate, with warnings where they '
            'conflict. Failed refreshes retain previous verified data and dates.';
      case 'North Carolina':
        return 'The official high-prize winner archive is updated weekly. '
            'Scratch-Off remaining prizes are updated daily through the stated '
            'source date; Reordered status can increase inventory counts. '
            'Draw reports retain their individual draw dates and retrieval time. '
            'Failed refreshes retain the previous verified data and dates.';
      case 'Texas':
        return 'Lottery Atlas attempts Texas imports every six hours. '
            'This is our refresh schedule, not a guaranteed Texas Lottery '
            'publication schedule. Source update cadence is unconfirmed; '
            'check each record or catalog date. Failed refreshes retain '
            'previous verified data and its original dates.';
      case 'Kentucky':
        return 'Lottery Atlas attempts Kentucky imports every six hours. '
            'Agency publication cadence is unconfirmed; current and retained '
            'winner listings cover different periods. Check each source date. '
            'Failed refreshes retain previous verified data and original dates.';
      case 'Tennessee':
        return 'Tennessee updates its published top-tier remaining prizes weekly. '
            'The totals include one prize per game reserved for a Play It Again! '
            'second-chance drawing. They do not establish prizes still available '
            'in tickets for sale or retailer stock; check the report date.';
      case 'Iowa':
        return 'Iowa retailer data is published weekly by the state. '
            'Winner and Scratch-Off data may follow different schedules. '
            'Check each official source date before treating the map as current.';
      case 'Missouri':
        return 'Missouri retailer-level winner releases are published monthly. '
            'The latest available month may lag the current date.';
      case 'Nebraska':
        return 'Nebraska results and catalog imports are attempted every six hours. '
            'Report dates differ from retrieval time. The manually reviewed September 13 '
            'Scratch inventory does not advance automatically; failed refreshes retain prior data.';
      default:
        return null;
    }
  }
}
