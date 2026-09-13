class StateWinningTicketTotal {
  const StateWinningTicketTotal({
    required this.state,
    required this.count,
    required this.periodStart,
    required this.periodEnd,
    required this.sourceDate,
    required this.sourceUrl,
    required this.coverage,
  });

  final String state;
  final int count;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime sourceDate;

  /// Exact included games and prize tiers; counts are never assumed complete.
  final String coverage;
  final String sourceUrl;

  static StateWinningTicketTotal? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final state = raw['state'];
    final count = raw['winningTickets'];
    final start = DateTime.tryParse(raw['periodStart']?.toString() ?? '');
    final end = DateTime.tryParse(raw['periodEnd']?.toString() ?? '');
    final sourceDate = DateTime.tryParse(raw['sourceDate']?.toString() ?? '');
    final sourceUrl = raw['sourceUrl'];
    final coverage = raw['coverage'];
    if (state is! String ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(state) ||
        count is! int ||
        count < 0 ||
        start == null ||
        end == null ||
        sourceDate == null ||
        end.isBefore(start) ||
        sourceDate.isBefore(end) ||
        sourceUrl is! String ||
        Uri.tryParse(sourceUrl)?.scheme != 'https' ||
        coverage is! String ||
        coverage.trim().isEmpty) {
      return null;
    }
    return StateWinningTicketTotal(
      state: state,
      count: count,
      periodStart: start,
      periodEnd: end,
      sourceDate: sourceDate,
      sourceUrl: sourceUrl,
      coverage: coverage.trim(),
    );
  }
}
