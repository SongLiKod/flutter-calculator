import 'package:flutter_test/flutter_test.dart';
import 'package:neon_calculator/calculator/units.dart';

void main() {
  ConvertCategory byId(String id) =>
      convertCategories.firstWhere((c) => c.id == id);

  group('长度', () {
    test('公制互转', () {
      expect(convertValue(byId('length'), 'm', 'cm', 1.5), closeTo(150, 1e-9));
      expect(convertValue(byId('length'), 'km', 'm', 2.5), closeTo(2500, 1e-9));
      expect(convertValue(byId('length'), 'cm', 'mm', 1), closeTo(10, 1e-9));
    });

    test('公英制互转', () {
      expect(convertValue(byId('length'), 'in', 'cm', 1), closeTo(2.54, 1e-9));
      expect(convertValue(byId('length'), 'ft', 'm', 3), closeTo(0.9144, 1e-9));
      expect(convertValue(byId('length'), 'km', 'mi', 1), closeTo(0.621371, 1e-5));
    });
  });

  group('重量', () {
    test('公制', () {
      expect(convertValue(byId('mass'), 'kg', 'g', 1.5), closeTo(1500, 1e-9));
      expect(convertValue(byId('mass'), 't', 'kg', 2), closeTo(2000, 1e-9));
    });

    test('英制', () {
      expect(convertValue(byId('mass'), 'lb', 'kg', 1), closeTo(0.45359237, 1e-9));
      expect(convertValue(byId('mass'), 'oz', 'g', 1), closeTo(28.349523125, 1e-9));
    });
  });

  group('温度', () {
    test('摄氏与开尔文', () {
      expect(convertValue(byId('temp'), '°C', 'K', 100), closeTo(373.15, 1e-9));
      expect(convertValue(byId('temp'), 'K', '°C', 0), closeTo(-273.15, 1e-9));
    });

    test('摄氏与华氏', () {
      expect(convertValue(byId('temp'), '°C', '°F', 100), closeTo(212, 1e-9));
      expect(convertValue(byId('temp'), '°F', '°C', 32), closeTo(0, 1e-9));
      expect(convertValue(byId('temp'), '°C', '°F', -40), closeTo(-40, 1e-9));
    });

    test('华氏与开尔文', () {
      expect(convertValue(byId('temp'), '°F', 'K', 32), closeTo(273.15, 1e-9));
    });
  });

  group('其他类别', () {
    test('面积', () {
      expect(convertValue(byId('area'), 'ha', 'm²', 1), closeTo(10000, 1e-9));
      expect(convertValue(byId('area'), 'km²', 'ha', 2), closeTo(200, 1e-9));
    });

    test('速度', () {
      expect(convertValue(byId('speed'), 'km/h', 'm/s', 36), closeTo(10, 1e-9));
      expect(convertValue(byId('speed'), 'm/s', 'km/h', 1), closeTo(3.6, 1e-9));
    });

    test('时间', () {
      expect(convertValue(byId('time'), 'h', 'min', 1.5), closeTo(90, 1e-9));
      expect(convertValue(byId('time'), 'd', 'h', 1), closeTo(24, 1e-9));
      expect(convertValue(byId('time'), 'year', 'd', 1), closeTo(365, 1e-9));
    });

    test('数据', () {
      expect(convertValue(byId('data'), 'KB', 'B', 1), closeTo(1024, 1e-9));
      expect(convertValue(byId('data'), 'MB', 'KB', 1), closeTo(1024, 1e-9));
      expect(convertValue(byId('data'), 'GB', 'MB', 2), closeTo(2048, 1e-9));
    });
  });

  test('未知单位抛出 ArgumentError', () {
    expect(
      () => convertValue(byId('length'), 'xx', 'cm', 1),
      throwsA(isA<ArgumentError>()),
    );
  });
}
