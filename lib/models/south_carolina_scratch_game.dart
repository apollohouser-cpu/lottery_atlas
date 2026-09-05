class SouthCarolinaScratchPrizeTier {
  const SouthCarolinaScratchPrizeTier({
    required this.amount,
    required this.claimedYesterday,
  });

  final int amount;
  final int claimedYesterday;

  factory SouthCarolinaScratchPrizeTier.fromJson(Map<String, dynamic> json) {
    final amount = _asInt(json['amount']);
    final claimedYesterday = _asInt(json['claimedYesterday']);
    if (amount == null ||
        amount < 1 ||
        claimedYesterday == null ||
        claimedYesterday < 0) {
      throw const FormatException('A Scratch-Off prize tier is invalid.');
    }
    return SouthCarolinaScratchPrizeTier(
      amount: amount,
      claimedYesterday: claimedYesterday,
    );
  }
}

class SouthCarolinaScratchGame {
  const SouthCarolinaScratchGame({
    required this.id,
    required this.name,
    required this.prizeTiers,
    this.groupedOfficialEntries = 1,
  });

  final String id;
  final String name;
  final List<SouthCarolinaScratchPrizeTier> prizeTiers;

  /// A few official entries share the same public game title but are listed
  /// separately without a game number. Those are shown as one grouped entry.
  final int groupedOfficialEntries;

  factory SouthCarolinaScratchGame.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    final rawTiers = json['prizeTiers'];
    final groupedOfficialEntries = _asInt(json['groupedOfficialEntries']) ?? 1;
    if (id.isEmpty ||
        name.isEmpty ||
        rawTiers is! List ||
        groupedOfficialEntries < 1) {
      throw const FormatException('A Scratch-Off game is invalid.');
    }

    final prizeTiers = <SouthCarolinaScratchPrizeTier>[];
    final seenPrizeAmounts = <int>{};
    for (final item in rawTiers) {
      if (item is! Map) {
        throw const FormatException('A Scratch-Off prize tier is invalid.');
      }
      final prizeTier = SouthCarolinaScratchPrizeTier.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (!seenPrizeAmounts.add(prizeTier.amount)) {
        throw const FormatException(
          'A Scratch-Off game repeats a prize tier.',
        );
      }
      prizeTiers.add(prizeTier);
    }
    if (prizeTiers.isEmpty) {
      throw const FormatException('A Scratch-Off game has no prize tiers.');
    }

    return SouthCarolinaScratchGame(
      id: id,
      name: name,
      prizeTiers: prizeTiers,
      groupedOfficialEntries: groupedOfficialEntries,
    );
  }

  int get topPrize =>
      prizeTiers.map((tier) => tier.amount).reduce((a, b) => a > b ? a : b);

  int get claimedYesterday =>
      prizeTiers.fold(0, (total, tier) => total + tier.claimedYesterday);

  List<SouthCarolinaScratchPrizeTier> matchingTiers({
    required int minimumPrize,
    required int maximumPrize,
  }) {
    return prizeTiers
        .where(
          (tier) => tier.amount >= minimumPrize && tier.amount <= maximumPrize,
        )
        .toList()
      ..sort((a, b) => a.amount.compareTo(b.amount));
  }

  int claimsInRange({required int minimumPrize, required int maximumPrize}) {
    return matchingTiers(
      minimumPrize: minimumPrize,
      maximumPrize: maximumPrize,
    ).fold(0, (total, tier) => total + tier.claimedYesterday);
  }

  String get displayName => groupedOfficialEntries > 1
      ? '$name ($groupedOfficialEntries games)'
      : name;
}

int? _asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
