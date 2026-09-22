/// Agency-confirmed limits, reviewed September 22, 2026.
/// Keep access limitations separate from source cadence and app readiness.
class StateDataLimitationRegistry {
  StateDataLimitationRegistry._();

  static String? noticeFor(String stateName) {
    final reason = switch (stateName) {
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
