import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottery_atlas/widgets/map/county_heat_layer.dart';

void main() {
  testWidgets('mixed county colors stay inside boundaries and preserve holes', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: RepaintBoundary(
              key: key,
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(0, 0),
                  initialZoom: 7,
                  backgroundColor: Colors.black,
                ),
                children: [
                  CountyHeatLayer(
                    regions: [
                      CountyHeatRegion(
                        const [
                          LatLng(-1, -1),
                          LatLng(-1, 1),
                          LatLng(1, 1),
                          LatLng(1, -1),
                        ],
                        const [
                          [
                            LatLng(-.1, -.1),
                            LatLng(-.1, .1),
                            LatLng(.1, .1),
                            LatLng(.1, -.1),
                          ],
                        ],
                        const [
                          (LatLng(0, -.5), Colors.blue),
                          (LatLng(0, .5), Colors.red),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = (await tester.runAsync(() => boundary.toImage()))!;
    final bytes = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    final camera = MapCamera.of(tester.element(find.byType(CountyHeatLayer)));
    List<int> pixel(LatLng p) {
      final at = camera.latLngToScreenPoint(p);
      final i = (at.y.round() * image.width + at.x.round()) * 4;
      return [bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2)];
    }

    expect(pixel(const LatLng(0, -.5))[2], greaterThan(100));
    expect(pixel(const LatLng(0, .5))[0], greaterThan(100));
    expect(pixel(const LatLng(0, 0)), [0, 0, 0]);
    expect(pixel(const LatLng(1.5, 0)), [0, 0, 0]);
    image.dispose();
    expect(tester.takeException(), isNull);
  });
}
