import 'package:flutter_test/flutter_test.dart';
import 'package:neon_calculator/calculator/stats.dart';

void main() {
  group('数字解析', () {
    test('逗号/空格/换行/中文逗号分隔', () {
      final s = parseStats('1, 2，3 4\n5\t6;');
      expect(s.count, 6);
      expect(s.invalid, 0);
      expect(s.sum, 21);
    });

    test('非法片段计数', () {
      final s = parseStats('1, abc, 2.5, -3, 1e2');
      expect(s.count, 4);
      expect(s.sum, closeTo(100.5, 1e-9));
      expect(s.invalid, 1);
    });

    test('空输入', () {
      final s = parseStats('   ');
      expect(s.count, 0);
      expect(s.mean, 0);
      expect(s.populationVariance, isNull);
      expect(s.sampleVariance, isNull);
      expect(s.sampleStdDev, isNull);
    });
  });

  group('统计量', () {
    test('基本统计量', () {
      final s = parseStats('5, 1, 9, 3, 7');
      expect(s.count, 5);
      expect(s.sum, 25);
      expect(s.mean, 5);
      expect(s.min, 1);
      expect(s.max, 9);
      expect(s.range, 8);
    });

    test('总体方差与标准差', () {
      // 经典数据集：均值 5，离差平方和 32
      final s = parseStats('2 4 4 4 5 5 7 9');
      expect(s.mean, 5);
      expect(s.populationVariance, closeTo(4, 1e-9));
      expect(s.populationStdDev, closeTo(2, 1e-9));
      expect(s.sampleVariance, closeTo(32 / 7, 1e-9));
      expect(s.sampleStdDev, closeTo(2.13809, 1e-4));
    });

    test('单个数值', () {
      final s = parseStats('42');
      expect(s.count, 1);
      expect(s.mean, 42);
      expect(s.populationVariance, 0);
      expect(s.sampleVariance, isNull); // n-1 = 0 无定义
    });

    test('含负数', () {
      final s = parseStats('-2, 2');
      expect(s.mean, 0);
      expect(s.populationVariance, closeTo(4, 1e-9));
      expect(s.min, -2);
      expect(s.max, 2);
    });
  });
}
