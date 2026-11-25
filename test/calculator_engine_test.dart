import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:neon_calculator/calculator/engine.dart';

void main() {
  group('基本运算', () {
    test('四则运算', () {
      expect(evaluate('1+2×3'), 7);
      expect(evaluate('(1+2)×3'), 9);
      expect(evaluate('10÷4'), 2.5);
      expect(evaluate('2^10'), 1024);
    });

    test('除数为零抛出错误', () {
      expect(() => evaluate('5÷0'), throwsA(isA<CalcException>()));
      expect(() => evaluate('5÷(2-2)'), throwsA(isA<CalcException>()));
    });

    test('输入未完成抛出 IncompleteException', () {
      expect(() => evaluate('5+'), throwsA(isA<IncompleteException>()));
      expect(() => evaluate('(1+2'), throwsA(isA<IncompleteException>()));
      expect(() => evaluate(''), throwsA(isA<IncompleteException>()));
    });

    test('一元负号', () {
      expect(evaluate('−5+3'), -2);
      expect(evaluate('−2^2'), -4);
      expect(evaluate('5-(-3)'), 8);
    });
  });

  group('百分比', () {
    test('加减中的百分比按比例计算', () {
      expect(evaluate('200+50%'), 300);
      expect(evaluate('200-50%'), 100);
      expect(evaluate('200+50%+10%'), 330);
    });

    test('乘除中的百分比等于除以一百', () {
      expect(evaluate('200×50%'), 100);
      expect(evaluate('50%×200'), 100);
      expect(evaluate('200×25%'), 50);
    });
  });

  group('函数与常量', () {
    test('角度制三角函数', () {
      expect(formatNumber(evaluate('sin(30)')), '0.5');
      expect(formatNumber(evaluate('cos(60)')), '0.5');
      expect(evaluate('tan(45)'), closeTo(1, 1e-9));
    });

    test('弧度制三角函数', () {
      expect(evaluate('sin(π÷2)', degrees: false), closeTo(1, 1e-9));
    });

    test('对数与开方', () {
      expect(evaluate('ln(e)'), closeTo(1, 1e-9));
      expect(evaluate('log(1000)'), closeTo(3, 1e-9));
      expect(evaluate('√(9)'), 3);
      expect(() => evaluate('√(-1)'), throwsA(isA<CalcException>()));
      expect(() => evaluate('ln(0)'), throwsA(isA<CalcException>()));
    });

    test('阶乘与常量', () {
      expect(evaluate('5!'), 120);
      expect(evaluate('0!'), 1);
      expect(evaluate('π'), closeTo(3.14159265, 1e-6));
      expect(evaluate('2×e'), closeTo(5.43656365, 1e-6));
    });
  });

  group('扩展函数', () {
    test('反三角函数（角度制）', () {
      expect(formatNumber(evaluate('asin(0.5)')), '30');
      expect(formatNumber(evaluate('acos(0.5)')), '60');
      expect(formatNumber(evaluate('atan(1)')), '45');
      expect(() => evaluate('asin(2)'), throwsA(isA<CalcException>()));
      expect(() => evaluate('acos(-1.5)'), throwsA(isA<CalcException>()));
    });

    test('反三角函数（弧度制）', () {
      expect(evaluate('asin(1)', degrees: false), closeTo(math.pi / 2, 1e-9));
      expect(evaluate('atan(1)', degrees: false), closeTo(math.pi / 4, 1e-9));
    });

    test('双曲函数', () {
      expect(evaluate('sinh(0)'), 0);
      expect(evaluate('cosh(0)'), 1);
      expect(evaluate('tanh(0)'), 0);
      expect(evaluate('sinh(1)'), closeTo(1.175201, 1e-5));
      expect(evaluate('cosh(1)'), closeTo(1.543081, 1e-5));
      expect(evaluate('tanh(1)'), closeTo(0.761594, 1e-5));
      expect(evaluate('tanh(100)'), 1);
    });

    test('反双曲函数与定义域', () {
      expect(evaluate('asinh(0)'), 0);
      expect(evaluate('acosh(1)'), 0);
      expect(evaluate('atanh(0)'), 0);
      expect(evaluate('asinh(1)'), closeTo(0.881374, 1e-5));
      expect(() => evaluate('acosh(0.5)'), throwsA(isA<CalcException>()));
      expect(() => evaluate('atanh(1)'), throwsA(isA<CalcException>()));
    });

    test('绝对值', () {
      expect(evaluate('abs(−5)'), 5);
      expect(evaluate('abs(3−8)'), 5);
      expect(formatNumber(evaluate('abs(−2.5)+1')), '3.5');
    });
  });

  group('科学计数输入', () {
    test('EXP 展开为普通数字', () {
      expect(evaluate('6.02e23'), 6.02e23);
      expect(evaluate('1.5e-3'), 0.0015);
      expect(evaluate('2e+3'), 2000);
      expect(evaluate('1e3×2'), 2000);
    });

    test('悬空的 e 视为输入未完成', () {
      expect(() => evaluate('6.02e'), throwsA(isA<IncompleteException>()));
      expect(() => evaluate('6.02e+'), throwsA(isA<IncompleteException>()));
      expect(livePreview('6.02e').text, '');
    });

    test('常量 e 写法不受影响', () {
      expect(evaluate('2×e'), closeTo(2 * math.e, 1e-9));
      expect(evaluate('e^2'), closeTo(math.e * math.e, 1e-9));
      expect(evaluate('(e+1)×2'), closeTo((math.e + 1) * 2, 1e-9));
    });

    test('科学计数结果可再次求值', () {
      final raw = formatNumber(evaluate('2^100'), grouped: false);
      expect(raw, contains('e'));
      final again = evaluate(raw);
      expect(formatNumber(again, grouped: false), raw);
    });
  });

  group('格式化', () {
    test('去除浮点噪声', () {
      expect(formatNumber(evaluate('0.1+0.2')), '0.3');
      expect(formatNumber(evaluate('1÷3×3')), '1');
    });

    test('千分位', () {
      expect(formatNumber(evaluate('1234567+1')), '1,234,568');
      expect(formatNumber(evaluate('9999.5×2')), '19,999');
    });

    test('不带分隔符的结果可再次求值', () {
      final raw = formatNumber(evaluate('1234567+1'), grouped: false);
      expect(raw, '1234568');
      expect(evaluate('$raw+1'), 1234569);
    });

    test('极大/极小值使用科学计数法', () {
      expect(formatNumber(evaluate('2^40')), '1.099512e+12');
      expect(formatNumber(0.0000000001), '1e-10');
    });

    test('表达式加千分位', () {
      expect(groupExpression('12345+678'), '12,345+678');
      expect(groupExpression('sin(30)'), 'sin(30)');
    });
  });

  group('实时预览', () {
    test('未完成时返回空', () {
      expect(livePreview('').text, '');
      expect(livePreview('12+').text, '');
      expect(livePreview('sin(').text, '');
    });

    test('错误时返回错误文案', () {
      final preview = livePreview('5÷0');
      expect(preview.error, true);
      expect(preview.text, '除数为零');
    });

    test('正常时返回结果', () {
      expect(livePreview('12×12').text, '144');
    });
  });
}
