import 'package:flutter/material.dart';

import '../../models/state_model.dart';
import 'lottery_overview_screen.dart';

class StateDetailsScreen extends StatelessWidget {
  const StateDetailsScreen({super.key, required this.state});

  final StateModel state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(state.name),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.abbreviation,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 30),
            _buildCard(
              title: 'Lottery Overview',
              subtitle:
                  'Powerball, Mega Millions, and state lottery statistics',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LotteryOverviewScreen(state: state),
                  ),
                );
              },
            ),
            _buildCard(
              title: 'Scratch-Off Games',
              subtitle:
                  'Available scratch games, prizes, and remaining jackpots',
            ),
            _buildCard(
              title: 'Counties',
              subtitle: 'View winning locations by county',
            ),
            _buildCard(
              title: 'Retailers',
              subtitle: 'Stores ranked by winning tickets and prizes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return _HoverMenuCard(title: title, subtitle: subtitle, onTap: onTap);
  }
}

class _HoverMenuCard extends StatefulWidget {
  const _HoverMenuCard({
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  State<_HoverMenuCard> createState() => _HoverMenuCardState();
}

class _HoverMenuCardState extends State<_HoverMenuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          scale: _isHovered ? 1.02 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isHovered
                  ? const Color(0xFF25202B)
                  : Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered ? Colors.amber : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.18),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: _isHovered ? Colors.amber : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
