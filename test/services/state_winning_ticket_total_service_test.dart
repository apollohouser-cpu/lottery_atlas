import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/state_winning_ticket_total_service.dart';

void main() {
  test('accepts a dated official state total without inventing a location', () {
    final totals = StateWinningTicketTotalService.parse('''
    {"totals":[{"state":"MD","winningTickets":42,
      "periodStart":"2026-01-01","periodEnd":"2026-08-31",
      "sourceDate":"2026-09-09",
      "sourceUrl":"https://www.mdlottery.com/example",
      "coverage":"Claimed prizes in listed Scratch-Off games"}]}
    ''');
    expect(totals.single.state, 'MD');
    expect(totals.single.count, 42);
    expect(totals.single.coverage, contains('Scratch-Off'));
  });

  test('rejects untraceable counts and duplicate state totals', () {
    expect(
      () => StateWinningTicketTotalService.parse(
        '{"totals":[{"state":"MD","winningTickets":42}]}',
      ),
      throwsFormatException,
    );
    const item = '''{"state":"MD","winningTickets":42,
      "periodStart":"2026-01-01","periodEnd":"2026-08-31",
      "sourceDate":"2026-09-09",
      "sourceUrl":"https://www.mdlottery.com/example",
      "coverage":"Claimed prizes in listed Scratch-Off games"}''';
    expect(
      () => StateWinningTicketTotalService.parse('{"totals":[$item,$item]}'),
      throwsFormatException,
    );
  });
}
