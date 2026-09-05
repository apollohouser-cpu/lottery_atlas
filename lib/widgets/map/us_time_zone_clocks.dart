import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Live clocks for the major US lottery time zones.
class UsTimeZoneClocks extends StatefulWidget {
  const UsTimeZoneClocks({super.key});

  @override
  State<UsTimeZoneClocks> createState() => _UsTimeZoneClocksState();
}

class _UsTimeZoneClocksState extends State<UsTimeZoneClocks> {
  static const List<_ZoneClock> _zones = [
    _ZoneClock('ET', 'Eastern', 'America/New_York'),
    _ZoneClock('CT', 'Central', 'America/Chicago'),
    _ZoneClock('MT', 'Mountain', 'America/Denver'),
    _ZoneClock('PT', 'Pacific', 'America/Los_Angeles'),
    _ZoneClock('AK', 'Alaska', 'America/Anchorage'),
    _ZoneClock('HI', 'Hawaii', 'Pacific/Honolulu'),
  ];

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _timeFor(_ZoneClock zone) {
    final time = tz.TZDateTime.now(tz.getLocation(zone.timeZoneId));
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 304,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xED0A1824),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.public_rounded, color: Color(0xFF60A5FA), size: 18),
                  SizedBox(width: 7),
                  Text(
                    'U.S. LOTTERY CLOCKS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final zone in _zones)
                    _ClockChip(zone: zone, timeLabel: _timeFor(zone)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockChip extends StatelessWidget {
  const _ClockChip({required this.zone, required this.timeLabel});

  final _ZoneClock zone;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF12293A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF24475D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            zone.code,
            style: const TextStyle(
              color: Color(0xFF93C5FD),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            timeLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneClock {
  const _ZoneClock(this.code, this.name, this.timeZoneId);

  final String code;
  final String name;
  final String timeZoneId;
}
