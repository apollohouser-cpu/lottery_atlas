import 'dart:convert';
import 'new_mexico_coverage_contract.dart';

class NewMexicoReportValidator {
  static final List _templates =
      (jsonDecode(newMexicoCoverageContractJson)['results'] as List)
          .where((r) => r['report'] != null)
          .map((r) => r['report'])
          .toList();
  static String canonical(dynamic value) {
    dynamic sorted(dynamic v) {
      if (v is Map) {
        return {
          for (final k in (v.keys.cast<String>().toList()..sort()))
            k: sorted(v[k]),
        };
      }
      if (v is List) {
        return v.map(sorted).toList();
      }
      return v;
    }

    return jsonEncode(sorted(value));
  }

  static int money(String label) {
    final compact = RegExp(
      r'^\$([1-9][0-9]*) (Million|Thousand)$',
    ).firstMatch(label);
    if (compact != null) {
      return int.parse(compact[1]!) *
          (compact[2] == 'Million' ? 1000000 : 1000);
    }
    if (!RegExp(
      r'^\$(?:0|[1-9][0-9]*|[1-9][0-9]{0,2}(?:,[0-9]{3})+)$',
    ).hasMatch(label)) {
      throw const FormatException('Invalid report money label');
    }
    return int.parse(label.substring(1).replaceAll(',', ''));
  }

  static void validate(Map draw) {
    final report = draw['report'];
    if (report == null) {
      return;
    }
    final matches = _templates.where(
      (t) => t['game'] == draw['game'] && t['variant'] == draw['variant'],
    );
    if (matches.length != 1 || draw['session'] != null) {
      throw const FormatException('Unsupported report identity');
    }
    final template = matches.single as Map;
    final normalized = jsonDecode(jsonEncode(report)) as Map;
    if (report['date'] != draw['date'] ||
        report['game'] != draw['game'] ||
        report['variant'] != draw['variant'] ||
        report['session'] != null) {
      throw const FormatException('Report/result join mismatch');
    }
    normalized['date'] = template['date'];
    normalized['retrievedAt'] = template['retrievedAt'];
    final paired = template.containsKey('multiplier');
    if (paired) {
      if (report['multiplier'] != draw['multiplier']) {
        throw const FormatException('Report multiplier mismatch');
      }
      normalized['multiplier'] = template['multiplier'];
    }
    final tiers = report['tiers'] as List;
    final expected = template['tiers'] as List;
    if (tiers.length != expected.length) {
      throw const FormatException('Report tier set changed');
    }
    var total = 0;
    var cash = 0;
    for (var i = 0; i < tiers.length; i++) {
      final t = tiers[i] as Map, e = expected[i] as Map;
      final count = t['sourceWinners'];
      if (count is! int || count < 0) {
        throw const FormatException('Invalid source Winners');
      }
      var prize = e['prizeValue'];
      if (paired && i > 0 && i.isEven) {
        final base = expected[i - 1]['prizeValue'] as int;
        prize = draw['game'] == 'powerball' && i == 2
            ? 2000000
            : base * (draw['multiplier'] as int);
      }
      if (t['prizeValue'] != prize || (prize == null && count != 0)) {
        throw const FormatException('Unverified prize or jackpot award');
      }
      if (prize != null &&
          (t['prizeLabel'] is! String || money(t['prizeLabel']) != prize)) {
        throw const FormatException('Prize label mismatch');
      }
      final n = normalized['tiers'][i] as Map;
      n['sourceWinners'] = e['sourceWinners'];
      // Paired source permits literal numeric or Million/Thousand labels.
      if (paired && prize != null) {
        n['prizeLabel'] = e['prizeLabel'];
        n['prizeValue'] = e['prizeValue'];
      }
      total += count;
      cash += count * ((prize as int?) ?? 0);
    }
    if (report['totalPrizesWon'] is! int ||
        report['totalPrizeValue'] is! int ||
        report['totalPrizesWon'] != total ||
        report['totalPrizeValue'] != cash) {
      throw const FormatException('Report totals do not reconcile');
    }
    normalized['totalPrizesWon'] = template['totalPrizesWon'];
    normalized['totalPrizeValue'] = template['totalPrizeValue'];
    if (canonical(normalized) != canonical(template)) {
      throw const FormatException(
        'Report schema units or tier identity changed',
      );
    }
  }

  static void continuity(List prior, List next) {
    for (final row in next) {
      validate(row as Map);
      final old = prior.where(
        (r) =>
            r['game'] == row['game'] &&
            r['variant'] == row['variant'] &&
            r['session'] == row['session'] &&
            r['date'] == row['date'],
      );
      if (old.isNotEmpty && old.single['report'] != null) {
        if (row['report'] == null) {
          throw const FormatException('Published report lost');
        }
        Map fixed(Map r) => Map.from(r)..remove('retrievedAt');
        if (canonical(fixed(old.single['report'])) !=
            canonical(fixed(row['report']))) {
          throw const FormatException('Published report corrected');
        }
        if (DateTime.parse(
          row['report']['retrievedAt'],
        ).isBefore(DateTime.parse(old.single['report']['retrievedAt']))) {
          throw const FormatException('Report capture regressed');
        }
      }
    }
  }
}
