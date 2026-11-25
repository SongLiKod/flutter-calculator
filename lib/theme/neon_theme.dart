import 'package:flutter/material.dart';

/// 一套主题配色。
class NeonPreset {
  final String name;
  final Color background;

  /// 主色（原「紫」，运算符与主视觉）。
  final Color violet;

  /// 主色浅色。
  final Color violetSoft;

  /// 强调色（原「粉」，等号渐变中段）。
  final Color pink;

  /// 科技色（原「青」，函数键与常量）。
  final Color cyan;

  /// 辅助色（背景光斑）。
  final Color teal;

  /// 暖色点缀（等号渐变末段）。
  final Color amber;

  /// 错误色。
  final Color danger;

  const NeonPreset({
    required this.name,
    required this.background,
    required this.violet,
    required this.violetSoft,
    required this.pink,
    required this.cyan,
    required this.teal,
    required this.amber,
    required this.danger,
  });
}

const List<NeonPreset> neonPresets = [
  NeonPreset(
    name: '霓虹紫',
    background: Color(0xFF07070E),
    violet: Color(0xFF7C4DFF),
    violetSoft: Color(0xFFB388FF),
    pink: Color(0xFFFF4D94),
    cyan: Color(0xFF00E5FF),
    teal: Color(0xFF00B8D4),
    amber: Color(0xFFFFB74D),
    danger: Color(0xFFFF5C7A),
  ),
  NeonPreset(
    name: '赛博青',
    background: Color(0xFF04090E),
    violet: Color(0xFF00BCD4),
    violetSoft: Color(0xFF64FFDA),
    pink: Color(0xFF00E5FF),
    cyan: Color(0xFF18FFFF),
    teal: Color(0xFF00BFA5),
    amber: Color(0xFFFFEA00),
    danger: Color(0xFFFF6E40),
  ),
  NeonPreset(
    name: '熔岩橙',
    background: Color(0xFF0C0603),
    violet: Color(0xFFFF6D00),
    violetSoft: Color(0xFFFFAB40),
    pink: Color(0xFFFF3D00),
    cyan: Color(0xFFFFD740),
    teal: Color(0xFFFFAB00),
    amber: Color(0xFFFFD180),
    danger: Color(0xFFFF5252),
  ),
  NeonPreset(
    name: '樱花粉',
    background: Color(0xFF0C050B),
    violet: Color(0xFFFF6EC7),
    violetSoft: Color(0xFFFF9AD5),
    pink: Color(0xFFFF4D94),
    cyan: Color(0xFFB388FF),
    teal: Color(0xFFF48FB1),
    amber: Color(0xFFFFD180),
    danger: Color(0xFFFF5C7A),
  ),
  NeonPreset(
    name: '极光绿',
    background: Color(0xFF030A06),
    violet: Color(0xFF00E676),
    violetSoft: Color(0xFF69F0AE),
    pink: Color(0xFFFF4081),
    cyan: Color(0xFF18FFFF),
    teal: Color(0xFF00C853),
    amber: Color(0xFFFFD740),
    danger: Color(0xFFFF5252),
  ),
];

/// 当前主题下标（根部件监听它整体重建，刷新全部非 const 颜色）。
final ValueNotifier<int> themeIndex = ValueNotifier<int>(0);

/// 切换主题。[persist] 为 true 时交给调用方持久化（见 home_page）。
void selectTheme(int index) {
  if (index < 0 || index >= neonPresets.length) return;
  themeIndex.value = index;
  Neon.applyPreset(neonPresets[index]);
}

/// 霓虹主题色板。字段随 [Neon.applyPreset] 更新，因此均为非 const，
/// 由根部 [ValueListenableBuilder] 重建整棵树来生效。
class Neon {
  Neon._();

  static Color background = const Color(0xFF07070E);
  static Color violet = const Color(0xFF7C4DFF);
  static Color violetSoft = const Color(0xFFB388FF);
  static Color pink = const Color(0xFFFF4D94);
  static Color cyan = const Color(0xFF00E5FF);
  static Color teal = const Color(0xFF00B8D4);
  static Color amber = const Color(0xFFFFB74D);
  static Color danger = const Color(0xFFFF5C7A);

  static LinearGradient equalsGradient = const LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFFFF4D94), Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient operatorGradient = const LinearGradient(
    colors: [Color(0xFF6D4AFF), Color(0xFF9B6BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient functionGradient = const LinearGradient(
    colors: [Color(0xFF0091A8), Color(0xFF00D5E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassGradient = const LinearGradient(
    colors: [Color(0x1FFFFFFF), Color(0x0AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient dangerGradient = const LinearGradient(
    colors: [Color(0x40FF4D94), Color(0x1FFF4D94)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient screenGradient = const LinearGradient(
    colors: [Color(0x14FFFFFF), Color(0x06FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 应用配色（幂等，可在根部重建时调用）。
  static void applyPreset(NeonPreset p) {
    background = p.background;
    violet = p.violet;
    violetSoft = p.violetSoft;
    pink = p.pink;
    cyan = p.cyan;
    teal = p.teal;
    amber = p.amber;
    danger = p.danger;
    equalsGradient = LinearGradient(
      colors: [p.violet, p.pink, p.amber],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    operatorGradient = LinearGradient(
      colors: [p.violet, p.violetSoft],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    functionGradient = LinearGradient(
      colors: [p.teal, p.cyan],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    dangerGradient = LinearGradient(
      colors: [p.danger.withValues(alpha: 0.25), p.danger.withValues(alpha: 0.12)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
