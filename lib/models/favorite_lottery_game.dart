import 'dart:convert';

/// The destination to use when a saved game is opened from Favorites.
///
/// `draw` remains for previously saved game filters, while the more specific
/// national and state draw kinds provide a direct route to their source.
enum FavoriteLotteryGameKind { scratchOff, draw, nationalDraw, stateDraw }

class FavoriteLotteryGame {
  const FavoriteLotteryGame({
    required this.key,
    required this.gameId,
    required this.name,
    required this.subtitle,
    required this.kind,
  });

  final String key;
  final String gameId;
  final String name;
  final String subtitle;
  final FavoriteLotteryGameKind kind;

  Map<String, dynamic> toJson() => {
    'key': key,
    'gameId': gameId,
    'name': name,
    'subtitle': subtitle,
    'kind': kind.name,
  };

  String encode() => jsonEncode(toJson());

  factory FavoriteLotteryGame.decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Favorite game is invalid.');
    }
    final json = Map<String, dynamic>.from(decoded);
    final key = json['key']?.toString().trim() ?? '';
    final gameId = json['gameId']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    final subtitle = json['subtitle']?.toString().trim() ?? '';
    final kind = FavoriteLotteryGameKind.values.where(
      (value) => value.name == json['kind']?.toString(),
    );
    if (key.isEmpty ||
        gameId.isEmpty ||
        name.isEmpty ||
        subtitle.isEmpty ||
        kind.isEmpty) {
      throw const FormatException('Favorite game is missing information.');
    }
    return FavoriteLotteryGame(
      key: key,
      gameId: gameId,
      name: name,
      subtitle: subtitle,
      kind: kind.first,
    );
  }
}
