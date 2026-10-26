/// Estimated top-prize continuity. Source wall time has no published timezone.
class NewMexicoScratchValidator {
  static DateTime _day(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Invalid Scratch date');
    }
    final d = DateTime.parse(value);
    if (d.toIso8601String().substring(0, 10) != value) {
      throw const FormatException('Invalid calendar day');
    }
    return d;
  }

  static DateTime _wall(Map catalog) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final value = catalog['sourceTimestamp'];
    if (value is! String) {
      throw const FormatException('Missing literal source time');
    }
    final m = RegExp(
      r'^([A-Za-z]+) (\d{2}), (\d{4}) (\d{2}):(\d{2}) (AM|PM)$',
    ).firstMatch(value);
    if (m == null || !months.contains(m[1])) {
      throw const FormatException('Invalid literal source time');
    }
    final hour = int.parse(m[4]!);
    final minute = int.parse(m[5]!);
    if (hour < 1 || hour > 12 || minute > 59) {
      throw const FormatException('Invalid wall clock');
    }
    final day = _day(catalog['sourceDate']);
    if (day.year != int.parse(m[3]!) ||
        day.month != months.indexOf(m[1]!) + 1 ||
        day.day != int.parse(m[2]!)) {
      throw const FormatException('Literal timestamp/date mismatch');
    }
    // Used only to compare two literal wall times, never interpreted as UTC.
    return DateTime(
      day.year,
      day.month,
      day.day,
      hour % 12 + (m[6] == 'PM' ? 12 : 0),
      minute,
    );
  }

  static void normalize(Map candidate, Map prior, String queryEnd) {
    if (_wall(candidate).isBefore(_wall(prior))) {
      throw const FormatException('Scratch source clock regression');
    }
    if (_day(candidate['sourceDate']).isAfter(_day(queryEnd))) {
      throw const FormatException(
        'Scratch source day beyond collection window',
      );
    }
    final oldGames = prior['games'] as List;
    final games = candidate['games'] as List;
    final byId = <String, Map>{};
    for (final g in games) {
      if (g['id'] is! String || byId.containsKey(g['id'])) {
        throw const FormatException('Duplicate Scratch identity');
      }
      byId[g['id']] = g as Map;
    }
    final excluded = candidate['excludedExpiredGameIds'] as List;
    if (excluded.toSet().length != excluded.length ||
        !excluded.every((v) => v is String)) {
      throw const FormatException('Invalid expired identity list');
    }
    final expectedExcluded = (prior['excludedExpiredGameIds'] as List).toSet();
    final normalizedGames = <Map>[];
    for (final old in oldGames) {
      final game = byId.remove(old['id']);
      if (game == null) {
        if (old['lastDayToRedeem'] == null ||
            !_day(old['lastDayToRedeem']).isBefore(_day(queryEnd))) {
          throw const FormatException('Unexpired Scratch identity lost');
        }
        expectedExcluded.add(old['id']);
        normalizedGames.add(Map.from(old));
        continue;
      }
      final count = game['topPrizesRemaining'];
      if (count is! int || count < 0 || count > old['topPrizesRemaining']) {
        throw const FormatException('Estimated inventory increased or unknown');
      }
      final expectedNote = (old['inventoryNote'] as String).replaceAll(
        prior['sourceTimestamp'],
        candidate['sourceTimestamp'],
      );
      if (game['inventoryNote'] != expectedNote) {
        throw const FormatException('Inventory interpretation changed');
      }
      game['topPrizesRemaining'] = old['topPrizesRemaining'];
      game['inventoryNote'] = old['inventoryNote'];
      normalizedGames.add(game);
    }
    if (byId.isNotEmpty ||
        excluded.toSet().difference(expectedExcluded).isNotEmpty ||
        expectedExcluded.difference(excluded.toSet()).isNotEmpty) {
      throw const FormatException('Unreviewed Scratch catalog membership');
    }
    candidate['games'] = normalizedGames;
    candidate['excludedExpiredGameIds'] = prior['excludedExpiredGameIds'];
    candidate['sourceDate'] = prior['sourceDate'];
    candidate['sourceTimestamp'] = prior['sourceTimestamp'];
  }
}
