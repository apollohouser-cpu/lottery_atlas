import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// A single place for Lottery Atlas drawing schedules.
///
/// National and state-specific games live here so the map can use one
/// consistent upcoming-draw menu.
class LotteryScheduleService {
  LotteryScheduleService._();

  static late final tz.Location _easternTime;
  static bool _isInitialized = false;

  static const Map<String, String> _primaryTimeZoneByState = {
    'Alabama': 'America/Chicago',
    'Alaska': 'America/Anchorage',
    'Arizona': 'America/Phoenix',
    'Arkansas': 'America/Chicago',
    'California': 'America/Los_Angeles',
    'Colorado': 'America/Denver',
    'Connecticut': 'America/New_York',
    'Delaware': 'America/New_York',
    'District of Columbia': 'America/New_York',
    'Florida': 'America/New_York',
    'Georgia': 'America/New_York',
    'Hawaii': 'Pacific/Honolulu',
    'Idaho': 'America/Denver',
    'Illinois': 'America/Chicago',
    'Indiana': 'America/New_York',
    'Iowa': 'America/Chicago',
    'Kansas': 'America/Chicago',
    'Kentucky': 'America/New_York',
    'Louisiana': 'America/Chicago',
    'Maine': 'America/New_York',
    'Maryland': 'America/New_York',
    'Massachusetts': 'America/New_York',
    'Michigan': 'America/New_York',
    'Minnesota': 'America/Chicago',
    'Mississippi': 'America/Chicago',
    'Missouri': 'America/Chicago',
    'Montana': 'America/Denver',
    'Nebraska': 'America/Chicago',
    'Nevada': 'America/Los_Angeles',
    'New Hampshire': 'America/New_York',
    'New Jersey': 'America/New_York',
    'New Mexico': 'America/Denver',
    'New York': 'America/New_York',
    'North Carolina': 'America/New_York',
    'North Dakota': 'America/Chicago',
    'Ohio': 'America/New_York',
    'Oklahoma': 'America/Chicago',
    'Oregon': 'America/Los_Angeles',
    'Pennsylvania': 'America/New_York',
    'Rhode Island': 'America/New_York',
    'South Carolina': 'America/New_York',
    'South Dakota': 'America/Chicago',
    'Tennessee': 'America/Chicago',
    'Texas': 'America/Chicago',
    'Utah': 'America/Denver',
    'Vermont': 'America/New_York',
    'Virginia': 'America/New_York',
    'Washington': 'America/Los_Angeles',
    'West Virginia': 'America/New_York',
    'Wisconsin': 'America/Chicago',
    'Wyoming': 'America/Denver',
  };

  static const List<LotteryDrawSchedule> nationalDraws = [
    LotteryDrawSchedule(
      name: 'Powerball',
      weekdays: [DateTime.monday, DateTime.wednesday, DateTime.saturday],
      hour: 22,
      minute: 59,
      accentColor: Color(0xFFE53935),
    ),
    LotteryDrawSchedule(
      name: 'Mega Millions',
      weekdays: [DateTime.tuesday, DateTime.friday],
      hour: 23,
      minute: 0,
      accentColor: Color(0xFFFFB300),
    ),
  ];

  static const List<int> _everyDay = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  static const List<int> _mondayToSaturday = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  ];

  static const List<int> _mondayToFriday = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];

  static const List<int> _oregonCashPopHours = [
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
  ];

  static void initialize() {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    _easternTime = tz.getLocation('America/New_York');
    _isInitialized = true;
  }

  /// Returns the next drawing in the selected state's primary time zone.
  /// Without a selected state, it uses the device's local time zone.
  static DateTime nextDrawing(
    LotteryDrawSchedule schedule, {
    String? stateName,
  }) {
    initialize();
    final nowEastern = tz.TZDateTime.now(_easternTime);

    for (var dayOffset = 0; dayOffset <= 7; dayOffset++) {
      final calendarDay = DateTime(
        nowEastern.year,
        nowEastern.month,
        nowEastern.day + dayOffset,
      );
      final candidate = tz.TZDateTime(
        _easternTime,
        calendarDay.year,
        calendarDay.month,
        calendarDay.day,
        schedule.hour,
        schedule.minute,
      );

      if (schedule.weekdays.contains(candidate.weekday) &&
          candidate.isAfter(nowEastern)) {
        final stateTimeZone = _primaryTimeZoneByState[stateName];
        if (stateTimeZone == null) {
          return candidate.toLocal();
        }

        return tz.TZDateTime.from(candidate, tz.getLocation(stateTimeZone));
      }
    }

    throw StateError('Unable to calculate the next ${schedule.name} drawing.');
  }

  /// Returns the current time in the selected state's primary time zone.
  static DateTime currentTimeInState(String stateName) {
    initialize();
    final stateTimeZone = _primaryTimeZoneByState[stateName];
    if (stateTimeZone == null) return DateTime.now();

    return tz.TZDateTime.now(tz.getLocation(stateTimeZone));
  }

  /// Returns known state drawing schedules.
  ///
  /// South Carolina is the first verified state adapter. Other states keep a
  /// clearly marked sample schedule until their official source is connected.
  static List<StateLotteryDrawSchedule> stateDrawsFor(String stateName) {
    if (stateName == 'Georgia') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Cash 3 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 29,
          salesCutoffMinutes: 9,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 3 · Evening',
          weekdays: _everyDay,
          hour: 18,
          minute: 59,
          salesCutoffMinutes: 9,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 3 · Night',
          weekdays: _everyDay,
          hour: 23,
          minute: 34,
          salesCutoffMinutes: 49,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 4 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 29,
          salesCutoffMinutes: 9,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 4 · Evening',
          weekdays: _everyDay,
          hour: 18,
          minute: 59,
          salesCutoffMinutes: 9,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 4 · Night',
          weekdays: _everyDay,
          hour: 23,
          minute: 34,
          salesCutoffMinutes: 49,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Georgia FIVE · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 29,
          salesCutoffMinutes: 9,
          accentColor: Color(0xFF2CC36B),
        ),
        StateLotteryDrawSchedule(
          name: 'Georgia FIVE · Evening',
          weekdays: _everyDay,
          hour: 18,
          minute: 59,
          salesCutoffMinutes: 9,
          accentColor: Color(0xFF2CC36B),
        ),
        StateLotteryDrawSchedule(
          name: 'Fantasy 5',
          weekdays: _everyDay,
          hour: 23,
          minute: 34,
          salesCutoffMinutes: 49,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Morning',
          weekdays: _everyDay,
          hour: 8,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Afternoon',
          weekdays: _everyDay,
          hour: 17,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Evening',
          weekdays: _everyDay,
          hour: 20,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Night',
          weekdays: _everyDay,
          hour: 23,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
      ];
    }

    if (stateName == 'Florida') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Pick 2 · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 30,
          salesCutoffMinutes: 13,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 2 · Evening',
          weekdays: _everyDay,
          hour: 21,
          minute: 45,
          salesCutoffMinutes: 13,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 30,
          salesCutoffMinutes: 11,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Evening',
          weekdays: _everyDay,
          hour: 21,
          minute: 45,
          salesCutoffMinutes: 11,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 30,
          salesCutoffMinutes: 10,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Evening',
          weekdays: _everyDay,
          hour: 21,
          minute: 45,
          salesCutoffMinutes: 10,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 30,
          salesCutoffMinutes: 12,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Evening',
          weekdays: _everyDay,
          hour: 21,
          minute: 45,
          salesCutoffMinutes: 12,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Morning',
          weekdays: _everyDay,
          hour: 8,
          minute: 45,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Matinee',
          weekdays: _everyDay,
          hour: 11,
          minute: 45,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Afternoon',
          weekdays: _everyDay,
          hour: 14,
          minute: 45,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Evening',
          weekdays: _everyDay,
          hour: 18,
          minute: 45,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Late Night',
          weekdays: _everyDay,
          hour: 23,
          minute: 45,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Florida Lotto',
          weekdays: [DateTime.wednesday, DateTime.saturday],
          hour: 23,
          minute: 15,
          salesCutoffMinutes: 20,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Jackpot Triple Play',
          weekdays: [DateTime.tuesday, DateTime.friday],
          hour: 23,
          minute: 15,
          salesCutoffMinutes: 20,
          accentColor: Color(0xFFFFB300),
        ),
      ];
    }

    if (stateName == 'Pennsylvania') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Pick 2 · Day',
          weekdays: _everyDay,
          hour: 13,
          minute: 35,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 2 · Evening',
          weekdays: _everyDay,
          hour: 18,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Day',
          weekdays: _everyDay,
          hour: 13,
          minute: 35,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Evening',
          weekdays: _everyDay,
          hour: 18,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Day',
          weekdays: _everyDay,
          hour: 13,
          minute: 35,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Evening',
          weekdays: _everyDay,
          hour: 18,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Day',
          weekdays: _everyDay,
          hour: 13,
          minute: 35,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Evening',
          weekdays: _everyDay,
          hour: 18,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Treasure Hunt',
          weekdays: _everyDay,
          hour: 13,
          minute: 35,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Morning Buzz',
          weekdays: _everyDay,
          hour: 9,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Lunch Break',
          weekdays: _everyDay,
          hour: 13,
          minute: 35,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Prime Time',
          weekdays: _everyDay,
          hour: 18,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Night Owl',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 5 with Quick Cash',
          weekdays: _everyDay,
          hour: 18,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Match 6 Lotto',
          weekdays: _everyDay,
          hour: 18,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Keno',
          weekdays: _everyDay,
          hour: 0,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
          drawIntervalMinutes: 4,
          drawWindowMinutes: 1436,
        ),
        StateLotteryDrawSchedule(
          name: 'Derby Cash',
          weekdays: _everyDay,
          hour: 0,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
          drawIntervalMinutes: 4,
          drawWindowMinutes: 1436,
        ),
      ];
    }

    if (stateName == 'New York') {
      return const [
        StateLotteryDrawSchedule(
          name: 'NUMBERS · Midday',
          weekdays: _everyDay,
          hour: 14,
          minute: 30,
          salesCutoffMinutes: 15,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'NUMBERS · Evening',
          weekdays: _everyDay,
          hour: 22,
          minute: 30,
          salesCutoffMinutes: 10,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Win4 · Midday',
          weekdays: _everyDay,
          hour: 14,
          minute: 30,
          salesCutoffMinutes: 15,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Win4 · Evening',
          weekdays: _everyDay,
          hour: 22,
          minute: 30,
          salesCutoffMinutes: 10,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Take 5 · Midday',
          weekdays: _everyDay,
          hour: 14,
          minute: 30,
          salesCutoffMinutes: 15,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Take 5 · Evening',
          weekdays: _everyDay,
          hour: 22,
          minute: 30,
          salesCutoffMinutes: 10,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Quick Draw',
          weekdays: _everyDay,
          hour: 4,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
          drawIntervalMinutes: 4,
          drawWindowMinutes: 1436,
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 10',
          weekdays: _everyDay,
          hour: 20,
          minute: 30,
          salesCutoffMinutes: 30,
          accentColor: Color(0xFFFFB300),
        ),
      ];
    }

    if (stateName == 'New Jersey') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Pick-3 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 59,
          salesCutoffMinutes: 6,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick-3 · Evening',
          weekdays: _everyDay,
          hour: 22,
          minute: 57,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick-4 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 59,
          salesCutoffMinutes: 6,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick-4 · Evening',
          weekdays: _everyDay,
          hour: 22,
          minute: 57,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Jersey Cash 5',
          weekdays: _everyDay,
          hour: 22,
          minute: 57,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick-6',
          weekdays: [DateTime.monday, DateTime.thursday, DateTime.saturday],
          hour: 22,
          minute: 57,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash4Life',
          weekdays: _everyDay,
          hour: 21,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Millionaire for Life',
          weekdays: _everyDay,
          hour: 23,
          minute: 15,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
      ];
    }

    if (stateName == 'Ohio') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 29,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 29,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 29,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Evening',
          weekdays: [
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.sunday,
          ],
          hour: 19,
          minute: 29,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Evening',
          weekdays: [
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.sunday,
          ],
          hour: 19,
          minute: 29,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Evening',
          weekdays: [
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.sunday,
          ],
          hour: 19,
          minute: 29,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Rolling Cash 5',
          weekdays: _everyDay,
          hour: 19,
          minute: 5,
          salesCutoffMinutes: 5,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Classic Lotto',
          weekdays: [DateTime.monday, DateTime.wednesday, DateTime.saturday],
          hour: 19,
          minute: 5,
          salesCutoffMinutes: 5,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Kicker',
          weekdays: [DateTime.monday, DateTime.wednesday, DateTime.saturday],
          hour: 19,
          minute: 1,
          salesCutoffMinutes: 1,
          accentColor: Color(0xFFFACC15),
        ),
        StateLotteryDrawSchedule(
          name: 'Millionaire for Life',
          weekdays: _everyDay,
          hour: 23,
          minute: 15,
          salesCutoffMinutes: 60,
          accentColor: Color(0xFF86EFAC),
        ),
      ];
    }

    if (stateName == 'Indiana') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Daily 3',
          weekdays: _everyDay,
          hour: 22,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Daily 4',
          weekdays: _everyDay,
          hour: 22,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
      ];
    }

    if (stateName == 'Missouri') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 45,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Evening',
          weekdays: _everyDay,
          hour: 20,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 45,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Evening',
          weekdays: _everyDay,
          hour: 20,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Show Me Cash',
          weekdays: _everyDay,
          hour: 20,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Missouri Lotto',
          weekdays: [DateTime.wednesday, DateTime.saturday],
          hour: 20,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Early Bird',
          weekdays: _everyDay,
          hour: 8,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Late Morning',
          weekdays: _everyDay,
          hour: 11,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Matinee',
          weekdays: _everyDay,
          hour: 15,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Prime Time',
          weekdays: _everyDay,
          hour: 19,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Night Owl',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
      ];
    }

    if (stateName == 'Tennessee') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Tennessee Cash',
          weekdays: [DateTime.monday, DateTime.wednesday, DateTime.friday],
          hour: 22,
          minute: 30,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Daily Tennessee Jackpot',
          weekdays: _everyDay,
          hour: 21,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 3 · Morning',
          weekdays: _mondayToSaturday,
          hour: 9,
          minute: 28,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 3 · Midday',
          weekdays: _mondayToSaturday,
          hour: 12,
          minute: 28,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 3 · Evening',
          weekdays: _everyDay,
          hour: 18,
          minute: 28,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 4 · Morning',
          weekdays: _mondayToSaturday,
          hour: 9,
          minute: 28,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 4 · Midday',
          weekdays: _mondayToSaturday,
          hour: 12,
          minute: 28,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 4 · Evening',
          weekdays: _everyDay,
          hour: 18,
          minute: 28,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
      ];
    }

    if (stateName == 'Virginia') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Day',
          weekdays: _everyDay,
          hour: 13,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Night',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Day',
          weekdays: _everyDay,
          hour: 13,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Night',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Day',
          weekdays: _everyDay,
          hour: 13,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF2CC36B),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Night',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF2CC36B),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 5 with EZ Match',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Coffee Break',
          weekdays: _everyDay,
          hour: 9,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Lunch Break',
          weekdays: _everyDay,
          hour: 12,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Rush Hour',
          weekdays: _everyDay,
          hour: 17,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Prime Time',
          weekdays: _everyDay,
          hour: 21,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · After Hours',
          weekdays: _everyDay,
          hour: 23,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
      ];
    }

    if (stateName == 'Kentucky') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 20,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Evening',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 20,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Evening',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Kentucky Cash Ball 225',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Millionaire for Life',
          weekdays: _everyDay,
          hour: 23,
          minute: 15,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
      ];
    }

    if (stateName == 'Maryland') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Morning',
          weekdays: _everyDay,
          hour: 9,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Afternoon',
          weekdays: _everyDay,
          hour: 13,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Evening',
          weekdays: _everyDay,
          hour: 18,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Night',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Midday',
          weekdays: _mondayToFriday,
          hour: 12,
          minute: 27,
          salesCutoffMinutes: 3,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Midday',
          weekdays: _mondayToFriday,
          hour: 12,
          minute: 27,
          salesCutoffMinutes: 3,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Midday',
          weekdays: _mondayToFriday,
          hour: 12,
          minute: 27,
          salesCutoffMinutes: 3,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Midday',
          weekdays: [DateTime.saturday, DateTime.sunday],
          hour: 12,
          minute: 28,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Midday',
          weekdays: [DateTime.saturday, DateTime.sunday],
          hour: 12,
          minute: 28,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Midday',
          weekdays: [DateTime.saturday, DateTime.sunday],
          hour: 12,
          minute: 28,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Evening',
          weekdays: _mondayToSaturday,
          hour: 19,
          minute: 56,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Evening',
          weekdays: _mondayToSaturday,
          hour: 19,
          minute: 56,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Evening',
          weekdays: _mondayToSaturday,
          hour: 19,
          minute: 56,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Bonus Match 5',
          weekdays: _mondayToSaturday,
          hour: 19,
          minute: 56,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Evening',
          weekdays: [DateTime.sunday],
          hour: 20,
          minute: 10,
          salesCutoffMinutes: 5,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Evening',
          weekdays: [DateTime.sunday],
          hour: 20,
          minute: 10,
          salesCutoffMinutes: 5,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Evening',
          weekdays: [DateTime.sunday],
          hour: 20,
          minute: 10,
          salesCutoffMinutes: 5,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Bonus Match 5',
          weekdays: [DateTime.sunday],
          hour: 20,
          minute: 10,
          salesCutoffMinutes: 5,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Multi-Match',
          weekdays: [DateTime.monday, DateTime.thursday],
          hour: 19,
          minute: 56,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFFFFB300),
        ),
      ];
    }

    if (stateName == 'Delaware') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Play 3 · Day',
          weekdays: _everyDay,
          hour: 13,
          minute: 58,
          salesCutoffMinutes: 18,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Play 3 · Night',
          weekdays: _everyDay,
          hour: 19,
          minute: 57,
          salesCutoffMinutes: 27,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Play 4 · Day',
          weekdays: _everyDay,
          hour: 13,
          minute: 58,
          salesCutoffMinutes: 18,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Play 4 · Night',
          weekdays: _everyDay,
          hour: 19,
          minute: 57,
          salesCutoffMinutes: 27,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Play 5 · Day',
          weekdays: _everyDay,
          hour: 13,
          minute: 58,
          salesCutoffMinutes: 18,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Play 5 · Night',
          weekdays: _everyDay,
          hour: 19,
          minute: 57,
          salesCutoffMinutes: 27,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Multi-Win Lotto',
          weekdays: _everyDay,
          hour: 19,
          minute: 57,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Lucky for Life',
          weekdays: _everyDay,
          hour: 22,
          minute: 38,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Lotto America',
          weekdays: [DateTime.monday, DateTime.wednesday, DateTime.saturday],
          hour: 22,
          minute: 15,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFFFB300),
        ),
      ];
    }

    if (stateName == 'Missouri') {
      // Source: https://www.molottery.com/about-us/missouri-lottery-drawings.jsp
      return const [
        StateLotteryDrawSchedule(
          name: 'MO Millions',
          weekdays: [DateTime.wednesday, DateTime.saturday],
          hour: 20,
          minute: 59,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Show Me Cash',
          weekdays: _everyDay,
          hour: 20,
          minute: 59,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 45,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Evening',
          weekdays: _everyDay,
          hour: 20,
          minute: 59,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 45,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Evening',
          weekdays: _everyDay,
          hour: 20,
          minute: 59,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Early Bird',
          weekdays: _everyDay,
          hour: 8,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Late Morning',
          weekdays: _everyDay,
          hour: 11,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Matinee',
          weekdays: _everyDay,
          hour: 15,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Prime Time',
          weekdays: _everyDay,
          hour: 19,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Night Owl',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
        ),
      ];
    }

    if (stateName == 'Oklahoma') {
      // Sources: https://www.lottery.ok.gov/draw-games/pick-3 and cash-5.
      return const [
        StateLotteryDrawSchedule(
          name: 'Pick 3',
          weekdays: _everyDay,
          hour: 21,
          minute: 0,
          salesCutoffMinutes: 1,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 5',
          weekdays: _everyDay,
          hour: 21,
          minute: 0,
          salesCutoffMinutes: 1,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Millionaire for Life',
          weekdays: _everyDay,
          hour: 22,
          minute: 15,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
      ];
    }

    if (stateName == 'Kansas') {
      // Sources: Kansas Lottery game rules for Super Kansas Cash and 2by2.
      return const [
        StateLotteryDrawSchedule(
          name: 'Super Kansas Cash',
          weekdays: [DateTime.monday, DateTime.wednesday, DateTime.saturday],
          hour: 21,
          minute: 10,
          salesCutoffMinutes: 11,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: '2by2',
          weekdays: _everyDay,
          hour: 21,
          minute: 30,
          salesCutoffMinutes: 31,
          accentColor: Color(0xFF86EFAC),
        ),
      ];
    }

    if (stateName == 'Colorado') {
      // Source: https://www.coloradolottery.com/en/about/faqs/
      return const [
        StateLotteryDrawSchedule(
          name: 'Colorado Lotto+',
          weekdays: [DateTime.wednesday, DateTime.saturday],
          hour: 19,
          minute: 35,
          salesCutoffMinutes: 5,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash 5',
          weekdays: _everyDay,
          hour: 19,
          minute: 35,
          salesCutoffMinutes: 5,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 36,
          salesCutoffMinutes: 6,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Evening',
          weekdays: _everyDay,
          hour: 19,
          minute: 36,
          salesCutoffMinutes: 6,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Millionaire for Life',
          weekdays: _everyDay,
          hour: 21,
          minute: 15,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
      ];
    }

    if (stateName == 'Indiana') {
      // Source: https://hoosierlottery.com/games/draw/televised-drawings/
      return const [
        StateLotteryDrawSchedule(
          name: 'Hoosier Lotto +PLUS',
          weekdays: [DateTime.wednesday, DateTime.saturday],
          hour: 23,
          minute: 0,
          salesCutoffMinutes: 21,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'CA\$H 5 +EZ',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: 21,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Daily 3 · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 20,
          salesCutoffMinutes: 10,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Daily 3 · Evening',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: 21,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Daily 4 · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 20,
          salesCutoffMinutes: 10,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Daily 4 · Evening',
          weekdays: _everyDay,
          hour: 23,
          minute: 0,
          salesCutoffMinutes: 21,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash POP · Morning',
          weekdays: _everyDay,
          hour: 9,
          minute: 30,
          salesCutoffMinutes: 10,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash POP · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 30,
          salesCutoffMinutes: 10,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash POP · Afternoon',
          weekdays: _everyDay,
          hour: 15,
          minute: 30,
          salesCutoffMinutes: 10,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash POP · Evening',
          weekdays: _everyDay,
          hour: 19,
          minute: 30,
          salesCutoffMinutes: 10,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash POP · Late Night',
          weekdays: _everyDay,
          hour: 23,
          minute: 30,
          salesCutoffMinutes: 10,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Millionaire for Life',
          weekdays: _everyDay,
          hour: 23,
          minute: 15,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
      ];
    }

    if (stateName == 'Oregon') {
      // Sources: Oregon Lottery's Megabucks, Pick 4 and Cash Pop game pages.
      return <StateLotteryDrawSchedule>[
        const StateLotteryDrawSchedule(
          name: 'Oregon’s Game Megabucks',
          weekdays: [DateTime.monday, DateTime.wednesday, DateTime.saturday],
          hour: 19,
          minute: 29,
          salesCutoffMinutes: 1,
          accentColor: Color(0xFFFFB300),
        ),
        const StateLotteryDrawSchedule(
          name: 'Win for Life',
          weekdays: _everyDay,
          hour: 19,
          minute: 30,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
        const StateLotteryDrawSchedule(
          name: 'Pick 4 · 1 PM',
          weekdays: _everyDay,
          hour: 13,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        const StateLotteryDrawSchedule(
          name: 'Pick 4 · 4 PM',
          weekdays: _everyDay,
          hour: 16,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        const StateLotteryDrawSchedule(
          name: 'Pick 4 · 7 PM',
          weekdays: _everyDay,
          hour: 19,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        const StateLotteryDrawSchedule(
          name: 'Pick 4 · 10 PM',
          weekdays: _everyDay,
          hour: 22,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        for (final hour in _oregonCashPopHours)
          StateLotteryDrawSchedule(
            name:
                'Cash Pop · ${hour <= 12 ? hour : hour - 12} ${hour < 12 ? 'AM' : 'PM'}',
            weekdays: _everyDay,
            hour: hour,
            minute: 0,
            salesCutoffMinutes: null,
            accentColor: const Color(0xFFEC4899),
          ),
      ];
    }

    if (stateName == 'Ohio') {
      // Source: https://www.ohiolottery.com/winning-numbers/drawings/draw-games-schedule
      return const [
        StateLotteryDrawSchedule(
          name: 'Classic Lotto',
          weekdays: [DateTime.monday, DateTime.wednesday, DateTime.saturday],
          hour: 19,
          minute: 5,
          salesCutoffMinutes: 5,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'KICKER',
          weekdays: [DateTime.monday, DateTime.wednesday, DateTime.saturday],
          hour: 19,
          minute: 1,
          salesCutoffMinutes: 1,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Rolling Cash 5',
          weekdays: _everyDay,
          hour: 19,
          minute: 5,
          salesCutoffMinutes: 5,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 29,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Evening',
          weekdays: _everyDay,
          hour: 19,
          minute: 29,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 29,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Evening',
          weekdays: _everyDay,
          hour: 19,
          minute: 29,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 29,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 5 · Evening',
          weekdays: _everyDay,
          hour: 19,
          minute: 29,
          salesCutoffMinutes: 4,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Millionaire for Life',
          weekdays: _everyDay,
          hour: 23,
          minute: 15,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF86EFAC),
        ),
      ];
    }

    if (stateName == 'Minnesota') {
      // Source: https://www.mnlottery.com/about-the-lottery/drawing-schedule
      return const [
        StateLotteryDrawSchedule(
          name: 'Lotto America',
          weekdays: [DateTime.monday, DateTime.wednesday, DateTime.saturday],
          hour: 21,
          minute: 20,
          salesCutoffMinutes: 20,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Gopher 5',
          weekdays: [DateTime.monday, DateTime.wednesday, DateTime.friday],
          hour: 18,
          minute: 17,
          salesCutoffMinutes: 7,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'North 5',
          weekdays: _everyDay,
          hour: 18,
          minute: 17,
          salesCutoffMinutes: 7,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3',
          weekdays: _everyDay,
          hour: 18,
          minute: 17,
          salesCutoffMinutes: 7,
          accentColor: Color(0xFF60A5FA),
        ),
      ];
    }

    if (stateName == 'Wisconsin') {
      // Sources: Wisconsin Lottery game rules and draw-time FAQ.
      return const [
        StateLotteryDrawSchedule(
          name: 'Megabucks',
          weekdays: [DateTime.wednesday, DateTime.saturday],
          hour: 21,
          minute: 0,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'SuperCash!',
          weekdays: _everyDay,
          hour: 21,
          minute: 0,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Badger 5',
          weekdays: _everyDay,
          hour: 21,
          minute: 0,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'All or Nothing · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 30,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'All or Nothing · Evening',
          weekdays: _everyDay,
          hour: 21,
          minute: 0,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 30,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Evening',
          weekdays: _everyDay,
          hour: 21,
          minute: 0,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Midday',
          weekdays: _everyDay,
          hour: 13,
          minute: 30,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Evening',
          weekdays: _everyDay,
          hour: 21,
          minute: 0,
          salesCutoffMinutes: 0,
          accentColor: Color(0xFF7C5CFC),
        ),
      ];
    }

    if (stateName == 'Washington') {
      // Source: https://www.walottery.com/JackpotGames/
      return const [
        StateLotteryDrawSchedule(
          name: 'Lotto',
          weekdays: [DateTime.monday, DateTime.wednesday, DateTime.saturday],
          hour: 20,
          minute: 0,
          salesCutoffMinutes: 15,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Hit 5',
          weekdays: _everyDay,
          hour: 20,
          minute: 0,
          salesCutoffMinutes: 15,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Match 4',
          weekdays: _everyDay,
          hour: 20,
          minute: 0,
          salesCutoffMinutes: 15,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3',
          weekdays: _everyDay,
          hour: 20,
          minute: 0,
          salesCutoffMinutes: 15,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop',
          weekdays: _everyDay,
          hour: 20,
          minute: 0,
          salesCutoffMinutes: 15,
          accentColor: Color(0xFFEC4899),
        ),
        StateLotteryDrawSchedule(
          name: 'Daily Keno',
          weekdays: _everyDay,
          hour: 20,
          minute: 0,
          salesCutoffMinutes: 15,
          accentColor: Color(0xFFEC4899),
        ),
      ];
    }

    if (stateName == 'Iowa') {
      // Source: https://www.ialottery.com/Pages/Games/DrawingTimes.aspx
      return const [
        StateLotteryDrawSchedule(
          name: 'Lotto America',
          weekdays: [DateTime.monday, DateTime.wednesday, DateTime.saturday],
          hour: 21,
          minute: 15,
          salesCutoffMinutes: 16,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Millionaire for Life',
          weekdays: _everyDay,
          hour: 22,
          minute: 15,
          salesCutoffMinutes: 76,
          accentColor: Color(0xFF86EFAC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 20,
          salesCutoffMinutes: 20,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 · Evening',
          weekdays: _everyDay,
          hour: 22,
          minute: 0,
          salesCutoffMinutes: 20,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Midday',
          weekdays: _everyDay,
          hour: 12,
          minute: 20,
          salesCutoffMinutes: 20,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 · Evening',
          weekdays: _everyDay,
          hour: 22,
          minute: 0,
          salesCutoffMinutes: 20,
          accentColor: Color(0xFF7C5CFC),
        ),
      ];
    }

    if (stateName == 'South Carolina') {
      return const [
        StateLotteryDrawSchedule(
          name: 'Pick 3 Plus FIREBALL · Midday',
          weekdays: [
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
          ],
          hour: 12,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 3 Plus FIREBALL · Evening',
          weekdays: [
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
            DateTime.sunday,
          ],
          hour: 18,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 Plus FIREBALL · Midday',
          weekdays: [
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
          ],
          hour: 12,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Pick 4 Plus FIREBALL · Evening',
          weekdays: [
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
            DateTime.sunday,
          ],
          hour: 18,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'CASH POP · Midday',
          weekdays: [
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
          ],
          hour: 12,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF2CC36B),
        ),
        StateLotteryDrawSchedule(
          name: 'CASH POP · Evening',
          weekdays: [
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
            DateTime.sunday,
          ],
          hour: 18,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF2CC36B),
        ),
        StateLotteryDrawSchedule(
          name: 'Palmetto Cash 5',
          weekdays: [
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
            DateTime.sunday,
          ],
          hour: 18,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFFFB300),
        ),
      ];
    }

    if (stateName == 'North Carolina') {
      const everyDay = [
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      ];
      return const [
        StateLotteryDrawSchedule(
          name: 'Carolina Cash 5',
          weekdays: everyDay,
          hour: 23,
          minute: 22,
          salesCutoffMinutes: 23,
          accentColor: Color(0xFFFFB300),
        ),
        StateLotteryDrawSchedule(
          name: 'Carolina Pick 3 · Daytime',
          weekdays: everyDay,
          hour: 15,
          minute: 0,
          salesCutoffMinutes: 15,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Carolina Pick 3 · Evening',
          weekdays: everyDay,
          hour: 23,
          minute: 22,
          salesCutoffMinutes: 22,
          accentColor: Color(0xFF60A5FA),
        ),
        StateLotteryDrawSchedule(
          name: 'Carolina Pick 4 · Daytime',
          weekdays: everyDay,
          hour: 15,
          minute: 0,
          salesCutoffMinutes: 15,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Carolina Pick 4 · Evening',
          weekdays: everyDay,
          hour: 23,
          minute: 22,
          salesCutoffMinutes: 22,
          accentColor: Color(0xFF7C5CFC),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Morning Buzz',
          weekdays: everyDay,
          hour: 9,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF2CC36B),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Lunch Rush',
          weekdays: everyDay,
          hour: 13,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF2CC36B),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Clock Out Cash',
          weekdays: everyDay,
          hour: 17,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF2CC36B),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Primetime Pop',
          weekdays: everyDay,
          hour: 20,
          minute: 0,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF2CC36B),
        ),
        StateLotteryDrawSchedule(
          name: 'Cash Pop · Midnight Money',
          weekdays: everyDay,
          hour: 23,
          minute: 59,
          salesCutoffMinutes: null,
          accentColor: Color(0xFF2CC36B),
        ),
        StateLotteryDrawSchedule(
          name: 'Carolina Keno · Every 4 minutes',
          weekdays: everyDay,
          hour: 5,
          minute: 4,
          salesCutoffMinutes: null,
          accentColor: Color(0xFFEC4899),
          drawIntervalMinutes: 4,
          drawWindowMinutes: 1240,
        ),
        StateLotteryDrawSchedule(
          name: 'Millionaire For Life',
          weekdays: everyDay,
          hour: 23,
          minute: 15,
          salesCutoffMinutes: 60,
          accentColor: Color(0xFF86EFAC),
        ),
      ];
    }

    // Never display invented schedules. Each state is added only after its
    // draw times have been verified from that lottery's official source.
    return const [];
  }

  static bool hasVerifiedStateDraws(String stateName) =>
      stateDrawsFor(stateName).isNotEmpty;

  static DateTime nextStateDrawing(
    StateLotteryDrawSchedule schedule, {
    required String stateName,
  }) {
    initialize();
    final zoneName = _primaryTimeZoneByState[stateName];
    final location = zoneName == null ? _easternTime : tz.getLocation(zoneName);
    final now = tz.TZDateTime.now(location);

    if (schedule.drawIntervalMinutes case final interval?) {
      final windowMinutes = schedule.drawWindowMinutes ?? interval;
      for (var offset = -1; offset <= 7; offset++) {
        final start = tz.TZDateTime(
          location,
          now.year,
          now.month,
          now.day + offset,
          schedule.hour,
          schedule.minute,
        );
        final end = start.add(Duration(minutes: windowMinutes));
        for (
          var candidate = start;
          !candidate.isAfter(end);
          candidate = candidate.add(Duration(minutes: interval))
        ) {
          if (candidate.isAfter(now)) return candidate;
        }
      }
    }

    for (var offset = 0; offset <= 7; offset++) {
      final day = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day + offset,
        schedule.hour,
        schedule.minute,
      );
      if (schedule.weekdays.contains(day.weekday) && day.isAfter(now)) {
        return day;
      }
    }

    throw StateError('Unable to calculate the next ${schedule.name} drawing.');
  }
}

class LotteryDrawSchedule {
  const LotteryDrawSchedule({
    required this.name,
    required this.weekdays,
    required this.hour,
    required this.minute,
    required this.accentColor,
  });

  final String name;
  final List<int> weekdays;
  final int hour;
  final int minute;
  final Color accentColor;
}

class StateLotteryDrawSchedule {
  const StateLotteryDrawSchedule({
    required this.name,
    required this.weekdays,
    required this.hour,
    required this.minute,
    required this.salesCutoffMinutes,
    required this.accentColor,
    this.drawIntervalMinutes,
    this.drawWindowMinutes,
  });

  final String name;
  final List<int> weekdays;
  final int hour;
  final int minute;

  /// Null when an official sales cutoff has not been verified.
  final int? salesCutoffMinutes;
  final Color accentColor;

  /// Used by games such as Carolina Keno that have frequent drawings within
  /// a published daily drawing window.
  final int? drawIntervalMinutes;
  final int? drawWindowMinutes;
}
