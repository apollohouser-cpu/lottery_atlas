import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/widgets/map/iowa_instant_inventory_sheet.dart';
void main(){
 final data=jsonDecode(File('data/iowa_coverage.generated.json').readAsStringSync()) as Map<String,dynamic>;
 testWidgets('three typed inventories render at enlarged text',(tester)async{
  for(final type in ['Scratch','InstaPlay','PullTab']){
   await tester.pumpWidget(MaterialApp(home:MediaQuery(data:const MediaQueryData(size:Size(390,844),textScaler:TextScaler.linear(2)),child:Scaffold(body:IowaInstantInventorySheet(key:ValueKey(type),coverageOverride:data,initialType:type)))));
   await tester.pumpAndSettle();expect(find.textContaining('$type games in report'),findsOneWidget);expect(tester.takeException(),isNull);
  }
 });
 testWidgets('search detail and return preserve filter',(tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:IowaInstantInventorySheet(coverageOverride:data,initialType:'PullTab'))));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField),'WHAT A GEM');await tester.pumpAndSettle();
  expect(find.text('1 of 9 PullTab games in report'),findsOneWidget);
  await tester.tap(find.text('WHAT A GEM! (4)'));await tester.pumpAndSettle();
  expect(find.text('Published prize: \$1999'),findsOneWidget);
  expect(find.textContaining('current progressive jackpot'),findsOneWidget);
  await tester.tap(find.byTooltip('Close game details'));await tester.pumpAndSettle();
  expect(find.text('1 of 9 PullTab games in report'),findsOneWidget);
  await tester.tap(find.text('Reset'));await tester.pumpAndSettle();expect(find.text('9 of 9 PullTab games in report'),findsOneWidget);
  expect(tester.takeException(),isNull);
 });
}
