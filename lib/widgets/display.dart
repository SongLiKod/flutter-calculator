import 'package:flutter/material.dart';

import '../calculator/engine.dart';
import '../theme/neon_theme.dart';
import 'history_sheet.dart';

class CalcDisplay extends StatelessWidget {
  /// 本次会话已完成的等式（按完成顺序，新完成的在底部）。
  final List<HistoryEntry> tape;

  /// 纸带中最近点取的等式，用于高亮提示。
  final HistoryEntry? picked;

  final String expression;
  final String result;
  final bool isError;
  final VoidCallback onCopyExpression;
  final VoidCallback onCopyResult;

  /// 点击纸带中的等式：把该等式的结果放入计算区。
  final ValueChanged<HistoryEntry> onPickTape;

  const CalcDisplay({
    super.key,
    required this.tape,
    required this.picked,
    required this.expression,
    required this.result,
    required this.isError,
    required this.onCopyExpression,
    required this.onCopyResult,
    required this.onPickTape,
  });

  /// 纸带行高与最多同时可见的行数。
  static const double _tapeRowHeight = 24;
  static const int _tapeMaxRows = 4;

  /// 每行右侧的会话累计小计（按纸带顺序逐行累加）。
  List<String> _runningTotals() {
    final totals = <String>[];
    var run = 0.0;
    for (final entry in tape) {
      final next = run + (double.tryParse(entry.result) ?? 0.0);
      // 极端情况下累加可能溢出为无穷，此时保留上一次的累计值。
      if (next.isFinite) run = next;
      totals.add(run.isFinite ? formatNumber(run) : '—');
    }
    return totals;
  }

  Widget _tapeRow(HistoryEntry entry, String total) {
    final isSelected = identical(entry, picked);
    return SizedBox(
      height: _tapeRowHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPickTape(entry),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? Neon.violet.withValues(alpha: 0.25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    groupExpression(entry.expression),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Text(
                  ' = ',
                  style: TextStyle(color: Color(0x59FFFFFF), fontSize: 13),
                ),
                Flexible(
                  child: Text(
                    groupExpression(entry.result),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 76,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Σ $total',
                      maxLines: 1,
                      style: TextStyle(
                        color: Neon.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 纸带：`reverse` 让新完成的等式始终贴在底部（紧邻算式行），
  /// 内容超出时向上滚动查看更早的记录。
  Widget _buildTape(List<String> totals) {
    final rows = <Widget>[];
    for (var i = tape.length - 1; i >= 0; i--) {
      rows.add(_tapeRow(tape[i], totals[i]));
    }
    final visible =
        tape.length < _tapeMaxRows ? tape.length : _tapeMaxRows;
    return Flexible(
      child: SizedBox(
        height: visible.toDouble() * _tapeRowHeight,
        child: ListView(
          primary: false,
          reverse: true,
          padding: EdgeInsets.zero,
          children: rows,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _runningTotals();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (tape.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                '每次按 = 的结果会保留在这里，点击等式可取用结果',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0x4DFFFFFF),
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            _buildTape(totals),
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
