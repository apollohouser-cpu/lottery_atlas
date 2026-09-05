import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

import '../../screens/state/state_details_screen.dart';
import '../../services/state_navigation_service.dart';

class StateMap extends StatefulWidget {
  const StateMap({super.key});

  @override
  State<StateMap> createState() => _StateMapState();
}

class _StateMapState extends State<StateMap>
    with SingleTickerProviderStateMixin {
  static const Size _svgSize = Size(1000, 589);

  final TransformationController _controller = TransformationController();
  late final Future<List<_StatePath>> _statePathsFuture;
  late final AnimationController _hoverController;

  String? _hoveredState;

  @override
  void initState() {
    super.initState();

    _statePathsFuture = _loadStatePaths();

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  Future<List<_StatePath>> _loadStatePaths() async {
    final svgText = await rootBundle.loadString('assets/maps/us.svg');
    final document = XmlDocument.parse(svgText);
    final statePaths = <_StatePath>[];

    for (final element in document.findAllElements('path')) {
      final abbreviation = element.getAttribute('id');
      final pathData = element.getAttribute('d');

      if (abbreviation == null || pathData == null) {
        continue;
      }

      final path = parseSvgPathData(pathData)..fillType = PathFillType.evenOdd;

      statePaths.add(
        _StatePath(abbreviation: abbreviation.toUpperCase(), path: path),
      );
    }

    return statePaths;
  }

  void _zoomIn() {
    _controller.value = Matrix4.copy(_controller.value)..scale(1.25);
  }

  void _zoomOut() {
    _controller.value = Matrix4.copy(_controller.value)..scale(0.8);
  }

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }

  String? _stateAt(
    Offset position,
    Size displayedMapSize,
    List<_StatePath> statePaths,
  ) {
    final svgPosition = Offset(
      position.dx * _svgSize.width / displayedMapSize.width,
      position.dy * _svgSize.height / displayedMapSize.height,
    );

    for (final statePath in statePaths.reversed) {
      if (statePath.path.contains(svgPosition)) {
        return statePath.abbreviation;
      }
    }

    return null;
  }

  void _updateHover(
    Offset position,
    Size displayedMapSize,
    List<_StatePath> statePaths,
  ) {
    final state = _stateAt(position, displayedMapSize, statePaths);

    if (state == _hoveredState) {
      return;
    }

    setState(() {
      _hoveredState = state;
    });

    if (state != null) {
      _hoverController.forward(from: 0);
    } else {
      _hoverController.reset();
    }
  }

  void _clearHover() {
    if (_hoveredState == null) {
      return;
    }

    setState(() {
      _hoveredState = null;
    });

    _hoverController.reset();
  }

  void _handleStateTap(
    BuildContext context,
    Offset tapPosition,
    Size displayedMapSize,
    List<_StatePath> statePaths,
  ) {
    final abbreviation = _stateAt(tapPosition, displayedMapSize, statePaths);

    if (abbreviation == null) {
      return;
    }

    final state = StateNavigationService.getStateByAbbreviation(abbreviation);

    if (state == null) {
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => StateDetailsScreen(state: state)));
  }

  Rect _mapRectFor(Size availableSize) {
    final scale = math.min(
      availableSize.width / _svgSize.width,
      availableSize.height / _svgSize.height,
    );

    final mapSize = Size(_svgSize.width * scale, _svgSize.height * scale);

    return Rect.fromLTWH(
      (availableSize.width - mapSize.width) / 2,
      (availableSize.height - mapSize.height) / 2,
      mapSize.width,
      mapSize.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _controller,
          minScale: 1.0,
          maxScale: 8.0,
          panEnabled: true,
          scaleEnabled: true,
          trackpadScrollCausesScale: true,
          scaleFactor: 200,
          boundaryMargin: const EdgeInsets.all(300),
          child: FutureBuilder<List<_StatePath>>(
            future: _statePathsFuture,
            builder: (context, snapshot) {
              final statePaths = snapshot.data ?? const <_StatePath>[];

              return LayoutBuilder(
                builder: (context, constraints) {
                  final mapRect = _mapRectFor(constraints.biggest);

                  _StatePath? hoveredPath;

                  for (final statePath in statePaths) {
                    if (statePath.abbreviation == _hoveredState) {
                      hoveredPath = statePath;
                      break;
                    }
                  }

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _svgSize.width,
                            height: _svgSize.height,
                            child: SvgPicture.asset('assets/maps/us.svg'),
                          ),
                        ),
                      ),
                      if (hoveredPath != null)
                        Positioned.fromRect(
                          rect: mapRect,
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _StateHoverPainter(
                                path: hoveredPath.path,
                                animation: _hoverController,
                              ),
                            ),
                          ),
                        ),
                      Positioned.fromRect(
                        rect: mapRect,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onExit: (_) => _clearHover(),
                          onHover: (event) {
                            _updateHover(
                              event.localPosition,
                              mapRect.size,
                              statePaths,
                            );
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapUp: (details) {
                              _handleStateTap(
                                context,
                                details.localPosition,
                                mapRect.size,
                                statePaths,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        Positioned(
          right: 20,
          bottom: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'zoomIn',
                tooltip: 'Zoom in',
                onPressed: _zoomIn,
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.small(
                heroTag: 'zoomOut',
                tooltip: 'Zoom out',
                onPressed: _zoomOut,
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.small(
                heroTag: 'reset',
                tooltip: 'Reset map',
                onPressed: _resetZoom,
                child: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatePath {
  const _StatePath({required this.abbreviation, required this.path});

  final String abbreviation;
  final Path path;
}

class _StateHoverPainter extends CustomPainter {
  _StateHoverPainter({required this.path, required this.animation})
    : super(repaint: animation);

  final Path path;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = Curves.easeOut.transform(animation.value);
    final bounds = path.getBounds();

    canvas.save();

    canvas.scale(size.width / 1000, size.height / 589);

    final scale = 1 + (0.035 * progress);

    canvas.translate(bounds.center.dx, bounds.center.dy);
    canvas.scale(scale);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.amber.withValues(alpha: 0.25 * progress),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.amber.withValues(alpha: progress),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StateHoverPainter oldDelegate) {
    return oldDelegate.path != path || oldDelegate.animation != animation;
  }
}
