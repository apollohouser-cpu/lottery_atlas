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
    this.horizontal = false,
  });

  final VoidCallback onReset;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onHome;
  final VoidCallback? onBack;
  final String backTooltip;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (onBack != null)
        _MapActionButton(
          icon: Icons.arrow_back_rounded,
          tooltip: backTooltip,
          onTap: onBack!,
        ),
      if (onHome != null)
        _MapActionButton(
          icon: Icons.home_rounded,
          tooltip: 'Home',
          onTap: onHome!,
        ),
      _MapActionButton(
        icon: Icons.center_focus_strong_rounded,
        tooltip: 'Recenter map',
        onTap: onReset,
      ),
      _MapActionButton(
        icon: Icons.add_rounded,
        tooltip: 'Zoom in',
        onTap: onZoomIn,
      ),
      _MapActionButton(
        icon: Icons.remove_rounded,
        tooltip: 'Zoom out',
        onTap: onZoomOut,
      ),
    ];
    if (horizontal) {
      return Row(
        children: [
          for (final button in buttons) Expanded(child: Center(child: button)),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          buttons[i],
        ],
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
