/// Verified source and agency-response limits.
/// Keep access limitations separate from source cadence and app readiness.
class StateDataLimitationRegistry {
  StateDataLimitationRegistry._();

  static String? noticeFor(String stateName) {
    final reason = switch (stateName) {
      'Texas' =>
        'Mapped 2026 activity includes selected Scratch top-prize claims with '
            'verified selling-retailer matches, plus selected Powerball and Mega Millions '
            'second-tier records and selected Lotto Texas, Texas Two Step, Cash Five and All or Nothing top-tier Where Sold records with exact address matches. Scratch '
            'records use claim dates; draw records use draw dates, with no verified '
            'time of day. Scratch selling-retailer reports include fully processed claims; '
            'recently filed claims can appear in game-page counts before these reports. '
            'Draw maps exclude other tiers, unverified locations and advertised shared jackpots. '
            'This is not an all-tier statewide feed. '
            'The retailer directory is separate and does not establish wins.',
      'Kentucky' =>
        'Mapped activity includes selected official winner notices with verified '
            'retailer matches, including retained historical listings. This is '
            'not a complete winner archive or an all-tier statewide count. '
            'Unmatched locations are excluded. The retailer directory is separate '
            'and does not establish wins; notice dates do not establish a sale time.',
      'Arkansas' =>
        'The lottery declined our records request because Arkansas citizenship '
            'was not established.',
      'Georgia' =>
        'The lottery declined the requested compilation, citing records it '
            'does not maintain and restrictions on nonpublic lottery information.',
      'Oklahoma' =>
        'The lottery said some requested reports do not exist and other '
            'information is restricted for privacy and security reasons.',
      'Rhode Island' =>
        'The lottery supplied an active retailer directory dated September 15, 2026. '
            'Requested winning-ticket data requires paid assembly that has not '
            'been authorized, and ticket identifiers will not be provided.',
      'Wyoming' =>
        'The lottery declined requested ticket records, a retailer-list export '
            'and retailer joins, directing us to its public winner and retailer pages. '
            'Wyoming offers no Scratch or instant-ticket games.',
      'North Dakota' =>
        'The lottery reports that it does not track lower-tier prizes. '
            'Public winner listings cover only a subset of prizes.',
      'New York' =>
        'The Gaming Commission says it maintains claims data only for prizes '
            'of \$600 or more. Its records response does not cover lower-tier prizes.',
      _ => null,
    };
    if (reason == null) return null;
    return 'Limited data coverage — $reason '
        'Lottery Atlas uses available verified public information. '
        'Displayed activity and rankings cover only the records shown, not '
        'all statewide wins or retailers. Missing data does not mean zero wins. '
        'Prize inventory is not store stock or a dated winning-ticket count. '
        'Check each source date and coverage note.';
  }
}
