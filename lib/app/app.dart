import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';

class LotteryAtlasApp extends StatelessWidget {
  const LotteryAtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lottery Atlas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: HomeScreen(),
    );
  }
}
