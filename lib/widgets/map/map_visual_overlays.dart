import 'package:flutter/material.dart';

/// Essential map controls only. Favorites live in bottom navigation.
class MapActionControls extends StatelessWidget {
  const MapActionControls({
    super.key,
    required this.onReset,
    required this.onZoomIn,
    required this.onZoomOut,
    this.onHome,
    this.onBack,
    this.backTooltip = 'Back to U.S. map',
  });

  final VoidCallback onReset;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onHome;
  final VoidCallback? onBack;
  final String backTooltip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onBack != null) ...[
          _MapActionButton(
            icon: Icons.arrow_back_rounded,
            tooltip: backTooltip,
            onTap: onBack!,
          ),
          const SizedBox(height: 10),
        ],
        _MapActionButton(
          icon: onHome == null ? Icons.my_location_rounded : Icons.home_rounded,
          tooltip: onHome == null ? 'Recenter map' : 'Go to home state',
          onTap: onHome ?? onReset,
        ),
        const SizedBox(height: 10),
        _MapActionButton(
          icon: Icons.add_rounded,
          tooltip: 'Zoom in',
          onTap: onZoomIn,
        ),
        const SizedBox(height: 10),
        _MapActionButton(
          icon: Icons.remove_rounded,
          tooltip: 'Zoom out',
          onTap: onZoomOut,
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xED071827),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5B6874)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFFF2F5F8), size: 25),
          ),
        ),
      ),
    );
  }
}
