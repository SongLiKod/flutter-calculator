import 'package:flutter/material.dart';

import '../calculator/engine.dart';
import '../calculator/stats.dart';
import '../theme/neon_theme.dart';

/// 统计计算底部面板。[initial] 为预填的数字文本（逗号分隔）。
void showStatsSheet(BuildContext context, {String initial = ''}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _StatsPanel(initialText: initial),
    ),
  );
}

class _StatsPanel extends StatefulWidget {
  final String initialText;
  const _StatsPanel({required this.initialText});

  @override
  State<_StatsPanel> createState() => _StatsPanelState();
}

class _StatsPanelState extends State<_StatsPanel> {
  late final TextEditingController _controller;
  bool _sample = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(double v) => formatNumber(v);

  String _fmtVar(double? v) => v == null ? '—' : formatNumber(v);

  Widget _card(String label, String value, {Color? accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x1AFFFFFF), Color(0x0AFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: accent ?? Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = parseStats(_controller.text);
    final variance = _sample ? stats.sampleVariance : stats.populationVariance;
    final stdDev = _sample ? stats.sampleStdDev : stats.populationStdDev;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xF015151F), Color(0xF70A0A12)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: const Color(0x33FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: Neon.violet.withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 46,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                Icon(Icons.analytics_rounded, color: Neon.cyan, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '统计计算',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(_controller.clear),
                  child: Text(
                    '清空',
                    style: TextStyle(color: Neon.pink, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true, decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: '输入数字，用逗号或空格分隔',
                    hintStyle: const TextStyle(color: Color(0x59FFFFFF)),
                    filled: true,
                    fillColor: const Color(0x14FFFFFF),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Neon.cyan.withValues(alpha: 0.7),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _modeChip('样本 (n−1)', _sample, () => setState(() => _sample = true)),
                    const SizedBox(width: 8),
                    _modeChip('总体 (n)', !_sample, () => setState(() => _sample = false)),
                    const Spacer(),
                    if (stats.invalid > 0)
                      Text(
                        '忽略 ${stats.invalid} 项',
                        style: TextStyle(color: Neon.amber, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (stats.count == 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Center(
                      child: Text(
                        '输入数字后自动统计',
                        style: TextStyle(color: Color(0x66FFFFFF), fontSize: 14),
                      ),
                    ),
                  )
                else ...[
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.3,
                    children: [
                      _card('个数 N', '${stats.count}'),
                      _card('总和', _fmt(stats.sum)),
                      _card('平均值', _fmt(stats.mean), accent: Neon.cyan),
                      _card('最大值', _fmt(stats.max)),
                      _card('最小值', _fmt(stats.min)),
                      _card('极差', _fmt(stats.range)),
                      _card(_sample ? '样本方差' : '总体方差', _fmtVar(variance)),
                      _card(
                        _sample ? '样本标准差' : '总体标准差',
                        _fmtVar(stdDev),
                        accent: Neon.amber,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: active ? Neon.equalsGradient : null,
          color: active ? null : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active ? Colors.white38 : const Color(0x22FFFFFF),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
