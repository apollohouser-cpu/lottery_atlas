import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/lottery_schedule_service.dart';

void main() {
  test('Kentucky exposes every current scheduled draw game', () {
    final schedules = LotteryScheduleService.stateDrawsFor('Kentucky');

    expect(
      schedules.map((schedule) => schedule.name),
      containsAll(<String>[
        'Pick 3 · Midday',
        'Pick 3 · Evening',
        'Pick 4 · Midday',
        'Pick 4 · Evening',
        'Kentucky Cash Ball 225',
        'Millionaire for Life',
        'Keno · Every 4 minutes',
        'Cash Pop · Every 4 minutes',
      ]),
    );
    expect(schedules, hasLength(8));
    expect(schedules.any((schedule) => schedule.name == 'Fast Play'), isFalse);
  });

  test('Kentucky monitor games use their complete official daily windows', () {
    final schedules = LotteryScheduleService.stateDrawsFor('Kentucky');
    final keno = schedules.singleWhere(
      (schedule) => schedule.name.startsWith('Keno'),
    );
    final cashPop = schedules.singleWhere(
      (schedule) => schedule.name.startsWith('Cash Pop'),
    );

    expect((keno.hour, keno.minute), (5, 4));
    expect(keno.drawIntervalMinutes, 4);
    expect(keno.drawWindowMinutes, 1252);
    expect((cashPop.hour, cashPop.minute), (5, 6));
    expect(cashPop.drawIntervalMinutes, 4);
    expect(cashPop.drawWindowMinutes, 1252);
  });

  test('Kentucky daily drawings use their official announced times', () {
    final schedules = LotteryScheduleService.stateDrawsFor('Kentucky');

    StateLotteryDrawSchedule named(String name) =>
        schedules.singleWhere((schedule) => schedule.name == name);

    expect(
      (named('Pick 3 · Midday').hour, named('Pick 3 · Midday').minute),
      (13, 20),
    );
    expect(
      (named('Pick 3 · Evening').hour, named('Pick 3 · Evening').minute),
      (22, 55),
    );
    expect(
      (named('Pick 4 · Midday').hour, named('Pick 4 · Midday').minute),
      (13, 20),
    );
    expect(
      (named('Pick 4 · Evening').hour, named('Pick 4 · Evening').minute),
      (22, 55),
    );
    expect(
      (
        named('Kentucky Cash Ball 225').hour,
        named('Kentucky Cash Ball 225').minute,
      ),
      (22, 58),
    );
    expect(
      (
        named('Millionaire for Life').hour,
        named('Millionaire for Life').minute,
      ),
      (23, 15),
    );
  });
}
