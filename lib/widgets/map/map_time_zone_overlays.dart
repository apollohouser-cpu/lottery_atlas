import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// A clean, introductory time-zone overlay for the contiguous US.
///
/// It deliberately uses broad bands for readability. A future data layer can
/// replace these with the exact legal time-zone boundary polygons.
class TimeZoneBoundaryBands extends StatelessWidget {
  const TimeZoneBoundaryBands({super.key});

  static const List<_TimeZoneBand> _bands = [
    _TimeZoneBand('Pacific', -125, -114, Color(0x161478FF)),
    _TimeZoneBand('Mountain', -114, -102, Color(0x1614B8A6)),
    _TimeZoneBand('Central', -102, -86, Color(0x16F59E0B)),
    _TimeZoneBand('Eastern', -86, -66, Color(0x16A855F7)),
  ];

  @override
  Widget build(BuildContext context) {
    return PolygonLayer(
      polygons: [
        for (final band in _bands)
          Polygon(
            points: [
              LatLng(24, band.westLongitude),
              LatLng(50, band.westLongitude),
              LatLng(50, band.eastLongitude),
              LatLng(24, band.eastLongitude),
            ],
            color: band.color,
            borderColor: const Color(0xAA93C5FD),
            borderStrokeWidth: 1.3,
          ),
      ],
    );
  }
}

/// Live clock labels placed inside their approximate geographic time zones.
class TimeZoneClockMarkers extends StatefulWidget {
  const TimeZoneClockMarkers({super.key});

  @override
  State<TimeZoneClockMarkers> createState() => _TimeZoneClockMarkersState();
}

class _TimeZoneClockMarkersState extends State<TimeZoneClockMarkers> {
  static const List<_ClockZone> _zones = [
    _ClockZone('PT', 'Pacific', 'America/Los_Angeles', LatLng(48.2, -119.5)),
    _ClockZone('MT', 'Mountain', 'America/Denver', LatLng(48.2, -108.0)),
    _ClockZone('CT', 'Central', 'America/Chicago', LatLng(48.2, -94.2)),
    _ClockZone('ET', 'Eastern', 'America/New_York', LatLng(48.2, -77.0)),
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

  String _timeFor(_ClockZone zone) {
    final time = tz.TZDateTime.now(tz.getLocation(zone.timeZoneId));
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        for (final zone in _zones)
          Marker(
            point: zone.location,
            width: 96,
            height: 48,
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xE60A1824),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xCC93C5FD)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 8),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.code,
                        style: const TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      Text(
                        _timeFor(zone),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class TimeZoneMenu extends StatelessWidget {
  const TimeZoneMenu({
    super.key,
    required this.isVisible,
    required this.onVisibilityChanged,
  });

  final bool isVisible;
  final ValueChanged<bool> onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 190,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xED0A1824),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF93C5FD),
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Time Zones',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: isVisible,
                      activeTrackColor: const Color(0xFF1478FF),
                      onChanged: onVisibilityChanged,
                    ),
                  ],
                ),
              ),
              if (isVisible)
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 11),
                  child: Text(
                    'Live local times shown directly in each map zone.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeZoneBand {
  const _TimeZoneBand(
    this.name,
    this.westLongitude,
    this.eastLongitude,
    this.color,
  );

  final String name;
  final double westLongitude;
  final double eastLongitude;
  final Color color;
}

class _ClockZone {
  const _ClockZone(this.code, this.name, this.timeZoneId, this.location);

  final String code;
  final String name;
  final String timeZoneId;
  final LatLng location;
}
