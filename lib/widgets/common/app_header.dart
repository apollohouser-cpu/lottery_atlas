import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Lottery Atlas',
      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    );
  }
}
