/// 单位换算：类别 + 单位定义与换算逻辑（纯 Dart，便于单测）。
library;

/// 单位定义。[factor] 表示 1 该单位 = [factor] 个基准单位。
class ConvertUnit {
  final String symbol;
  final String name;
  final double factor;

  const ConvertUnit(this.symbol, this.name, this.factor);
}

/// 换算类别。温度为线性公式特例（`special == 'temp'`）。
class ConvertCategory {
  final String id;
  final String name;
  final String? special;
  final List<ConvertUnit> units;

  const ConvertCategory({
    required this.id,
    required this.name,
    this.special,
    required this.units,
  });

  ConvertUnit? unitOf(String symbol) {
    for (final u in units) {
      if (u.symbol == symbol) return u;
    }
    return null;
  }
}

const List<ConvertCategory> convertCategories = [
  ConvertCategory(
    id: 'length',
    name: '长度',
    units: [
      ConvertUnit('mm', '毫米', 0.001),
      ConvertUnit('cm', '厘米', 0.01),
      ConvertUnit('m', '米', 1),
      ConvertUnit('km', '千米', 1000),
      ConvertUnit('in', '英寸', 0.0254),
      ConvertUnit('ft', '英尺', 0.3048),
      ConvertUnit('yd', '码', 0.9144),
      ConvertUnit('mi', '英里', 1609.344),
    ],
  ),
  ConvertCategory(
    id: 'mass',
    name: '重量',
    units: [
      ConvertUnit('mg', '毫克', 0.000001),
      ConvertUnit('g', '克', 0.001),
      ConvertUnit('kg', '千克', 1),
      ConvertUnit('t', '吨', 1000),
      ConvertUnit('oz', '盎司', 0.028349523125),
      ConvertUnit('lb', '磅', 0.45359237),
    ],
  ),
  ConvertCategory(
    id: 'temp',
    name: '温度',
    special: 'temp',
    units: [
      ConvertUnit('°C', '摄氏度', 1),
      ConvertUnit('°F', '华氏度', 1),
      ConvertUnit('K', '开尔文', 1),
    ],
  ),
  ConvertCategory(
    id: 'area',
    name: '面积',
    units: [
      ConvertUnit('mm²', '平方毫米', 0.000001),
      ConvertUnit('m²', '平方米', 1),
      ConvertUnit('km²', '平方千米', 1000000),
      ConvertUnit('ha', '公顷', 10000),
      ConvertUnit('acre', '英亩', 4046.8564224),
      ConvertUnit('ft²', '平方英尺', 0.09290304),
    ],
  ),
  ConvertCategory(
    id: 'speed',
    name: '速度',
    units: [
      ConvertUnit('m/s', '米/秒', 1),
      ConvertUnit('km/h', '千米/时', 1 / 3.6),
      ConvertUnit('mph', '英里/时', 1609.344 / 3600),
      ConvertUnit('kn', '节', 1852 / 3600),
      ConvertUnit('ft/s', '英尺/秒', 0.3048),
    ],
  ),
  ConvertCategory(
    id: 'time',
    name: '时间',
    units: [
      ConvertUnit('ms', '毫秒', 0.001),
      ConvertUnit('s', '秒', 1),
      ConvertUnit('min', '分钟', 60),
      ConvertUnit('h', '小时', 3600),
      ConvertUnit('d', '天', 86400),
      ConvertUnit('week', '周', 604800),
      ConvertUnit('year', '年', 31536000),
    ],
  ),
  ConvertCategory(
    id: 'data',
    name: '数据',
    units: [
      ConvertUnit('bit', '比特', 0.125),
      ConvertUnit('B', '字节', 1),
      ConvertUnit('KB', '千字节', 1024),
      ConvertUnit('MB', '兆字节', 1048576),
      ConvertUnit('GB', '吉字节', 1073741824),
      ConvertUnit('TB', '太字节', 1099511627776),
    ],
  ),
];

double _tempToCelsius(double v, String unit) {
  switch (unit) {
    case '°F':
      return (v - 32) * 5 / 9;
    case 'K':
      return v - 273.15;
    default:
      return v;
  }
}

double _celsiusToTemp(double c, String unit) {
  switch (unit) {
    case '°F':
      return c * 9 / 5 + 32;
    case 'K':
      return c + 273.15;
    default:
      return c;
  }
}

/// 把 [value] 从 [from] 单位换算为 [to] 单位。未知单位抛出 [ArgumentError]。
double convertValue(ConvertCategory category, String from, String to, double value) {
  if (category.special == 'temp') {
    return _celsiusToTemp(_tempToCelsius(value, from), to);
  }
  final src = category.unitOf(from);
  final dst = category.unitOf(to);
  if (src == null || dst == null) {
    throw ArgumentError('未知单位');
  }
  return value * src.factor / dst.factor;
}
