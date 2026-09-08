import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/lottery_activity.dart';
import 'state_navigation_service.dart';
import '../widgets/map/map_filter_state.dart';

enum MapRankingLevel { state, county, city, retailer, game }

class MapRankingSnapshot {
  const MapRankingSnapshot({
    required this.records,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.countyIds,
    this.stateName,
    this.stateAbbreviation,
    this.countyName,
    this.countyId,
    this.cityName,
    this.retailerName,
    this.retailerAddress,
  });

  factory MapRankingSnapshot.empty() {
    final now = DateTime.now();
    return MapRankingSnapshot(
      records: const <LotteryActivity>[],
      dateRangeStart: DateTime(now.year, now.month, now.day),
      dateRangeEnd: now,
      countyIds: const <String, String>{},
    );
  }

  final List<LotteryActivity> records;
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final Map<String, String> countyIds;
  final String? stateName;
  final String? stateAbbreviation;
  final String? countyName;
  final String? countyId;
  final String? cityName;
  final String? retailerName;
  final String? retailerAddress;

  MapRankingLevel get level {
    if (retailerName != null) return MapRankingLevel.game;
    if (cityName != null) return MapRankingLevel.retailer;
    if (countyName != null) return MapRankingLevel.city;
    if (stateName != null) return MapRankingLevel.county;
    return MapRankingLevel.state;
  }

  String get signature {
    final recordSignature = records.map((record) => record.id).toList()..sort();
    return <Object?>[
      dateRangeStart.microsecondsSinceEpoch,
      dateRangeEnd.microsecondsSinceEpoch,
      stateName,
      countyName,
      cityName,
      retailerName,
      retailerAddress,
      ...recordSignature,
    ].join('|');
  }
}

class MapRankingEntry {
  const MapRankingEntry({
    required this.key,
    required this.label,
    required this.records,
    required this.winningTickets,
    required this.publishedPrizeTotal,
    required this.gameBreakdown,
    required this.location,
    this.stateName,
    this.countyId,
    this.retailerActivityId,
  });

  final String key;
  final String label;
  final int records;
  final int winningTickets;
  final int publishedPrizeTotal;
  final Map<String, int> gameBreakdown;
  final LatLng location;
  final String? stateName;
  final String? countyId;
  final String? retailerActivityId;
}

class MapRankingService {
  MapRankingService._();

  static final ValueNotifier<MapRankingSnapshot> snapshot =
      ValueNotifier<MapRankingSnapshot>(MapRankingSnapshot.empty());

  static String _lastSignature = snapshot.value.signature;

  static void publish(MapRankingSnapshot next) {
    final signature = next.signature;
    if (signature == _lastSignature) return;
    _lastSignature = signature;
    snapshot.value = next;
  }

  static List<MapRankingEntry> rankings(MapRankingSnapshot source) {
    final scopedRecords = source.records.where((record) {
      if (source.stateAbbreviation != null &&
          record.state != source.stateAbbreviation) {
        return false;
      }
      if (source.countyName != null &&
          _normalize(record.county) != _normalize(source.countyName!)) {
        return false;
      }
      if (source.cityName != null &&
          _normalize(record.city) != _normalize(source.cityName!)) {
        return false;
      }
      if (source.retailerName != null &&
          (_normalize(record.retailerName ?? '') !=
                  _normalize(source.retailerName!) ||
              (source.retailerAddress != null &&
                  _normalize(record.retailerAddress ?? '') !=
                      _normalize(source.retailerAddress!)))) {
        return false;
      }
      return true;
    });

    final groups = <String, List<LotteryActivity>>{};
    for (final record in scopedRecords) {
      final key = switch (source.level) {
        MapRankingLevel.state => record.state,
        MapRankingLevel.county => _normalize(record.county),
        MapRankingLevel.city => _normalize(record.city),
        MapRankingLevel.retailer =>
          '${_normalize(record.retailerName ?? '')}|${_normalize(record.retailerAddress ?? '')}',
        MapRankingLevel.game => _normalize(
          record.gameName ?? record.game.label,
        ),
      };
      if (key.replaceAll('|', '').isEmpty) continue;
      groups.putIfAbsent(key, () => <LotteryActivity>[]).add(record);
    }

    final entries = groups.entries.map((group) {
      final records = group.value;
      final first = records.first;
      final gameTotals = <String, int>{};
      var tickets = 0;
      var prizes = 0;
      var latitude = 0.0;
      var longitude = 0.0;
      for (final record in records) {
        tickets += record.winningTickets;
        prizes += record.prizeAmount;
        latitude += record.location.latitude;
        longitude += record.location.longitude;
        final game = record.gameName ?? record.game.label;
        gameTotals[game] = (gameTotals[game] ?? 0) + record.winningTickets;
      }
      final sortedGames = gameTotals.entries.toList()
        ..sort((left, right) {
          final countOrder = right.value.compareTo(left.value);
          return countOrder != 0 ? countOrder : left.key.compareTo(right.key);
        });
      final stateName = source.level == MapRankingLevel.state
          ? StateNavigationService.getStateByAbbreviation(first.state)?.name
          : source.stateName;
      final label = switch (source.level) {
        MapRankingLevel.state => stateName ?? first.state,
        MapRankingLevel.county => first.county,
        MapRankingLevel.city => first.city,
        MapRankingLevel.retailer => first.retailerName ?? first.city,
        MapRankingLevel.game => first.gameName ?? first.game.label,
      };

      return MapRankingEntry(
        key: group.key,
        label: label,
        records: records.length,
        winningTickets: tickets,
        publishedPrizeTotal: prizes,
        gameBreakdown: Map<String, int>.fromEntries(sortedGames),
        location: LatLng(latitude / records.length, longitude / records.length),
        stateName: stateName,
        countyId: source.level == MapRankingLevel.county
            ? source.countyIds[_normalize(first.county)]
            : source.countyId,
        retailerActivityId: source.level == MapRankingLevel.retailer
            ? first.id
            : null,
      );
    }).toList();

    entries.sort((left, right) {
      final ticketOrder = right.winningTickets.compareTo(left.winningTickets);
      if (ticketOrder != 0) return ticketOrder;
      final prizeOrder = right.publishedPrizeTotal.compareTo(
        left.publishedPrizeTotal,
      );
      return prizeOrder != 0 ? prizeOrder : left.label.compareTo(right.label);
    });
    return entries.take(5).toList(growable: false);
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceFirst(RegExp(r'\s+\(city\)$'), '')
      .replaceFirst(RegExp(r'\s+city$'), '')
      .replaceFirst(RegExp(r'\s+county$'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}
