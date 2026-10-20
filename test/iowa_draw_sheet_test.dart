import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/widgets/map/iowa_draw_collection_sheet.dart';

void main(){
  final data=jsonDecode(File('data/iowa_coverage.generated.json').readAsStringSync()) as Map<String,dynamic>;
  testWidgets('all twenty selections render at enlarged text without errors',(tester)async{
    for(var i=0;i<20;i++){
      await tester.pumpWidget(MaterialApp(home:MediaQuery(data:const MediaQueryData(size:Size(390,844),textScaler:TextScaler.linear(2)),child:Scaffold(body:IowaDrawCollectionSheet(key:ValueKey(i),coverageOverride:data,initialIndex:i)))));
      await tester.pumpAndSettle();
      expect(find.text('Iowa results and schedules'),findsOneWidget);
      expect(tester.takeException(),isNull,reason:'selection $i');
    }
  });
  testWidgets('Double Play retains distinct chart and explicit shared-page warning',(tester)async{
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:IowaDrawCollectionSheet(coverageOverride:data,initialIndex:2))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Shared Powerball source page'),500,scrollable:find.byType(Scrollable).last,maxScrolls:35);
    expect(find.textContaining('Regular jackpot, Power Play and annuity terms do not describe Double Play prizes.'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
  testWidgets('long schedules reach final source at 2x in portrait and landscape', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(390,844), const Size(844,390)]) {
      tester.view.physicalSize = size;
      for (final index in [0,2,4,6,8,10,14,18]) {
        await tester.pumpWidget(MaterialApp(home:MediaQuery(
          data:MediaQueryData(size:size,textScaler:const TextScaler.linear(2)),
          child:Scaffold(body:IowaDrawCollectionSheet(key:ValueKey('$size-$index'),coverageOverride:data,initialIndex:index)))));
        await tester.pumpAndSettle();
        expect(tester.takeException(),isNull,reason:'initial $size selection $index');
        await tester.scrollUntilVisible(find.text('Official results and history'),250,
          scrollable:find.byType(Scrollable).last,maxScrolls:250);
        await tester.pumpAndSettle();
        expect(find.text('Official results and history').hitTestable(),findsOneWidget);
        expect(tester.takeException(),isNull,reason:'end $size selection $index');
      }
    }
  });

}
