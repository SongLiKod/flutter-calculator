import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_calculator/home_page.dart';
import 'package:neon_calculator/main.dart';
import 'package:neon_calculator/widgets/neon_button.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const NeonCalculatorApp());
    await tester.pump(const Duration(milliseconds: 900));
  }

  Future<void> tapKey(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(NeonButton, label));
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('基础算式 7×8=56', (tester) async {
    await pumpApp(tester);
    await tapKey(tester, '7');
    await tapKey(tester, '×');
    await tapKey(tester, '8');
    await tapKey(tester, '=');
    expect(find.text('56'), findsWidgets);
    // 表达式与结果一致展示
    expect(find.text('7×8'), findsOneWidget);
  });

  testWidgets('输入错误显示错误态，C 清空', (tester) async {
    await pumpApp(tester);
    await tapKey(tester, '5');
    await tapKey(tester, '÷');
    await tapKey(tester, '0');
    expect(find.text('除数为零'), findsOneWidget);
    await tapKey(tester, 'C');
    expect(find.text('除数为零'), findsNothing);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('连续计算与括号', (tester) async {
    await pumpApp(tester);
    await tapKey(tester, 'C');
    await tapKey(tester, '1');
    await tapKey(tester, '+');
    await tapKey(tester, '2');
    expect(find.text('3'), findsWidgets);
    await tapKey(tester, '=');
    expect(find.text('3'), findsWidgets);
    expect(find.text('1+2'), findsOneWidget);
  });

  testWidgets('科学模式与历史记录', (tester) async {
    await pumpApp(tester);
    // 打开科学模式
    await tester.tap(find.text('科学'));
    await tester.pump(const Duration(milliseconds: 500));
    await tapKey(tester, 'sin');
    await tapKey(tester, '3');
    await tapKey(tester, '0');
    await tapKey(tester, ')');
    await tapKey(tester, '=');
    expect(find.text('0.5'), findsOneWidget);
    expect(find.text('sin(30)'), findsOneWidget);

    // 打开历史面板
    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('计算历史'), findsOneWidget);
    expect(find.text('sin(30)'), findsWidgets);
    Navigator.of(tester.element(find.text('计算历史'))).pop();
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('页面可以正常启动', (tester) async {
    await pumpApp(tester);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('NEON CALC'), findsOneWidget);
    expect(find.text('='), findsWidgets);
  });
}
