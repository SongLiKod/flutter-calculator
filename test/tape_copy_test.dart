import 'package:flutter_test/flutter_test.dart';
import 'package:neon_calculator/widgets/display.dart';
import 'package:neon_calculator/widgets/history_sheet.dart';

void main() {
  final t = DateTime(2026, 1, 1);

  final tape = [
    HistoryEntry('7×8', '56', t),
    HistoryEntry('6×7', '42', t),
    HistoryEntry('5÷2', '2.5', t),
  ];

  test('复制用的累计和与显示的Σ同一次累加（无千分位）', () {
    expect(runningTotalValue(tape, 0), '56');
    expect(runningTotalValue(tape, 1), '98');
    expect(runningTotalValue(tape, 2), '100.5');
    // 显示层带千分位，与复制值同源
    expect(runningTotals(tape), ['56', '98', '100.5']);
  });

  test('和的等式为算式链，单笔时无 + 链', () {
    expect(runningTotalEquation(tape, 0), '7×8 = 56');
    expect(runningTotalEquation(tape, 1), '7×8 + 6×7 = 98');
    expect(runningTotalEquation(tape, 2), '7×8 + 6×7 + 5÷2 = 100.5');
  });

  test('和为负数时复制纯负值，行首一元负号的算式补括号', () {
    final neg = [
      HistoryEntry('5−9', '-4', t),
      HistoryEntry('−3×2', '-6', t),
    ];
    expect(runningTotalValue(neg, 1), '-10');
    expect(runningTotalEquation(neg, 1), '5−9 + (−3×2) = -10');
  });

  test('结果链等式只含各行结果，负数转为减号', () {
    expect(runningTotalResultChain(tape, 0), '56 = 56');
    expect(runningTotalResultChain(tape, 1), '56 + 42 = 98');
    expect(runningTotalResultChain(tape, 2), '56 + 42 + 2.5 = 100.5');

    final neg = [
      HistoryEntry('5−9', '-4', t),
      HistoryEntry('−3×2', '-6', t),
    ];
    expect(runningTotalResultChain(neg, 1), '-4 - 6 = -10');
  });

  test('大数无千分位，浮点噪声与超大值按结果复制惯例', () {
    final misc = [
      HistoryEntry('1234×1000000', '1234000000', t),
      HistoryEntry('0.1+0.2', '0.30000000000000004', t),
    ];
    expect(runningTotalValue(misc, 1), '1234000000.3');

    final huge = [HistoryEntry('1e15', '1e15', t)];
    expect(runningTotalValue(huge, 0), '1e+15');
    expect(runningTotalEquation(huge, 0), '1e15 = 1e+15');
  });
}
