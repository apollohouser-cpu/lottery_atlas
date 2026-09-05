import 'package:flutter/foundation.dart';

import '../models/state_retailer.dart';

/// Holds official, statewide retailer directories separately from winner data.
///
/// Consumers must use [LotteryActivity] to create a heat-map point. Directory
/// entries are only used for retailer lookup and navigation.
class StateRetailerDirectoryRepository {
  StateRetailerDirectoryRepository._();

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Map<String, List<StateRetailer>> _directories =
      const <String, List<StateRetailer>>{};
  static Map<String, String> _sourceUrls = const <String, String>{};

  static List<StateRetailer> retailersFor(String stateName) =>
      List<StateRetailer>.unmodifiable(_directories[stateName] ?? const []);

  static String? sourceFor(String stateName) => _sourceUrls[stateName];

  static int countFor(String stateName) => _directories[stateName]?.length ?? 0;

  static void usePublishedDirectories(
    Map<String, List<StateRetailer>> directories, {
    required Map<String, String> sourceUrls,
  }) {
    if (directories.isEmpty) return;
    _directories = Map<String, List<StateRetailer>>.unmodifiable(
      directories.map(
        (stateName, retailers) =>
            MapEntry(stateName, List<StateRetailer>.unmodifiable(retailers)),
      ),
    );
    _sourceUrls = Map<String, String>.unmodifiable(sourceUrls);
    changes.value++;
  }
}
