import 'dart:convert';

class IowaInventoryValidator {
  static void need(bool ok) {
    if (!ok) throw const FormatException('Invalid Iowa inventory');
  }

  static void exact(dynamic a, dynamic b) =>
      need(jsonEncode(a) == jsonEncode(b));
  static DateTime date(dynamic v) {
    need(v is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v));
    final d = DateTime.tryParse(v);
    need(d != null && d.toIso8601String().substring(0, 10) == v);
    return d!;
  }

  static void count(dynamic n) =>
      need(n is int && n >= 0 && n <= 9007199254740991);
  static Map<String, dynamic> index(dynamic inventory) {
    final result = <String, dynamic>{};
    for (final subset in inventory['inventories']) {
      for (final game in subset['games']) {
        final key = '${subset['productType']}:${game['id']}';
        need(!result.containsKey(key));
        result[key] = game;
      }
    }
    return result;
  }

  static void validate(
    dynamic inventory,
    dynamic scratch,
    dynamic template,
    DateTime cutoff,
  ) {
    exact(inventory['state'], 'Iowa');
    exact(inventory['sourceUrl'], template['instantInventories']['sourceUrl']);
    exact(inventory['coverage'], template['instantInventories']['coverage']);
    final source = date(inventory['sourceDate']);
    need(!source.isAfter(cutoff));
    final subsets = inventory['inventories'] as List;
    need(subsets.length == 3);
    final types = <String>{};
    for (final subset in subsets) {
      final kind = subset['productType'] as String;
      need(
        ['Scratch', 'InstaPlay', 'PullTab'].contains(kind) && types.add(kind),
      );
      final spec = (template['instantInventories']['inventories'] as List)
          .firstWhere((s) => s['productType'] == kind);
      exact(subset['officialRoute'], spec['officialRoute']);
      final games = subset['games'] as List;
      need(games.isNotEmpty);
      for (final game in games) {
        exact(game['productType'], kind);
        need(game['id'] is String && RegExp(r'^\d+$').hasMatch(game['id']));
        need(
          game['name'] is String && (game['name'] as String).trim().isNotEmpty,
        );
        count(game['cost']);
        need(game['cost'] > 0);
        final tiers = game['prizeTiers'] as List;
        need(tiers.isNotEmpty);
        final amounts = <int>{};
        for (final tier in tiers) {
          count(tier['prizeAmount']);
          need(tier['prizeAmount'] >= 50 && amounts.add(tier['prizeAmount']));
          count(tier['claimed']);
          count(tier['unclaimed']);
        }
        need(!game.containsKey('topPrize'));
      }
    }
    final indexed = index(inventory);
    exact(scratch['state'], 'Iowa');
    exact(scratch['source'], inventory['sourceUrl']);
    exact(scratch['sourceDate'], inventory['sourceDate']);
    exact(scratch['coverage'], template['scratchCatalog']['coverage']);
    exact(
      scratch['updateCadence'],
      template['scratchCatalog']['updateCadence'],
    );
    final games = scratch['games'] as List;
    need(
      games.length ==
          indexed.keys.where((k) => k.startsWith('Scratch:')).length,
    );
    final ids = <String>{};
    for (final game in games) {
      need(ids.add(game['id']));
      final typed = indexed['Scratch:${game['id']}'];
      need(typed != null);
      for (final key in ['id', 'name', 'cost', 'prizeTiers']) {
        exact(game[key], typed[key]);
      }
      exact(game['stateName'], 'Iowa');
      exact(
        game['sourceUrl'],
        'https://www.ialottery.com/Pages/Games-Scratch/ScratchGamesDetail.aspx?g=${game['id']}',
      );
      final tiers = game['prizeTiers'] as List;
      final top = tiers.reduce(
        (a, b) => a['prizeAmount'] > b['prizeAmount'] ? a : b,
      );
      exact(game['topPrize'], top['prizeAmount']);
      exact(game['topPrizesRemaining'], top['unclaimed']);
      final start = date(game['startDate']);
      for (final key in [
        'endDistributionDate',
        'gameEndDate',
        'lastDayToRedeem',
      ]) {
        if (game.containsKey(key)) need(!date(game[key]).isBefore(start));
      }
      var note =
          'Inventory through ${inventory['sourceDate']}; published tiers \$50 or more only. Cumulative counts, not 2026 winning tickets. Store availability unverified.';
      for (final entry in {
        'endDistributionDate': 'Distribution ended',
        'gameEndDate': 'Game ends',
        'lastDayToRedeem': 'Redeem by',
      }.entries) {
        if (game.containsKey(entry.key)) {
          note += ' ${entry.value} ${game[entry.key]}.';
        }
      }
      exact(game['inventoryNote'], note);
    }
  }

  static void continuity(dynamic old, dynamic next) {
    final a = old['instantInventories'], b = next['instantInventories'];
    need(!date(b['sourceDate']).isBefore(date(a['sourceDate'])));
    if (a['sourceDate'] == b['sourceDate']) {
      exact(a, b);
      exact(old['scratchCatalog'], next['scratchCatalog']);
    }
    final newer = index(b);
    for (final entry in index(a).entries) {
      final game = newer[entry.key];
      need(game != null);
      exact(game['name'], entry.value['name']);
      exact(game['cost'], entry.value['cost']);
      final tiers = {for (final t in game['prizeTiers']) t['prizeAmount']: t};
      for (final prior in entry.value['prizeTiers']) {
        final current = tiers[prior['prizeAmount']];
        need(current != null);
        need(
          current['claimed'] >= prior['claimed'] &&
              current['unclaimed'] <= prior['unclaimed'],
        );
      }
    }
  }
}
