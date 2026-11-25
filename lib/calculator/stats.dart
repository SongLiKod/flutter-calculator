/// 统计计算：解析一串数字并给出基础统计量（纯 Dart，便于单测）。
library;

import 'dart:math' as math;

class StatsResult {
  /// 参与统计的原始数值。
  final List<double> values;

  /// 非法片段数量（无法解析为数字的输入）。
  final int invalid;

  const StatsResult._({
    required this.values,
    required this.invalid,
    required this.sum,
    required this.min,
    required this.max,
  });

  int get count => values.length;

  final double sum;
  final double min;
  final double max;

  double get mean => count == 0 ? 0 : sum / count;

  double get range => max - min;

  /// 总体方差（除以 n）。样本数为 0 时返回 null。
  double? get populationVariance {
    if (count == 0) return null;
    final m = mean;
    var acc = 0.0;
    for (final v in values) {
      acc += (v - m) * (v - m);
    }
    return acc / count;
  }

  /// 样本方差（除以 n-1）。样本数不足 2 时返回 null。
  double? get sampleVariance {
    if (count < 2) return null;
    final m = mean;
    var acc = 0.0;
    for (final v in values) {
      acc += (v - m) * (v - m);
    }
    return acc / (count - 1);
  }

  double? get populationStdDev {
    final v = populationVariance;
    return v == null ? null : math.sqrt(v);
  }

  double? get sampleStdDev {
    final v = sampleVariance;
    return v == null ? null : math.sqrt(v);
  }
}

/// 解析输入文本中的数字。支持逗号/中文逗号/空格/分号/换行分隔，
/// 非法片段计入 [StatsResult.invalid]。
StatsResult parseStats(String source) {
  final parts = source
      .split(RegExp(r'[,，;；\s\n\t]+'))
      .where((p) => p.isNotEmpty);
  final values = <double>[];
  var invalid = 0;
  for (final p in parts) {
    final v = double.tryParse(p);
    if (v == null || !v.isFinite) {
      invalid++;
    } else {
      values.add(v);
    }
  }
  if (values.isEmpty) {
    return StatsResult._(
      values: const [],
      invalid: invalid,
      sum: 0,
      min: 0,
      max: 0,
    );
  }
  var sum = 0.0;
  var min = values.first;
  var max = values.first;
  for (final v in values) {
    sum += v;
    if (v < min) min = v;
    if (v > max) max = v;
  }
  return StatsResult._(
    values: values,
    invalid: invalid,
    sum: sum,
    min: min,
    max: max,
  );
}
