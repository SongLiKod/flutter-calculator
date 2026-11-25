import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calculator/engine.dart';
import '../calculator/units.dart';
import '../theme/neon_theme.dart';
import 'neon_chip.dart';

/// 单位换算面板（长度/重量/温度/面积/速度/时间/数据）。
class UnitConverterView extends StatefulWidget {
  const UnitConverterView({super.key});

  @override
  State<UnitConverterView> createState() => _UnitConverterViewState();
}

class _UnitConverterViewState extends State<UnitConverterView> {
  int _categoryIndex = 0;
  late String _from;
  late String _to;
  final TextEditingController _input = TextEditingController(text: '1');

  ConvertCategory get _category => convertCategories[_categoryIndex];

  @override
  void initState() {
    super.initState();
    _resetUnits();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _resetUnits() {
    _from = _category.units[0].symbol;
    _to = _category.units[1].symbol;
  }

  void _selectCategory(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _categoryIndex = index;
      _resetUnits();
    });
  }

  void _swap() {
    HapticFeedback.selectionClick();
    setState(() {
      final t = _from;
      _from = _to;
      _to = t;
    });
  }

  double? get _value => double.tryParse(_input.text.trim());

  String get _result {
    final v = _value;
    if (v == null) return '—';
    try {
      return formatNumber(convertValue(_category, _from, _to, v));
    } catch (_) {
      return '—';
    }
  }

  void _copyResult() {
    final text = _result;
    if (text == '—') return;
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            '已复制换算结果',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          backgroundColor: Neon.violet,
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  DropdownButton<String> _dropdown(String value, {required bool source}) {
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF15151F),
      icon: Icon(Icons.arrow_drop_down_rounded, color: Neon.cyan, size: 26),
      style: const TextStyle(color: Colors.white, fontSize: 14.5),
      underline: const SizedBox.shrink(),
      items: [
        for (final unit in _category.units)
          DropdownMenuItem(
            value: unit.symbol,
            child: Text(
              '${unit.name} (${unit.symbol})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) {
        if (v == null) return;
        HapticFeedback.selectionClick();
        setState(() {
          if (source) {
            _from = v;
          } else {
            _to = v;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 类别选择
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              for (var i = 0; i < convertCategories.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                NeonChip(
                  label: convertCategories[i].name,
                  compact: true,
                  active: i == _categoryIndex,
                  onTap: () => _selectCategory(i),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x1FFFFFFF), Color(0x0AFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0x2EFFFFFF)),
                boxShadow: [
                  BoxShadow(
                    color: Neon.violet.withValues(alpha: 0.18),
                    blurRadius: 26,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.swap_horiz_rounded, color: Neon.cyan, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '单位换算',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 输入
                    TextField(
                      controller: _input,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        labelText: '输入数值',
                        labelStyle: const TextStyle(
                            color: Color(0x80FFFFFF), fontSize: 14),
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
                    const SizedBox(height: 14),
                    // 源 / 目标单位
                    Row(
                      children: [
                        Expanded(child: _dropdown(_from, source: true)),
                        IconButton(
                          onPressed: _swap,
                          tooltip: '交换单位',
                          icon: Icon(Icons.swap_horiz_rounded,
                              color: Neon.pink, size: 26),
                        ),
                        Expanded(child: _dropdown(_to, source: false)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: const Color(0x1AFFFFFF)),
                    const SizedBox(height: 14),
                    // 结果
                    GestureDetector(
                      onTap: _copyResult,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${_category.name} · $_from → $_to',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0x80FFFFFF),
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Neon.violetSoft, Neon.cyan, Neon.amber],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds),
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                _result,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 46,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '点按结果可复制',
                            textAlign: TextAlign.right,
                            style: TextStyle(color: Color(0x4DFFFFFF), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
