import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// Display cells around published locations, clipped to actual county geometry.
/// Cells are a visualization, not town boundaries or estimated missing wins.
class CountyHeatRegion {
  const CountyHeatRegion(this.points, this.holes, this.sites);
  final List<LatLng> points;
  final List<List<LatLng>> holes;
  final List<(LatLng, Color)> sites;
}

class CountyHeatLayer extends StatelessWidget {
  const CountyHeatLayer({super.key, required this.regions});
  final List<CountyHeatRegion> regions;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      size: Size.infinite,
      painter: _CountyHeatPainter(MapCamera.of(context), regions),
    ),
  );
}

/// Clips a convex display cell to the half plane nearest [site].
List<Offset> nearestSiteCell(List<Offset> cell, Offset site, Offset other) {
  final normal = other - site;
  if (normal.distanceSquared < 0.000001) return cell;
  final midpoint = (site + other) / 2;
  double distance(Offset p) =>
      (p.dx - midpoint.dx) * normal.dx + (p.dy - midpoint.dy) * normal.dy;
  final out = <Offset>[];
  for (var i = 0; i < cell.length; i++) {
    final a = cell[i], b = cell[(i + 1) % cell.length];
    final da = distance(a), db = distance(b);
    if (da <= 0) out.add(a);
    if ((da <= 0) != (db <= 0)) out.add(a + (b - a) * (da / (da - db)));
  }
  return out;
}

class _CountyHeatPainter extends CustomPainter {
  _CountyHeatPainter(this.camera, this.regions);
  final MapCamera camera;
  final List<CountyHeatRegion> regions;
  Offset project(LatLng p) {
    final v = camera.latLngToScreenPoint(p);
    return Offset(v.x, v.y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      if (region.sites.isEmpty || region.points.length < 3) continue;
      final path = Path()..fillType = PathFillType.evenOdd;
      path.addPolygon(region.points.map(project).toList(), true);
      for (final hole in region.holes) {
        path.addPolygon(hole.map(project).toList(), true);
      }
      final bounds = path.getBounds();
      if (!bounds.overlaps(Offset.zero & size)) continue;
      canvas.save();
      canvas.clipPath(path);
      final sites = region.sites.map((s) => (project(s.$1), s.$2)).toList();
      for (var i = 0; i < sites.length; i++) {
        var cell = [
          bounds.topLeft,
          bounds.topRight,
          bounds.bottomRight,
          bounds.bottomLeft,
        ];
        for (var j = 0; j < sites.length && cell.isNotEmpty; j++) {
          if (i != j) cell = nearestSiteCell(cell, sites[i].$1, sites[j].$1);
        }
        if (cell.length >= 3) {
          canvas.drawPath(
            Path()..addPolygon(cell, true),
            Paint()..color = sites[i].$2.withValues(alpha: 0.65),
          );
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CountyHeatPainter oldDelegate) => true;
}
