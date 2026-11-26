import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calculator/engine.dart';
import '../theme/neon_theme.dart';
import 'history_sheet.dart';

/// 纸带累计和的原始数值序列（与显示的Σ是同一次累加，复制用）。
List<double> rawRunningTotals(List<HistoryEntry> tape) {
  final values = <double>[];
  var run = 0.0;
  for (final entry in tape) {
    final next = run + (double.tryParse(entry.result) ?? 0.0);
    // 极端情况下累加可能溢出为无穷，此时保留上一次的累计值。
    if (next.isFinite) run = next;
    values.add(run);
  }
  return values;
}

/// 纸带每行右侧的会话累计小计（按纸带顺序逐行累加，带千分位）。
/// 主显示区与全屏查看共用。
List<String> runningTotals(List<HistoryEntry> tape) =>
    rawRunningTotals(tape).map(formatNumber).toList();

/// 第 [index] 行的累计和（复制用，无千分位，与「复制结果」惯例一致）。
String runningTotalValue(List<HistoryEntry> tape, int index) =>
    formatNumber(rawRunningTotals(tape)[index], grouped: false);

/// 第 [index] 行累计和的完整等式（算式链，复制用）：
/// `7×8 + 123×456 + 5÷2 = 56146.5`；单笔时为 `7×8 = 56`。
/// 每段取原始表达式（无千分位）；行首是一元负号时补括号，保证外部可解析。
String runningTotalEquation(List<HistoryEntry> tape, int index) {
  final terms = <String>[];
  for (var i = 0; i <= index && i < tape.length; i++) {
    final expr = tape[i].expression;
    final startsNegative = expr.startsWith('−') || expr.startsWith('-');
    terms.add(startsNegative ? '($expr)' : expr);
  }
  return '${terms.join(' + ')} = ${runningTotalValue(tape, index)}';
}

/// 第 [index] 行累计和的结果链（复制用）：只含每行结果相加，无算式细节。
/// `56 + 56088 + 2.5 = 56146.5`；负数转为减号（`56 - 6 + 3 = 53`）。
/// 运算符与数值均为 ASCII，粘贴到表格软件可直接计算。
String runningTotalResultChain(List<HistoryEntry> tape, int index) {
  final parts = <String>[];
  for (var i = 0; i <= index && i < tape.length; i++) {
    var raw = tape[i].result;
    var negative = false;
    if (raw.startsWith('-') || raw.startsWith('−')) {
      negative = true;
      raw = raw.substring(1);
    }
    if (i == 0) {
      parts.add(negative ? '-$raw' : raw);
    } else {
      parts.add(negative ? ' - $raw' : ' + $raw');
    }
  }
  return '${parts.join()} = ${runningTotalValue(tape, index)}';
}

/// 长按纸带行：弹出「复制和 / 复制和（大写）/ 结果链 / 算式链」菜单并执行复制。
/// [showTip] 是复制后的反馈（主显示区走 SnackBar，全屏为行内提示条）。
Future<void> showTapeTotalMenu(
  BuildContext context, {
  required HistoryEntry entry,
  required List<HistoryEntry> tape,
  required Offset position,
  required void Function(String tip) showTip,
}) async {
  final index = tape.indexWhere((e) => identical(e, entry));
  if (index < 0) return;
  HapticFeedback.selectionClick();
  final size = MediaQuery.sizeOf(context);
  final action = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      size.width - position.dx,
      size.height - position.dy,
    ),
    items: const [
      PopupMenuItem(value: 'value', child: Text('复制和')),
      PopupMenuItem(value: 'upper', child: Text('复制和（大写）')),
      PopupMenuItem(value: 'chain', child: Text('复制和的结果链')),
      PopupMenuItem(value: 'equation', child: Text('复制和的算式链')),
    ],
  );
  if (action == null) return;
  final String text;
  final String tip;
  if (action == 'value') {
    text = runningTotalValue(tape, index);
    tip = '已复制和';
  } else if (action == 'upper') {
    text = toChineseUpper(runningTotalValue(tape, index));
    tip = '已复制和（大写）';
  } else if (action == 'chain') {
    text = runningTotalResultChain(tape, index);
    tip = '已复制和的结果链';
  } else {
    text = runningTotalEquation(tape, index);
    tip = '已复制和的算式链';
  }
  Clipboard.setData(ClipboardData(text: text));
  showTip(tip);
}

/// 纸带单行：`等式 = 结果  Σ累计小计`，点击把结果取入计算区。
/// 主显示区与全屏查看共用，尺寸由 [height] / [fontSize] 调节。
class TapeRow extends StatelessWidget {
  final HistoryEntry entry;
  final String total;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final double fontSize;
  final double totalWidth;

  /// 长按行（返回触点的全局位置）：弹出复制和菜单；为 null 时不可长按。
  final void Function(Offset position)? onLongPressStart;

  const TapeRow({
    super.key,
    required this.entry,
    required this.total,
    required this.selected,
    required this.onTap,
    this.onLongPressStart,
    this.height = 24,
    this.fontSize = 13,
    this.totalWidth = 76,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      // 长按弹复制菜单；InkWell 只处理点按（取用结果），两种手势互不抢占。
      child: GestureDetector(
        onLongPressStart: onLongPressStart == null
            ? null
            : (details) => onLongPressStart!(details.globalPosition),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: selected
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
                      style: TextStyle(
                        color: const Color(0x99FFFFFF),
                        fontSize: fontSize,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    ' = ',
                    style: TextStyle(
                      color: const Color(0x59FFFFFF),
                      fontSize: fontSize,
                    ),
                  ),
                  // 结果列：固定列宽 + 右对齐，保证各行的值与 Σ 列上下对齐
                  //（若用 Flexible，文本只占实际宽度，会把 Σ 列顶得参差不齐）。
                  Expanded(
                    child: Text(
                      groupExpression(entry.result),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: const Color(0xE6FFFFFF),
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: totalWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Σ $total',
                        maxLines: 1,
                        style: TextStyle(
                          color: Neon.amber,
                          fontSize: fontSize - 1,
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
      ),
    );
  }
}

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

  /// 长按结果：复制人民币大写（点按仍复制数值）；null 时长按无效。
  final VoidCallback? onCopyResultUpper;

  /// 点击纸带中的等式：把该等式的结果放入计算区。
  final ValueChanged<HistoryEntry> onPickTape;

  /// 长按纸带行：弹出复制和 / 大写 / 结果链 / 算式链菜单。
  final void Function(HistoryEntry entry, Offset position)? onCopyMenu;

  /// 点击结果旁的展开图标：全屏查看结果、算式与完整纸带。
  final VoidCallback onOpenFullscreen;

  const CalcDisplay({
    super.key,
    required this.tape,
    required this.picked,
    required this.expression,
    required this.result,
    required this.isError,
    required this.onCopyExpression,
    required this.onCopyResult,
    this.onCopyResultUpper,
    required this.onPickTape,
    this.onCopyMenu,
    required this.onOpenFullscreen,
  });

  /// 纸带行高与最多同时可见的行数。
  static const double _tapeRowHeight = 24;
  static const int _tapeMaxRows = 4;

  /// 纸带：`reverse` 让新完成的等式始终贴在底部（紧邻算式行），
  /// 内容超出时向上滚动查看更早的记录。
  Widget _buildTape(List<String> totals) {
    final rows = <Widget>[];
    for (var i = tape.length - 1; i >= 0; i--) {
      rows.add(TapeRow(
        entry: tape[i],
        total: totals[i],
        selected: identical(tape[i], picked),
        onTap: () => onPickTape(tape[i]),
        onLongPressStart: onCopyMenu == null
            ? null
            : (pos) => onCopyMenu!(tape[i], pos),
      ));
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
    final totals = runningTotals(tape);
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
          // 结果（点按复制数值、长按复制人民币大写；左侧图标进入全屏查看）。
          // 手势层放在动画外层：脉冲缩放期间命中区域仍等于布局区域。
          Row(
            children: [
              IconButton(
                onPressed: onOpenFullscreen,
                tooltip: '全屏查看',
                constraints:
                    const BoxConstraints.tightFor(width: 30, height: 30),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.fullscreen_rounded,
                  size: 20,
                  color: Color(0x99FFFFFF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isError ? null : onCopyResult,
                  onLongPress: isError || onCopyResultUpper == null
                      ? null
                      : onCopyResultUpper,
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
                                  Shadow(
                                      color: Color(0x88FF5C7A), blurRadius: 24),
                                ],
                              ),
                            )
                          : ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Neon.violetSoft,
                                  Neon.cyan,
                                  Neon.amber
                                ],
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
                                  fontFeatures: [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
