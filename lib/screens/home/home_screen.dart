import 'package:flutter/material.dart';

import '../../widgets/cards/most_winning_state_card.dart';
import '../../widgets/map/lottery_map.dart';
import '../../widgets/navigation/bottom_nav.dart';
import '../../services/map_focus_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    MapFocusService.requestedFocus.addListener(_scrollToMap);
  }

  @override
  void dispose() {
    MapFocusService.requestedFocus.removeListener(_scrollToMap);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToMap() {
    if (MapFocusService.requestedFocus.value == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // The map gets the previously unused vertical space. Its
                  // heat index and timeline remain docked at the map bottom,
                  // and the Trending States card naturally moves down below it.
                  final mapHeight = (constraints.maxHeight * 0.84).clamp(
                    720.0,
                    1040.0,
                  );

                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 18),
                    children: [
                      SizedBox(height: mapHeight, child: const LotteryMap()),
                      const SizedBox(height: 14),
                      const MostWinningStateCard(),
                    ],
                  );
                },
              ),
            ),
            const BottomNav(),
          ],
        ),
      ),
    );
  }
}
