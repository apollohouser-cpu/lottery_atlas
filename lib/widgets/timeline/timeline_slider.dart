import 'package:flutter/material.dart';

class TimelineSlider extends StatelessWidget {
  const TimelineSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Slider(value: 2026, min: 2000, max: 2026, onChanged: (value) {});
  }
}
