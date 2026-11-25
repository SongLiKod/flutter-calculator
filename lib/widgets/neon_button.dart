import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calculator/key_spec.dart';
import '../theme/neon_theme.dart';

class NeonButton extends StatefulWidget {
  final KeySpec spec;
  final VoidCallback onTap;
  final int index;

  const NeonButton({
    super.key,
    required this.spec,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  ({List<Color> colors, Color glow, Color border, Color textColor})
      get _palette {
    switch (widget.spec.kind) {
      case KeyKind.number:
        return (
          colors: const [Color(0x24FFFFFF), Color(0x0DFFFFFF)],
          glow: Colors.white,
          border: const Color(0x33FFFFFF),
          textColor: Colors.white,
        );
      case KeyKind.operator:
        return (
          colors: const [Color(0xFF6D4AFF), Color(0xFF9B6BFF)],
          glow: Neon.violet,
          border: const Color(0x66FFFFFF),
          textColor: Colors.white,
        );
      case KeyKind.func:
        return (
          colors: const [Color(0xFF0091A8), Color(0xFF00D5E8)],
          glow: Neon.cyan,
          border: const Color(0x55FFFFFF),
          textColor: Colors.white,
        );
      case KeyKind.constant:
        return (
          colors: const [Color(0x1F00E5FF), Color(0x0A00E5FF)],
          glow: Neon.cyan,
          border: const Color(0x2E00E5FF),
          textColor: const Color(0xFF9BF4FF),
        );
      case KeyKind.action:
        return (
          colors: const [Color(0x33FF4D94), Color(0x14FF4D94)],
          glow: Neon.pink,
          border: const Color(0x40FF4D94),
          textColor: const Color(0xFFFFA9C4),
        );
      case KeyKind.equals:
        return (
          colors: [Neon.violet, Neon.pink, Neon.amber],
          glow: Neon.pink,
          border: const Color(0x88FFFFFF),
          textColor: Colors.white,
        );
      case KeyKind.memory:
        return (
          colors: [
            Neon.violet.withValues(alpha: 0.3),
            Neon.violet.withValues(alpha: 0.1),
          ],
          glow: Neon.violet,
          border: const Color(0x55FFFFFF),
          textColor: Neon.violetSoft,
        );
    }
  }

  void _handleTapDown(TapDownDetails _) => setState(() => _pressed = true);

  void _handleTapUp(TapUpDetails _) => _release();

  void _handleTapCancel() => _release();

  void _release() {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final pressScale = widget.spec.kind == KeyKind.equals ? 0.93 : 0.90;

    // 错峰入场动画。
    final delay = (widget.index * 0.03).clamp(0.0, 0.92);

    // GestureDetector 放在入场动画（Opacity/位移）外层：动画期间按钮虽有
    // 位移与透明度变化，命中区域仍等于布局区域，点击不会落空。
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 620),
        curve: Interval(delay, 1, curve: Curves.easeOutBack),
        builder: (context, t, child) {
          final progress = t.clamp(0.0, 1.0);
          return Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, 26 * (1 - progress)),
              child: child,
            ),
          );
        },
        child: AnimatedScale(
          scale: _pressed ? pressScale : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: palette.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _pressed
                    ? palette.border.withValues(alpha: 0.95)
                    : palette.border,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.glow.withValues(alpha: _pressed ? 0.55 : 0.18),
                  blurRadius: _pressed ? 30 : 16,
                  spreadRadius: _pressed ? 1 : 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.spec.label,
                style: TextStyle(
                  color: palette.textColor,
                  fontSize: widget.spec.fontSize,
                  fontWeight: widget.spec.kind == KeyKind.number
                      ? FontWeight.w600
                      : FontWeight.w700,
                  letterSpacing: widget.spec.kind == KeyKind.number ? 0 : 0.5,
                  shadows: [
                    Shadow(
                      color: palette.glow.withValues(alpha: 0.55),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
