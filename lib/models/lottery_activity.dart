import 'package:latlong2/latlong.dart';

import '../widgets/map/map_filter_state.dart';

/// A location-based lottery result or activity record.
///
/// This is the model that future official lottery adapters will populate.
class LotteryActivity {
  const LotteryActivity({
    required this.id,
    required this.location,
    required this.city,
    required this.county,
    required this.state,
    required this.game,
    required this.drawDate,
    required this.winningTickets,
    required this.prizeAmount,
    this.gameName,
    this.retailerName,
    this.retailerAddress,
    this.sourceUrl,
    this.sourceLabel,
    this.isHistorical = false,
    this.isFavorite = false,
  });

  final String id;
  final LatLng location;
  final String city;
  final String county;
  final String state;
  final LotteryGame game;
  final DateTime drawDate;
  final int winningTickets;
  final int prizeAmount;
  final String? gameName;

  /// The retailer that sold the ticket, when the official source publishes it.
  /// This remains optional because many state winner reports disclose only a
  /// winner's home city or a claim office.
  final String? retailerName;
  final String? retailerAddress;

  /// A direct official page supporting this individual record, when one is
  /// available. Historical records should include this rather than relying on
  /// a general current-results page.
  final String? sourceUrl;
  final String? sourceLabel;
  final bool isHistorical;
  final bool isFavorite;

  /// Parses one published map-activity record from the app's remote feed.
  /// A feed must use the game codes documented in [_gameFromCode].
  factory LotteryActivity.fromJson(
    Map<String, dynamic> json, {
    bool defaultIsHistorical = false,
  }) {
    final id = json['id']?.toString().trim() ?? '';
    final city = json['city']?.toString().trim() ?? '';
    final county = json['county']?.toString().trim() ?? '';
    final state = json['state']?.toString().trim().toUpperCase() ?? '';
    final latitude = _number(json['latitude']);
    final longitude = _number(json['longitude']);
    final drawDate = DateTime.tryParse(json['drawDate']?.toString() ?? '');
    final winningTickets = _integer(json['winningTickets']);
    final prizeAmount = _integer(json['prizeAmount']);
    final rawGameName = json['gameName']?.toString().trim();
    final rawRetailerName = json['retailerName']?.toString().trim();
    final rawRetailerAddress = json['retailerAddress']?.toString().trim();
    final rawSourceUrl = json['sourceUrl']?.toString().trim();
    final rawSourceLabel = json['sourceLabel']?.toString().trim();

    if (id.isEmpty ||
        city.isEmpty ||
        county.isEmpty ||
        state.length != 2 ||
        latitude == null ||
        longitude == null ||
        drawDate == null ||
        winningTickets == null ||
        prizeAmount == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        winningTickets < 0 ||
        prizeAmount < 0) {
      throw const FormatException(
        'A map activity record has missing or invalid fields.',
      );
    }

    return LotteryActivity(
      id: id,
      location: LatLng(latitude, longitude),
      city: city,
      county: county,
      state: state,
      game: _gameFromCode(json['game']?.toString()),
      drawDate: drawDate.toLocal(),
      winningTickets: winningTickets,
      prizeAmount: prizeAmount,
      gameName: rawGameName == null || rawGameName.isEmpty ? null : rawGameName,
      retailerName: rawRetailerName == null || rawRetailerName.isEmpty
          ? null
          : rawRetailerName,
      retailerAddress: rawRetailerAddress == null || rawRetailerAddress.isEmpty
          ? null
          : rawRetailerAddress,
      sourceUrl: rawSourceUrl == null || rawSourceUrl.isEmpty
          ? null
          : rawSourceUrl,
      sourceLabel: rawSourceLabel == null || rawSourceLabel.isEmpty
          ? null
          : rawSourceLabel,
      isHistorical: json['isHistorical'] == true || defaultIsHistorical,
      isFavorite: json['isFavorite'] == true,
    );
  }

  /// Writes this record in the same portable schema accepted by [fromJson].
  /// This lets Lottery Atlas safely cache one merged result when activity is
  /// loaded from several independent state feeds.
  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': location.latitude,
    'longitude': location.longitude,
    'city': city,
    'county': county,
    'state': state,
    'game': _gameCode(game),
    'gameName': gameName,
    'retailerName': retailerName,
    'retailerAddress': retailerAddress,
    'drawDate': drawDate.toIso8601String(),
    'winningTickets': winningTickets,
    'prizeAmount': prizeAmount,
    'sourceUrl': sourceUrl,
    'sourceLabel': sourceLabel,
    'isHistorical': isHistorical,
    'isFavorite': isFavorite,
  };

  static LotteryGame _gameFromCode(String? code) {
    switch (code?.trim().toLowerCase()) {
      case 'powerball':
        return LotteryGame.powerball;
      case 'mega-millions':
      case 'megamillions':
        return LotteryGame.megaMillions;
      case 'scratch-off':
      case 'scratchoff':
        return LotteryGame.scratchOff;
      case 'state-draw':
      case 'statedraw':
        return LotteryGame.stateDraw;
      default:
        throw const FormatException('The map activity game code is unknown.');
    }
  }

  static String _gameCode(LotteryGame game) {
    switch (game) {
      case LotteryGame.allGames:
        throw StateError('All Games cannot be stored as an activity record.');
      case LotteryGame.powerball:
        return 'powerball';
      case LotteryGame.megaMillions:
        return 'mega-millions';
      case LotteryGame.scratchOff:
        return 'scratch-off';
      case LotteryGame.stateDraw:
        return 'state-draw';
    }
  }

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  bool get hasWinningActivity => winningTickets > 0;

  String get formattedPrizeAmount {
    if (prizeAmount >= 1000000) {
      final millions = prizeAmount / 1000000;
      return '\$${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M';
    }
    if (prizeAmount >= 1000) {
      return '\$${(prizeAmount / 1000).toStringAsFixed(0)}K';
    }
    return '\$$prizeAmount';
  }

  double get radius {
    if (winningTickets >= 100) return 18;
    if (winningTickets >= 50) return 15;
    if (winningTickets >= 20) return 12;
    if (winningTickets >= 5) return 9;
    return 6;
  }
}
