import 'dart:convert';

enum FavoritePlaceKind { state, county, retailer }

class FavoritePlace {
  const FavoritePlace({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.stateName,
    this.countyId,
    this.retailerId,
  });

  final String key;
  final String title;
  final String subtitle;
  final FavoritePlaceKind kind;
  final String stateName;
  final String? countyId;
  final String? retailerId;

  String encode() => jsonEncode({
    'key': key,
    'title': title,
    'subtitle': subtitle,
    'kind': kind.name,
    'stateName': stateName,
    'countyId': countyId,
    'retailerId': retailerId,
  });

  factory FavoritePlace.decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('Favorite place is invalid.');
    final json = Map<String, dynamic>.from(decoded);
    final key = json['key']?.toString().trim() ?? '';
    final title = json['title']?.toString().trim() ?? '';
    final subtitle = json['subtitle']?.toString().trim() ?? '';
    final stateName = json['stateName']?.toString().trim() ?? '';
    final matches = FavoritePlaceKind.values.where(
      (kind) => kind.name == json['kind']?.toString(),
    );
    final countyId = json['countyId']?.toString().trim();
    final retailerId = json['retailerId']?.toString().trim();
    if (key.isEmpty ||
        title.isEmpty ||
        subtitle.isEmpty ||
        stateName.isEmpty ||
        matches.isEmpty) {
      throw const FormatException('Favorite place is missing information.');
    }
    return FavoritePlace(
      key: key,
      title: title,
      subtitle: subtitle,
      kind: matches.first,
      stateName: stateName,
      countyId: countyId?.isEmpty == true ? null : countyId,
      retailerId: retailerId?.isEmpty == true ? null : retailerId,
    );
  }
}
