import 'package:flutter/material.dart';

import '../../screens/favorites/favorites_screen.dart';
import '../../screens/games/games_screen.dart';
import '../../screens/stats/stats_screen.dart';
import '../../screens/settings/settings_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _activeIndex = 0;

  Future<void> _handleTap(int index) async {
    if (index == 0) {
      setState(() {
        _activeIndex = 0;
      });
      return;
    }

    if (index == 3) {
      setState(() {
        _activeIndex = 3;
      });

      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));

      if (!mounted) {
        return;
      }

      setState(() {
        _activeIndex = 0;
      });

      return;
    }

    if (index == 1) {
      setState(() {
        _activeIndex = 1;
      });

      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const GamesScreen()));

      if (!mounted) {
        return;
      }

      setState(() {
        _activeIndex = 0;
      });

      return;
    }

    if (index == 2) {
      setState(() {
        _activeIndex = 2;
      });

      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const StatsScreen()));

      if (!mounted) {
        return;
      }

      setState(() {
        _activeIndex = 0;
      });

      return;
    }

    if (index == 4) {
      setState(() {
        _activeIndex = 4;
      });

      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

      if (!mounted) {
        return;
      }

      setState(() {
        _activeIndex = 0;
      });

      return;
    }

    setState(() {
      _activeIndex = index;
    });

    final labels = ['Map', 'Games', 'Stats', 'Favorites', 'Settings'];

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${labels[index]} is coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(label: 'Map', icon: Icons.map_outlined, activeIcon: Icons.map),
      _NavItem(
        label: 'Games',
        icon: Icons.casino_outlined,
        activeIcon: Icons.casino,
      ),
      _NavItem(
        label: 'Stats',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
      ),
      _NavItem(
        label: 'Favorites',
        icon: Icons.star_border_rounded,
        activeIcon: Icons.star_rounded,
      ),
      _NavItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 78,
        decoration: const BoxDecoration(
          color: Color(0xF2071827),
          border: Border(top: BorderSide(color: Color(0xFF263C4F))),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = index == _activeIndex;

            return Expanded(
              child: InkWell(
                onTap: () => _handleTap(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive
                            ? const Color(0xFF1478FF)
                            : Colors.white60,
                        size: 27,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFF1478FF)
                              : Colors.white60,
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
