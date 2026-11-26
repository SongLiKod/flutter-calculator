import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/neon_theme.dart';
import 'display.dart';
import 'history_sheet.dart';

/// 全屏查看：超大结果 + 算式 + 完整纸带（不限 4 行，可滚动）。
///
/// - 退出：右上角关闭按钮 / 系统返回键 / Esc（真全屏没有「外部」可点）。
/// - 点击纸带行：把该结果取入计算区并自动关闭。
/// - 复制算式/结果为行内图标（点按大结果复制数值、长按复制人民币大写），
///   反馈显示在顶部提示条。
Future<void> showFullscreenDisplay(
  BuildContext context, {
  required List<HistoryEntry> tape,
  required HistoryEntry? picked,
  required String expression,
  required String result,
  required bool isError,
  required VoidCallback onCopyExpression,
  required VoidCallback onCopyResult,
  required VoidCallback onCopyResultUpper,
  required ValueChanged<HistoryEntry> onPickTape,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _FullscreenDisplay(
      tape: tape,
      picked: picked,
      expression: expression,
      result: result,
      isError: isError,
      onCopyExpression: onCopyExpression,
      onCopyResult: onCopyResult,
      onCopyResultUpper: onCopyResultUpper,
      onPickTape: onPickTape,
    ),
  );
}

class _FullscreenDisplay extends StatefulWidget {
  final List<HistoryEntry> tape;
  final HistoryEntry? picked;
  final String expression;
  final String result;
  final bool isError;
  final VoidCallback onCopyExpression;
  final VoidCallback onCopyResult;
  final VoidCallback onCopyResultUpper;
  final ValueChanged<HistoryEntry> onPickTape;

  const _FullscreenDisplay({
    required this.tape,
    required this.picked,
    required this.expression,
    required this.result,
    required this.isError,
    required this.onCopyExpression,
    required this.onCopyResult,
    required this.onCopyResultUpper,
    required this.onPickTape,
  });

  @override
  State<_FullscreenDisplay> createState() => _FullscreenDisplayState();
}

class _FullscreenDisplayState extends State<_FullscreenDisplay> {
  Timer? _tipTimer;
  String? _tip;

  /// 关闭幂等标记：退场动画期间的重复点击不会连累下层路由。
  bool _closed = false;

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.pop(context);
  }

  void _flash(String tip) {
    _tipTimer?.cancel();
    setState(() => _tip = tip);
    _tipTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _tip = null);
    });
  }

  void _copyExpression() {
    widget.onCopyExpression();
    _flash('已复制算式');
  }

  void _copyResult() {
    widget.onCopyResult();
    _flash('已复制结果');
  }

  void _copyResultUpper() {
    widget.onCopyResultUpper();
    _flash('已复制大写');
  }

  /// 点纸带行：取用结果并关闭全屏。
  void _pick(HistoryEntry entry) {
    if (_closed) return;
    _close();
    widget.onPickTape(entry);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _copyButton({
    required Key key,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      key: key,
      onPressed: enabled ? onPressed : null,
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.copy_rounded,
        size: 17,
        color: enabled ? const Color(0x8AFFFFFF) : const Color(0x33FFFFFF),
      ),
    );
  }

  /// 超大结果：点按复制数值，长按复制人民币大写。
  Widget _bigResult() {
    final text = Text(
      widget.result,
      key: const ValueKey('fullscreen-result'),
      maxLines: 1,
      style: widget.isError
          ? TextStyle(
              color: Neon.danger,
              fontSize: 64,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              shadows: const [
                Shadow(color: Color(0x88FF5C7A), blurRadius: 24),
              ],
            )
          : const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.isError ? null : _copyResult,
      onLongPress: widget.isError ? null : _copyResultUpper,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: widget.isError
            ? text
            : ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Neon.violetSoft, Neon.cyan, Neon.amber],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: text,
              ),
      ),
    );
  }

  /// 纸带列表：新完成的等式在底部（与主显示区一致），
  /// 内容超出时初始定位在底部，向上滚动查看更早的记录。
  Widget _tapeList(List<String> totals) {
    return Expanded(
      child: Align(
        alignment: Alignment.topCenter,
        child: ListView.builder(
          reverse: true,
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          itemCount: widget.tape.length,
          itemBuilder: (context, i) {
            final index = widget.tape.length - 1 - i;
            final entry = widget.tape[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TapeRow(
                entry: entry,
                total: totals[index],
                selected: identical(entry, widget.picked),
                onTap: () => _pick(entry),
                onLongPressStart: (pos) => showTapeTotalMenu(
                  context,
                  entry: entry,
                  tape: widget.tape,
                  position: pos,
                  showTip: _flash,
                ),
                height: 36,
                fontSize: 15,
                totalWidth: 92,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = runningTotals(widget.tape);
    return Dialog.fullscreen(
      backgroundColor: Neon.background,
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶栏：关闭 + 标题
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _close,
                      tooltip: '关闭',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xCCFFFFFF),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        '全屏查看',
                        style: TextStyle(
                          color: Color(0xE6FFFFFF),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 复制反馈提示条（无提示时占位，保持布局稳定）
              SizedBox(
                height: 22,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: _tip == null
                        ? const SizedBox.shrink()
                        : Text(
                            _tip!,
                            key: ValueKey(_tip!),
                            style: TextStyle(
                              color: Neon.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),
              // 算式（左侧图标复制）
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Row(
                  children: [
                    _copyButton(
                      key: const ValueKey('fullscreen-copy-expr'),
                      tooltip: '复制算式',
                      enabled: widget.expression.isNotEmpty,
                      onPressed: _copyExpression,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.expression.isEmpty ? ' ' : widget.expression,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // 超大结果（左侧图标或点按复制）
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Row(
                  children: [
                    _copyButton(
                      key: const ValueKey('fullscreen-copy-result'),
                      tooltip: '复制结果',
                      enabled: !widget.isError,
                      onPressed: _copyResult,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _bigResult()),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 24),
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
              // 纸带标题：本次会话的笔数
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
                child: Row(
                  children: [
                    const Text(
                      '计算纸带',
                      style: TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.tape.length} 笔',
                      style: TextStyle(
                        color: Neon.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.tape.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      '每次按 = 的等式会记录在这里，点行可取用结果',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0x4DFFFFFF),
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                )
              else
                _tapeList(totals),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
