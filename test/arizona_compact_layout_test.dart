import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/arizona_coverage_loader.dart';
import 'package:lottery_atlas/widgets/map/arizona_coverage_view.dart';

void main() {
  final raw = File(
    'test/fixtures/arizona_coverage_candidate.json',
  ).readAsStringSync();
  for (final products in [false, true]) {
    testWidgets(
      'landscape 2x ${products ? 'products' : 'draws'} keeps exit usable',
      (tester) async {
        tester.view.physicalSize = const Size(844, 390);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: ArizonaCoverageView(
                products: products,
                loader: ArizonaCoverageLoader(
                  readBundle: () async => raw,
                  readCache: () async => null,
                  writeCache: (_) async {},
                  fetchRemote: () async => throw StateError('offline'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find
              .byTooltip(
                products ? 'Close Arizona products' : 'Close Arizona draws',
              )
              .hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
