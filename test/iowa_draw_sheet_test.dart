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
}
