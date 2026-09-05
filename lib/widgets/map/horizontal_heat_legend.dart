import 'package:flutter/material.dart';

/// Compact horizontal heat index intended to sit directly above a timeline.
class HorizontalHeatLegend extends StatelessWidget {
  const HorizontalHeatLegend({
    super.key,
    required this.isSampleData,
    this.onSourceTap,
  });

  final bool isSampleData;
  final VoidCallback? onSourceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xED0A1824),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'HEAT INDEX',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(width: 12),
          const _HeatScale(),
          const SizedBox(width: 10),
          const Text(
            'Low',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(width: 6),
          const Text(
            'High',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          if (onSourceTap != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: isSampleData
                  ? 'Sample map activity. Select for source details.'
                  : 'View map data source and freshness.',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSourceTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(
                      isSampleData
                          ? Icons.science_outlined
                          : Icons.info_outline_rounded,
                      color: isSampleData
                          ? const Color(0xFFFFC107)
                          : const Color(0xFF93C5FD),
                      size: 17,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeatScale extends StatelessWidget {
  const _HeatScale();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 144,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1478FF),
            Color(0xFF22C55E),
            Color(0xFFFACC15),
            Color(0xFFF97316),
            Color(0xFFEF4444),
          ],
        ),
      ),
    );
  }
}
