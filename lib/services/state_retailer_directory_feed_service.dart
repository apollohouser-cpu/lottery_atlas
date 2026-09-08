import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/state_model.dart';
import '../models/state_retailer.dart';
import 'state_retailer_directory_repository.dart';

/// Loads bundled snapshots of official statewide lottery retailer directories.
///
/// A directory supports retailer search and routing. It never creates heat-map
/// bubbles; those require a separately verified [LotteryActivity] record.
class StateRetailerDirectoryFeedService {
  StateRetailerDirectoryFeedService._();

  static const String _feedUrl = String.fromEnvironment(
    'STATE_RETAILER_DIRECTORY_FEED_URL',
    defaultValue:
        'https://apollohouser-cpu.github.io/lottery_atlas/state_retailer_directories.json',
  );

  static const List<String> _bootstrapAssets = <String>[
    'data/michigan_retailer_directory.initial.json',
    'data/kentucky_retailer_directory.generated.json',
    'data/virginia_retailer_directory.generated.json',
    'data/new_york_retailer_directory.generated.json',
  ];

  static Future<void> loadBundledDirectories({http.Client? client}) async {
    final directories = <String, List<StateRetailer>>{};
    final sourceUrls = <String, String>{};

    for (final asset in _bootstrapAssets) {
      try {
        final feed = _parse(await rootBundle.loadString(asset));
        directories.addAll(feed.directories);
        sourceUrls.addAll(feed.sourceUrls);
      } catch (_) {
        // An optional official directory must never prevent the map loading.
      }
    }

    final activeClient = client ?? http.Client();
    try {
      if (_feedUrl.trim().isNotEmpty) {
        final response = await activeClient
            .get(
              Uri.parse(_feedUrl),
              headers: const {'accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 20));
        if (response.statusCode == 200) {
          final feed = _parse(response.body);
          directories.addAll(feed.directories);
          sourceUrls.addAll(feed.sourceUrls);
        }
      }
    } catch (_) {
      // The bundled verified directory remains available offline.
    } finally {
      if (client == null) activeClient.close();
    }

    StateRetailerDirectoryRepository.usePublishedDirectories(
      directories,
      sourceUrls: sourceUrls,
    );
  }

  static _RetailerDirectoryFeed _parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['directories'] is! List) {
      throw const FormatException(
        'Retailer directory feed needs a directories list.',
      );
    }

    final knownStates = allStates.map((state) => state.name).toSet();
    final directories = <String, List<StateRetailer>>{};
    final sourceUrls = <String, String>{};

    for (final rawDirectory in decoded['directories'] as List) {
      if (rawDirectory is! Map) continue;
      final directory = Map<String, dynamic>.from(rawDirectory);
      final stateName = directory['state']?.toString().trim() ?? '';
      final sourceUrl = directory['source']?.toString().trim() ?? '';
      final rawRetailers = directory['retailers'];
      if (!knownStates.contains(stateName) ||
          sourceUrl.isEmpty ||
          rawRetailers is! List) {
        continue;
      }

      final retailers = <StateRetailer>[];
      final ids = <String>{};
      for (final rawRetailer in rawRetailers) {
        if (rawRetailer is! Map) continue;
        try {
          final payload = Map<String, dynamic>.from(rawRetailer);
          payload['stateName'] ??= stateName;
          final retailer = StateRetailer.fromJson(payload);
          if (retailer.stateName == stateName && ids.add(retailer.id)) {
            retailers.add(retailer);
          }
        } on FormatException {
          // Individual malformed records are ignored without weakening the
          // integrity of the rest of an official statewide file.
        }
      }
      if (retailers.isEmpty) continue;
      directories[stateName] = List<StateRetailer>.unmodifiable(retailers);
      sourceUrls[stateName] = sourceUrl;
    }

    if (directories.isEmpty) {
      throw const FormatException('Retailer directory feed has no valid data.');
    }
    return _RetailerDirectoryFeed(
      directories: directories,
      sourceUrls: sourceUrls,
    );
  }
}

class _RetailerDirectoryFeed {
  const _RetailerDirectoryFeed({
    required this.directories,
    required this.sourceUrls,
  });

  final Map<String, List<StateRetailer>> directories;
  final Map<String, String> sourceUrls;
}
