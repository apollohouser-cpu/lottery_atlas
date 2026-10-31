import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:lottery_atlas/services/saved_ticket_service.dart';

class FailingStore extends InMemorySharedPreferencesStore {
  FailingStore() : super.empty();
  bool fail = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (fail) return false;
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'failed ticket mutations do not appear saved or poison recovery',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = FailingStore();
      SharedPreferencesStorePlatform.instance = store;
      final ticket = await SavedTicketService.save(
        gameCode: 'powerball',
        whiteNumbers: ['1', '2', '3', '4', '5'],
        specialNumber: '6',
        label: 'Original',
      );
      store.fail = true;
      await expectLater(
        SavedTicketService.rename(ticket.id, 'Failed'),
        throwsStateError,
      );
      expect((await SavedTicketService.load()).single.label, 'Original');
      await expectLater(SavedTicketService.delete(ticket.id), throwsStateError);
      expect((await SavedTicketService.load()).single.id, ticket.id);
      await expectLater(
        SavedTicketService.save(
          gameCode: 'mega-millions',
          whiteNumbers: ['1', '2', '3', '4', '5'],
          specialNumber: '6',
          label: 'Failed save',
        ),
        throwsStateError,
      );
      expect((await SavedTicketService.load()).single.id, ticket.id);
      store.fail = false;
      await SavedTicketService.rename(ticket.id, 'Recovered');
      expect((await SavedTicketService.load()).single.label, 'Recovered');
      await Future.wait([
        SavedTicketService.save(
          gameCode: 'mega-millions',
          whiteNumbers: ['1', '2', '3', '4', '5'],
          specialNumber: '6',
          label: 'Concurrent addition',
        ),
        SavedTicketService.delete(ticket.id),
      ]);
      expect(
        (await SavedTicketService.load()).single.gameCode,
        'mega-millions',
      );
    },
  );
}
