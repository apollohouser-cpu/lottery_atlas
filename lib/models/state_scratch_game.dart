/// A verified Scratch-Off ticket from a state lottery's official catalog.
///
/// Unlike a map-activity record, catalog data describes the ticket itself. It
/// must not be treated as proof of a winning ticket's retailer location.
class StateScratchGame {
  const StateScratchGame({
    required this.stateName,
    required this.id,
    required this.name,
    required this.cost,
    required this.topPrize,
    this.topPrizeLabel,
    this.topPrizesRemaining,
  });

  final String stateName;
  final String id;
  final String name;
  final int cost;
  final int topPrize;

  /// Optional official non-cash label for a top prize, such as a vehicle.
  /// [topPrize] remains the highest cash prize for amount-based filtering.
  final String? topPrizeLabel;

  /// Null when the official catalog does not publish a current count.
  final int? topPrizesRemaining;

  /// Parses one verified ticket from a published state catalog feed.
  ///
  /// The feed deliberately requires the fields that are displayed in the app,
  /// so a partial search result can never become an apparently complete
  /// Scratch-Off ticket. This catalog record is still not retailer activity.
  factory StateScratchGame.fromJson(Map<String, dynamic> json) {
    final stateName = json['stateName']?.toString().trim() ?? '';
    final id = (json['id'] ?? json['gameNumber'])?.toString().trim() ?? '';
    final name = (json['name'] ?? json['gameName'])?.toString().trim() ?? '';
    final cost = _integer(json['cost'] ?? json['price']);
    final topPrize = _integer(json['topPrize']);
    final topPrizeLabel = json['topPrizeLabel']?.toString().trim();
    final topPrizesRemaining = _integer(json['topPrizesRemaining']);

    if (stateName.isEmpty ||
        id.isEmpty ||
        name.isEmpty ||
        cost == null ||
        topPrize == null ||
        cost <= 0 ||
        topPrize < 0 ||
        (topPrizesRemaining != null && topPrizesRemaining < 0)) {
      throw const FormatException(
        'A Scratch-Off catalog game has missing or invalid fields.',
      );
    }

    return StateScratchGame(
      stateName: stateName,
      id: id,
      name: name,
      cost: cost,
      topPrize: topPrize,
      topPrizeLabel: topPrizeLabel == null || topPrizeLabel.isEmpty
          ? null
          : topPrizeLabel,
      topPrizesRemaining: topPrizesRemaining,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'stateName': stateName,
    'id': id,
    'name': name,
    'cost': cost,
    'topPrize': topPrize,
    'topPrizeLabel': topPrizeLabel,
    'topPrizesRemaining': topPrizesRemaining,
  };

  static int? _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
