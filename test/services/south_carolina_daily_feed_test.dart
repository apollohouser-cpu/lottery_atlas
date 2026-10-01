import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lottery_atlas/services/south_carolina_scratch_catalog_feed_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('daily source day survives cached network failure', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final raw = File(
      'data/south_carolina_daily_scratch.generated.json',
    ).readAsStringSync();
    final fresh = await SouthCarolinaScratchCatalogFeedService.load(
      client: MockClient((_) async => http.Response(raw, 200)),
    );
    final source = jsonDecode(raw) as Map<String, dynamic>;
    expect(fresh.claimDate, DateTime.parse(source['claimDate'] as String));
    expect(fresh.games, hasLength((source['games'] as List).length));
    expect(fresh.rejectedGames, 0);
    final saved = await SouthCarolinaScratchCatalogFeedService.load(
      client: MockClient((_) async => http.Response('unavailable', 503)),
    );
    expect(saved.isCached, isTrue);
    expect(saved.claimDate, fresh.claimDate);
    expect(saved.updatedAt, fresh.updatedAt);
    expect(saved.games.length, fresh.games.length);
  });
}
