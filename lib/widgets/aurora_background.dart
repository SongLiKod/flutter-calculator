import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/neon_theme.dart';

/// 缓慢流动的极光光斑背景。
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 26))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _blob({
    required double x,
    required double y,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * math.pi * 2;
        final w = size.width;
        final h = size.height;
        return DecoratedBox(
          decoration: BoxDecoration(color: Neon.background),
          child: Stack(
            children: [
              _blob(
                x: -w * 0.35 + math.sin(t) * w * 0.08,
                y: -h * 0.06 + math.cos(t * 1.1) * h * 0.04,
                size: w * 1.25,
                color: Neon.violet,
                opacity: 0.42,
              ),
              _blob(
                x: w * 0.42 + math.cos(t * 0.8) * w * 0.1,
                y: h * 0.28 + math.sin(t * 1.3) * h * 0.06,
                size: w * 1.1,
                color: Neon.pink,
                opacity: 0.3,
              ),
              _blob(
                x: w * 0.1 + math.sin(t * 1.5 + 1) * w * 0.12,
                y: h * 0.62 + math.cos(t) * h * 0.05,
                size: w * 1.2,
                color: Neon.teal,
                opacity: 0.24,
              ),
              // 底部压暗，保证按键文字可读
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Neon.background.withValues(alpha: 0.55),
                        Neon.background.withValues(alpha: 0.85),
                      ],
                      stops: const [0.4, 0.75, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
