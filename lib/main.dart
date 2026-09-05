import 'package:flutter/material.dart';

import 'app/app_route_observer.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const LotteryAtlasApp());
}

class LotteryAtlasApp extends StatelessWidget {
  const LotteryAtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,

        scaffoldBackgroundColor: Colors.black,
      ),

      navigatorObservers: [appRouteObserver],

      home: HomeScreen(),
    );
  }
}
