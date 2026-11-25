import 'package:flutter/material.dart';

import '../theme/neon_theme.dart';

class CalcDisplay extends StatelessWidget {
  final String expression;
  final String result;
  final bool isError;
  final VoidCallback onCopyExpression;
  final VoidCallback onCopyResult;

  const CalcDisplay({
    super.key,
    required this.expression,
    required this.result,
    required this.isError,
    required this.onCopyExpression,
    required this.onCopyResult,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 输入的表达式（左侧小按钮复制算式）
          Row(
            children: [
              IconButton(
                onPressed: expression.isEmpty ? null : onCopyExpression,
                tooltip: '复制算式',
                constraints:
                    const BoxConstraints.tightFor(width: 26, height: 26),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 15,
                  color: Color(0x59FFFFFF),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    expression.isEmpty ? ' ' : expression,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0x667C4DFF),
                  Colors.transparent
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 结果（带缩放脉冲动画，点按或长按复制）。
          // 手势层放在动画外层：脉冲缩放期间命中区域仍等于布局区域。
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isError ? null : onCopyResult,
            onLongPress: isError ? null : onCopyResult,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('$result|$isError'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (context, t, child) {
                final p = t.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: 0.86 + 0.14 * p,
                  child: Opacity(opacity: p, child: child),
                );
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: isError
                    ? Text(
                        result,
                        maxLines: 1,
                        style: TextStyle(
                          color: Neon.danger,
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          shadows: const [
                            Shadow(color: Color(0x88FF5C7A), blurRadius: 24),
                          ],
                        ),
                      )
                    : ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Neon.violetSoft, Neon.cyan, Neon.amber],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          result,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 58,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
