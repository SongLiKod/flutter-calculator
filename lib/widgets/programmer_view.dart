import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calculator/key_spec.dart';
import '../calculator/programmer.dart';
import '../theme/neon_theme.dart';
import 'neon_button.dart';
import 'neon_chip.dart';

/// 程序员模式：四进制读数 + 位宽/进制选择 + 位运算键盘。
class ProgrammerView extends StatelessWidget {
  final ProgrammerCalc calc;
  final String? error;
  final ValueChanged<String> onKey;

  const ProgrammerView({
    super.key,
    required this.calc,
    required this.error,
    required this.onKey,
  });

  static const List<ProgBase> _readoutOrder = [
    ProgBase.hex,
    ProgBase.bin,
    ProgBase.oct,
    ProgBase.dec,
  ];

  void _tap(String id) {
    HapticFeedback.selectionClick();
    onKey(id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 34, child: _buildReadout()),
        _buildSelectors(),
        Expanded(flex: 66, child: _buildPad()),
      ],
    );
  }

  Widget _buildReadout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 挂起运算 / 错误提示
          SizedBox(
            height: 22,
            child: error != null
                ? Text(
                    error!,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Neon.danger,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : calc.pendingOp != null
                    ? Text(
                        '${calc.format(as: calc.base)} ${calc.pendingOp!.symbol}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0x80FFFFFF),
                          fontSize: 17,
                          letterSpacing: 1.2,
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          for (final base in _readoutOrder) _readoutRow(base),
        ],
      ),
    );
  }

  Widget _readoutRow(ProgBase base) {
    final active = base == calc.base;
    final value = calc.format(as: base, group: base != ProgBase.dec);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              base.label,
              style: TextStyle(
                color: active ? Neon.cyan : const Color(0x59FFFFFF),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xB3FFFFFF),
                  fontSize: active ? 30 : 19,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectors() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final base in ProgBase.values) ...[
              NeonChip(
                label: base.label,
                compact: true,
                active: base == calc.base,
                onTap: () => _tap('base-${base.name}'),
              ),
              const SizedBox(width: 6),
            ],
            const SizedBox(width: 6),
            Container(width: 1, height: 18, color: const Color(0x33FFFFFF)),
            const SizedBox(width: 6),
            for (final w in BitWidth.values) ...[
              NeonChip(
                label: '${w.bits}位',
                compact: true,
                active: w == calc.width,
                onTap: () => _tap('w${w.bits}'),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPad() {
    var index = 0;
    return Column(
      children: [
        for (final row in programRows)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  for (final spec in row)
                    Expanded(
                      child: NeonButton(
                        key: ValueKey(spec.id),
                        spec: spec,
                        index: index++,
                        onTap: () => onKey(spec.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
