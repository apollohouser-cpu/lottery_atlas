import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottery_atlas/services/saved_ticket_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'synthetic saved numbers survive reload, rename, replacement and deletion',
    () async {
      SharedPreferences.setMockInitialValues({});
      const key = 'lottery_atlas.saved_lottery_tickets';
      final store = await SharedPreferences.getInstance();
      final first = await SavedTicketService.save(
        gameCode: 'powerball',
        whiteNumbers: ['01', '02', '03', '04', '05'],
        specialNumber: '06',
        label: ' Synthetic test ',
      );
      await store.reload();
      final persisted = jsonDecode(store.getString(key)!) as List;
      expect(persisted.single['whiteNumbers'], ['1', '2', '3', '4', '5']);
      expect(persisted.single['label'], 'Synthetic test');
      expect((await SavedTicketService.load()).single.id, first.id);

      await SavedTicketService.rename(first.id, ' Renamed test ');
      await store.reload();
      expect((await SavedTicketService.load()).single.label, 'Renamed test');
      expect(
        (jsonDecode(store.getString(key)!) as List).single['label'],
        'Renamed test',
      );

      final replacement = await SavedTicketService.save(
        gameCode: 'powerball',
        whiteNumbers: ['1', '2', '3', '4', '5'],
        specialNumber: '6',
        label: 'Replacement',
      );
      expect((await SavedTicketService.load()).length, 1);
      final otherGame = await SavedTicketService.save(
        gameCode: 'mega-millions',
        whiteNumbers: ['1', '2', '3', '4', '5'],
        specialNumber: '6',
        label: 'Different game',
      );
      expect((await SavedTicketService.load()).length, 2);
      await SavedTicketService.delete(replacement.id);
      await store.reload();
      expect((await SavedTicketService.load()).single.id, otherGame.id);
      await SavedTicketService.delete(otherGame.id);
      await store.reload();
      expect(await SavedTicketService.load(), isEmpty);
      expect(jsonDecode(store.getString(key)!), isEmpty);
      await expectLater(
        SavedTicketService.rename('missing-test-id', 'Unused'),
        throwsStateError,
      );
      expect(jsonDecode(store.getString(key)!), isEmpty);
    },
  );
}
