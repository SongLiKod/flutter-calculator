import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculator/engine.dart';
import 'calculator/key_spec.dart';
import 'calculator/programmer.dart';
import 'calculator/store.dart';
import 'theme/neon_theme.dart';
import 'widgets/aurora_background.dart';
import 'widgets/display.dart';
import 'widgets/history_sheet.dart';
import 'widgets/neon_button.dart';
import 'widgets/neon_chip.dart';
import 'widgets/programmer_view.dart';
import 'widgets/stats_sheet.dart';
import 'widgets/theme_sheet.dart';
import 'widgets/unit_converter.dart';

enum AppMode { calc, prog, convert }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 尾部数字（可含科学计数法指数），例如 `6.02e+23`
  static final RegExp _trailingNumber =
      RegExp(r'(\d+\.?\d*(?:[eE][+\-−]?\d+)?|\.\d+)$');

  /// 被 `±` 包裹为负数的尾部数字
  static final RegExp _wrappedNegative =
      RegExp(r'\([−-](\d+\.?\d*(?:[eE][+\-−]?\d+)?|\.\d+)\)$');

  /// 尾部整体函数（退格时删除）
  static final RegExp _trailingFuncOpen = RegExp(
      r'(asinh|acosh|atanh|sinh|cosh|tanh|asin|acos|atan|sin|cos|tan|ln|log|abs|√|∛)\($');

  /// 指数尾部：`6.02e` / `6.02e+` / `6.02e-`（数字直接追加）
  static final RegExp _expTail = RegExp(r'[\d.][eE][+\-−]?$');

  /// 指数内部（禁止小数点与正负切换）
  static final RegExp _insideExponent = RegExp(r'[eE][+\-−]?\d*$');

  static final RegExp _numberInExpr = RegExp(r'\d+\.?\d*|\.\d+');

  /// 内部表达式（无千分位，可直接求值）
  String _expr = '';

  /// 展示结果
  String _result = '0';
  bool _isError = false;

  /// 等号计算失败后的状态，任何新输入都从头开始
  bool _errorState = false;

  /// 等号之后：数字开启新算式，运算符接续结果
  bool _justEvaluated = false;

  /// 等号按下时的原始表达式，用于在结果上方继续展示
  String _evaluatedSource = '';

  /// 最近一次成功计算的结果（供 Ans 使用）
  String _lastAnswer = '';

  bool _science = false;
  bool _degrees = true;
  int _sciPage = 0;

  AppMode _mode = AppMode.calc;

  double? _memory;

  final ProgrammerCalc _prog = ProgrammerCalc();
  String? _progError;

  final List<HistoryEntry> _history = [];

  /// 本次会话的计算纸带：每次按 `=` 追加一条，按 C 清空时结束本次计算。
  final List<HistoryEntry> _tape = [];

  /// 纸带中最近点取的等式（高亮提示，直到清空）。
  HistoryEntry? _tapePicked;

  final Random _random = Random();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final history = await AppStore.loadHistory();
    final memory = await AppStore.loadMemory();
    if (!mounted) return;
    setState(() {
      if (history.isNotEmpty) _history.insertAll(0, history);
      _memory = memory;
    });
  }

  // ---------------------------------------------------------------- 输入规则

  bool _endsWithValue(String s) =>
      s.isNotEmpty && RegExp(r'[0-9)%!πe]$').hasMatch(s);

  bool _endsWithOperator(String s) =>
      s.isNotEmpty && '+−×÷^'.contains(s[s.length - 1]);

  bool _endsWithOpen(String s) => s.endsWith('(');

  void _resetIfError() {
    if (!_errorState) return;
    _errorState = false;
    _isError = false;
    _expr = '';
    _result = '0';
    _justEvaluated = false;
  }

  void _inputDigit(String digit) {
    _resetIfError();
    if (_justEvaluated) {
      _expr = '';
      _justEvaluated = false;
    }
    if (digit == '.') {
      if (_expr.isEmpty) {
        _expr = '0.';
        return;
      }
      final number = _trailingNumber.firstMatch(_expr);
      if (number != null) {
        if (number.group(1)!.contains('.')) return;
        if (_insideExponent.hasMatch(_expr)) return; // 指数里不加小数点
        _expr = '$_expr.';
        return;
      }
      if (_endsWithValue(_expr)) return;
      _expr = '${_expr}0.';
      return;
    }
    if (_expr.isEmpty) {
      _expr = digit;
      return;
    }
    // EXP 悬空指数：数字直接追加（6.02e → 6.02e5）
    if (_expTail.hasMatch(_expr)) {
      _expr = '$_expr$digit';
      return;
    }
    if (_endsWithValue(_expr)) {
      final last = _expr[_expr.length - 1];
      final endsSymbol =
          last == ')' || last == '%' || last == '!' || last == 'π' || last == 'e';
      _expr = endsSymbol ? '$_expr×$digit' : '$_expr$digit';
      return;
    }
    _expr = '$_expr$digit';
  }

  void _inputOperator(String op) {
    _resetIfError();
    if (_justEvaluated) _justEvaluated = false;
    if (_expr.isEmpty) {
      if (op == '−') _expr = '−';
      return;
    }
    if (_endsWithValue(_expr)) {
      _expr = '$_expr$op';
      return;
    }
    if (_endsWithOperator(_expr)) {
      _expr = '${_expr.substring(0, _expr.length - 1)}$op';
      return;
    }
    if (_endsWithOpen(_expr) && op == '−') {
      _expr = '$_expr$op';
    }
  }

  void _inputFunc(String name) {
    _resetIfError();
    if (_justEvaluated) {
      _expr = '';
      _justEvaluated = false;
    }
    final prefix = _endsWithValue(_expr) ? '×' : '';
    _expr = '$_expr$prefix$name(';
  }

  void _inputConstant(String symbol) {
    _resetIfError();
    if (_justEvaluated) {
      _expr = '';
      _justEvaluated = false;
    }
    final prefix = _endsWithValue(_expr) ? '×' : '';
    _expr = '$_expr$prefix$symbol';
  }

  void _inputOpenParen() {
    _resetIfError();
    if (_justEvaluated) {
      _expr = '';
      _justEvaluated = false;
    }
    if (_expr.isEmpty) {
      _expr = '(';
      return;
    }
    if (_endsWithValue(_expr)) {
      _expr = '$_expr×(';
      return;
    }
    if (_endsWithOperator(_expr) || _endsWithOpen(_expr)) {
      _expr = '$_expr(';
    }
  }

  void _inputCloseParen() {
    if (_errorState || _justEvaluated || _expr.isEmpty) return;
    if (_endsWithOperator(_expr) || _endsWithOpen(_expr)) return;
    final opens = _expr.split('(').length - 1;
    final closes = _expr.split(')').length - 1;
    if (opens > closes) _expr = '$_expr)';
  }

  void _inputPercent() {
    _resetIfError();
    if (_justEvaluated) _justEvaluated = false;
    if (!_endsWithValue(_expr) || _expr.endsWith('%')) return;
    _expr = '$_expr%';
  }

  void _inputFactorial() {
    _resetIfError();
    if (_justEvaluated) _justEvaluated = false;
    if (!_endsWithValue(_expr) || _expr.endsWith('!')) return;
    _expr = '$_expr!';
  }

  /// x² / x³：直接追加幂运算。
  void _inputPower(int degree) {
    _resetIfError();
    if (!_endsWithValue(_expr)) return;
    _justEvaluated = false;
    _expr = '$_expr^$degree';
  }

  /// 10ˣ / eˣ：追加底数与幂运算符。
  void _inputPowBase(String base) {
    _resetIfError();
    if (_justEvaluated) {
      _expr = '';
      _justEvaluated = false;
    }
    final prefix = _endsWithValue(_expr) ? '×' : '';
    _expr = '$_expr$prefix$base^';
  }

  /// EXP：给尾部数字追加科学计数法指数标记。
  void _inputExp() {
    _resetIfError();
    if (_justEvaluated) _justEvaluated = false;
    if (!RegExp(r'\d$').hasMatch(_expr)) return;
    final number = _trailingNumber.firstMatch(_expr);
    if (number == null) return;
    final before = _expr.substring(0, number.start);
    if (before.endsWith('e') || before.endsWith('E')) return; // 已有指数
    _expr = '${_expr}e';
  }

  /// RAN#：插入 [0,1) 的随机小数。
  void _inputRandom() {
    _resetIfError();
    if (_justEvaluated) {
      _expr = '';
      _justEvaluated = false;
    }
    final digits =
        (_random.nextDouble() * 1000000).floor().toString().padLeft(6, '0');
    final prefix = _endsWithValue(_expr) ? '×' : '';
    _expr = '$_expr${prefix}0.$digits';
  }

  /// Ans：插入最近一次计算结果。
  void _inputAns() {
    if (_lastAnswer.isEmpty) return;
    _resetIfError();
    if (_justEvaluated) {
      _expr = '';
      _justEvaluated = false;
    }
    final text = _lastAnswer.startsWith('-')
        ? '(−${_lastAnswer.substring(1)})'
        : _lastAnswer;
    final prefix = _endsWithValue(_expr) ? '×' : '';
    _expr = '$_expr$prefix$text';
  }

  /// |x|：包裹整个表达式为 abs(...)；1/x：包裹为 1÷(...)。
  void _inputWrap(String kind) {
    _resetIfError();
    if (!_endsWithValue(_expr)) return;
    _justEvaluated = false;
    _expr = kind == 'inv' ? '1÷($_expr)' : 'abs($_expr)';
  }

  void _toggleSign() {
    _resetIfError();
    if (_justEvaluated) _justEvaluated = false;
    final wrapped = _wrappedNegative.firstMatch(_expr);
    if (wrapped != null) {
      _expr = _expr.substring(0, wrapped.start) + wrapped.group(1)!;
      return;
    }
    final number = _trailingNumber.firstMatch(_expr);
    if (number == null) {
      if (_expr.isEmpty || _endsWithOperator(_expr) || _endsWithOpen(_expr)) {
        _expr = '$_expr−';
      }
      return;
    }
    _expr = '${_expr.substring(0, number.start)}(−${number.group(1)})';
  }

  void _backspace() {
    if (_errorState) {
      _errorState = false;
      _isError = false;
    }
    if (_justEvaluated) _justEvaluated = false;
    if (_expr.isEmpty) return;
    final wrapped = _wrappedNegative.firstMatch(_expr);
    if (wrapped != null && wrapped.end == _expr.length) {
      _expr = _expr.substring(0, wrapped.start);
      return;
    }
    final func = _trailingFuncOpen.firstMatch(_expr);
    if (func != null) {
      _expr = _expr.substring(0, func.start);
      return;
    }
    _expr = _expr.substring(0, _expr.length - 1);
  }

  /// 重置显示与输入状态（不动纸带）。
  void _resetScreen() {
    _expr = '';
    _result = '0';
    _isError = false;
    _errorState = false;
    _justEvaluated = false;
    _evaluatedSource = '';
  }

  /// 结束本次计算：屏幕归零并清空纸带。
  void _clear() {
    _resetScreen();
    _tape.clear();
    _tapePicked = null;
  }

  /// 点击纸带中的等式：把该等式的结果放入计算区。
  /// 计算区为空或刚按过 `=` 时作为新起点；末尾是运算符或左括号时直接接上；
  /// 末尾是数字时自动补 `+`，方便连续累加。
  void _pickTape(HistoryEntry entry) {
    HapticFeedback.selectionClick();
    setState(() {
      _resetIfError();
      final value = entry.result.startsWith('-')
          ? '(−${entry.result.substring(1)})'
          : entry.result;
      _tapePicked = entry;
      if (_expr.isEmpty || _justEvaluated) {
        _expr = value;
        _evaluatedSource = entry.expression;
        _justEvaluated = true;
      } else if (_endsWithOperator(_expr) || _endsWithOpen(_expr)) {
        _expr = '$_expr$value';
        _evaluatedSource = '';
        _justEvaluated = false;
      } else if (_endsWithValue(_expr)) {
        _expr = '$_expr+$value';
        _evaluatedSource = '';
        _justEvaluated = false;
      }
      _syncPreview();
    });
  }

  // ------------------------------------------------------------------ 记忆

  double? _currentValueOrNull() {
    if (_expr.isEmpty) return null;
    try {
      return evaluate(_expr, degrees: _degrees);
    } catch (_) {
      return null;
    }
  }

  void _memoryDelta(int sign) {
    final v = _currentValueOrNull();
    if (v == null) return;
    setState(() {
      _memory = (_memory ?? 0) + sign * v;
      AppStore.saveMemory(_memory);
    });
  }

  void _memoryRecall() {
    if (_memory == null) return;
    setState(() {
      final raw = formatNumber(_memory!, grouped: false);
      final text = raw.startsWith('-') ? '(−${raw.substring(1)})' : raw;
      _inputConstant(text);
      _syncPreview();
    });
  }

  void _memoryClear() {
    if (_memory == null) return;
    setState(() {
      _memory = null;
      AppStore.saveMemory(null);
    });
  }

  // ------------------------------------------------------------------ 计算

  void _equals() {
    if (_expr.isEmpty) return;
    if (_errorState) {
      _resetScreen();
      return;
    }
    _evaluatedSource = _expr;
    try {
      final value = evaluate(_expr, degrees: _degrees);
      final raw = formatNumber(value, grouped: false);
      final now = DateTime.now();
      _lastAnswer = raw;
      _history.insert(0, HistoryEntry(_expr, raw, now));
      if (_history.length > AppStore.maxHistory) _history.removeLast();
      AppStore.saveHistory(_history);
      _tape.add(HistoryEntry(_expr, raw, now));
      _expr = raw;
      _result = groupExpression(raw);
      _isError = false;
      _justEvaluated = true;
    } on CalcException {
      _result = '错误';
      _isError = true;
      _errorState = true;
      _justEvaluated = true;
    } on IncompleteException {
      // 输入未完成，保持现状
    }
  }

  void _syncPreview() {
    if (_isError && _errorState) return;
    final preview = livePreview(_expr, degrees: _degrees);
    if (preview.text.isNotEmpty) {
      _result = preview.text;
      _isError = preview.error;
    } else if (_expr.isEmpty) {
      _result = '0';
      _isError = false;
    }
  }

  void _handle(String id) {
    setState(() {
      switch (id) {
        case 'clear':
          _clear();
        case 'back':
          _backspace();
        case 'sign':
          _toggleSign();
        case '=' || 'equals':
          _equals();
        case 'percent':
          _inputPercent();
        case 'fact':
          _inputFactorial();
        case 'pi':
          _inputConstant('π');
        case 'e':
          _inputConstant('e');
        case 'sq':
          _inputPower(2);
        case 'cube':
          _inputPower(3);
        case 'pow10':
          _inputPowBase('10');
        case 'epow':
          _inputPowBase('e');
        case 'exp':
          _inputExp();
        case 'rand':
          _inputRandom();
        case 'ans':
          _inputAns();
        case 'abs':
          _inputWrap('abs');
        case 'inv':
          _inputWrap('inv');
        case 'mc':
          _memoryClear();
        case 'mr':
          _memoryRecall();
        case 'mplus':
          _memoryDelta(1);
        case 'mminus':
          _memoryDelta(-1);
        case 'sci1':
          setState(() => _sciPage = 0);
        case 'sci2':
          setState(() => _sciPage = 1);
        case 'sin':
        case 'cos':
        case 'tan':
        case 'asin':
        case 'acos':
        case 'atan':
        case 'sinh':
        case 'cosh':
        case 'tanh':
        case 'asinh':
        case 'acosh':
        case 'atanh':
        case 'ln':
        case 'log':
        case '√':
        case '∛':
          _inputFunc(id);
        case '(':
          _inputOpenParen();
        case ')':
          _inputCloseParen();
        case '+':
        case '−':
        case '×':
        case '÷':
        case '^':
          _inputOperator(id);
        default:
          _inputDigit(id);
      }
      _syncPreview();
    });
  }

  // ------------------------------------------------------------ 程序员模式

  void _handleProg(String id) {
    setState(() {
      _progError = null;
      try {
        if (id.startsWith('base-')) {
          final name = id.substring(5);
          for (final b in ProgBase.values) {
            if (b.name == name) _prog.setBase(b);
          }
          return;
        }
        if (id.startsWith('w')) {
          final bits = int.tryParse(id.substring(1));
          if (bits != null) {
            for (final w in BitWidth.values) {
              if (w.bits == bits) _prog.setWidth(w);
            }
          }
          return;
        }
        switch (id) {
          case 'clr':
            _prog.clear();
          case 'bk':
            _prog.backspace();
          case 'not':
            _prog.bitNot();
          case 'psign':
            _prog.negate();
          case 'peq':
            _prog.equals();
          case 'and':
            _prog.selectOp(ProgOp.and);
          case 'or':
            _prog.selectOp(ProgOp.or);
          case 'xor':
            _prog.selectOp(ProgOp.xor);
          case 'shl':
            _prog.selectOp(ProgOp.shl);
          case 'shr':
            _prog.selectOp(ProgOp.shr);
          case '+':
            _prog.selectOp(ProgOp.add);
          case '−':
            _prog.selectOp(ProgOp.sub);
          case '×':
            _prog.selectOp(ProgOp.mul);
          case '÷':
            _prog.selectOp(ProgOp.div);
          default:
            if (id.length == 1) _prog.inputDigit(id);
        }
      } on CalcException catch (e) {
        _progError = e.message;
      }
    });
  }

  // ------------------------------------------------------------------ 复制

  void _showCopied(String tip) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            tip,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
          backgroundColor: Neon.violet,
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _copyExpression() {
    final text =
        _justEvaluated && _evaluatedSource.isNotEmpty ? _evaluatedSource : _expr;
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    _showCopied('已复制算式');
  }

  void _copyResult() {
    if (_isError || _result.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _result.replaceAll(',', '')));
    _showCopied('已复制结果');
  }

  // ------------------------------------------------------------------ 界面

  void _toggleScience() {
    HapticFeedback.selectionClick();
    setState(() => _science = !_science);
  }

  void _toggleAngle() {
    HapticFeedback.selectionClick();
    setState(() {
      _degrees = !_degrees;
      _syncPreview();
    });
  }

  void _setMode(AppMode mode) {
    if (mode == _mode) return;
    HapticFeedback.selectionClick();
    setState(() {
      _mode = mode;
      _progError = null;
    });
    _focusNode.requestFocus();
  }

  void _openHistory() {
    HapticFeedback.lightImpact();
    showHistorySheet(
      context,
      entries: _history,
      onClear: () => setState(() {
        _history.clear();
        AppStore.saveHistory(_history);
      }),
      onPick: (entry) => setState(() {
        _expr = entry.result;
        _evaluatedSource = entry.expression;
        _isError = false;
        _errorState = false;
        _justEvaluated = true;
        _syncPreview();
      }),
      onCopy: (entry) {
        Clipboard.setData(
            ClipboardData(text: '${entry.expression} = ${entry.result}'));
        _showCopied('已复制记录');
      },
    );
  }

  void _openTheme() {
    HapticFeedback.lightImpact();
    showThemeSheet(
      context,
      current: themeIndex.value,
      onSelect: (index) {
        selectTheme(index);
        AppStore.saveTheme(index);
      },
    );
  }

  void _openStats() {
    HapticFeedback.lightImpact();
    final source = _justEvaluated && _evaluatedSource.isNotEmpty
        ? _evaluatedSource
        : _expr;
    final numbers = _numberInExpr
        .allMatches(source)
        .map((m) => m.group(0)!)
        .join(', ');
    showStatsSheet(context, initial: numbers);
  }

  // ---------------------------------------------------------------- 键盘输入

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_mode == AppMode.convert) return KeyEventResult.ignored;
    // 弹层（历史/主题/统计等）打开时交给弹层处理
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return KeyEventResult.ignored;

    String? id;
    final ch = event.character;
    if (ch != null && ch.length == 1) {
      final c = ch.toLowerCase();
      if ('0123456789'.contains(c)) {
        id = c;
      } else {
        switch (c) {
          case '.':
            id = '.';
          case '+':
            id = '+';
          case '-':
            id = '−';
          case '*':
            id = '×';
          case '/':
            id = '÷';
          case '%':
            id = 'percent';
          case '^':
            id = '^';
          case '(':
            id = '(';
          case ')':
            id = ')';
          case '=':
            id = '=';
          case 'p':
            id = 'pi';
          case '&':
            id = 'and';
          case '|':
            id = 'or';
          case '~':
            id = 'not';
          case 'x':
            id = 'xor';
          default:
            if ('abcdef'.contains(c)) id = c;
        }
      }
    }
    if (id == null) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        id = '=';
      } else if (key == LogicalKeyboardKey.backspace) {
        id = 'back';
      } else if (key == LogicalKeyboardKey.escape) {
        id = 'clear';
      }
    }
    if (id == null) return KeyEventResult.ignored;

    if (_mode == AppMode.prog) {
      final progId = switch (id) {
        'back' => 'bk',
        'clear' => 'clr',
        '=' => 'peq',
        'pi' || 'percent' || '^' || '(' || ')' => null,
        'a' || 'b' || 'c' || 'd' || 'e' || 'f' => id.toUpperCase(),
        _ => id,
      };
      if (progId == null) return KeyEventResult.ignored;
      _handleProg(progId);
      return KeyEventResult.handled;
    }

    final calcId = switch (id) {
      'and' || 'or' || 'xor' || 'not' => null,
      'a' || 'b' || 'c' || 'd' || 'f' => null, // 仅 e 作为自然常量
      _ => id,
    };
    if (calcId == null) return KeyEventResult.ignored;
    _handle(calcId);
    return KeyEventResult.handled;
  }

  // ---------------------------------------------------------------- 组件

  Widget _iconButton(IconData icon, VoidCallback onTap, {String? tooltip}) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      icon: Icon(icon, color: const Color(0xCCFFFFFF), size: 24),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: Neon.equalsGradient,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: Neon.violet.withValues(alpha: 0.55),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Neon.violetSoft, Neon.cyan],
                    ).createShader(bounds),
                    child: const Text(
                      'NEON CALC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
              _iconButton(Icons.palette_rounded, _openTheme, tooltip: '主题'),
              _iconButton(Icons.analytics_rounded, _openStats, tooltip: '统计'),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: _openHistory,
                    icon: const Icon(Icons.history_rounded,
                        color: Color(0xCCFFFFFF), size: 26),
                  ),
                  if (_history.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: Neon.equalsGradient,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Neon.background, width: 1.5),
                        ),
                        child: Text(
                          _history.length > 99 ? '99+' : '${_history.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                NeonChip(
                  label: '计算',
                  active: _mode == AppMode.calc,
                  onTap: () => _setMode(AppMode.calc),
                ),
                const SizedBox(width: 8),
                NeonChip(
                  label: '程序员',
                  active: _mode == AppMode.prog,
                  onTap: () => _setMode(AppMode.prog),
                ),
                const SizedBox(width: 8),
                NeonChip(
                  label: '换算',
                  active: _mode == AppMode.convert,
                  onTap: () => _setMode(AppMode.convert),
                ),
                if (_mode == AppMode.calc) ...[
                  const SizedBox(width: 8),
                  NeonChip(
                    label: '科学',
                    active: _science,
                    icon: Icons.functions_rounded,
                    onTap: _toggleScience,
                  ),
                ],
                if (_mode == AppMode.calc && _science) ...[
                  const SizedBox(width: 8),
                  NeonChip(
                    label: _degrees ? 'DEG' : 'RAD',
                    active: _degrees,
                    onTap: _toggleAngle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _memKey(KeySpec spec) {
    final enabled = switch (spec.id) {
      'mc' || 'mr' => _memory != null,
      _ => true,
    };
    return Expanded(
      child: GestureDetector(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                _handle(spec.id);
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    colors: [
                      Neon.violet.withValues(alpha: 0.28),
                      Neon.violet.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: enabled ? null : const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? Neon.violet.withValues(alpha: 0.5)
                  : const Color(0x1AFFFFFF),
            ),
          ),
          child: Text(
            spec.label,
            style: TextStyle(
              color: enabled ? Neon.violetSoft : const Color(0x4DFFFFFF),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryBar() {
    final has = _memory != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: has
                    ? Neon.violet.withValues(alpha: 0.16)
                    : const Color(0x10FFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: has
                      ? Neon.violet.withValues(alpha: 0.5)
                      : const Color(0x22FFFFFF),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  has ? 'M=${formatNumber(_memory!)}' : 'M ∅',
                  maxLines: 1,
                  style: TextStyle(
                    color: has ? Neon.violetSoft : const Color(0x66FFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          for (var i = 0; i < memoryKeys.length; i++) ...[
            _memKey(memoryKeys[i]),
            if (i < memoryKeys.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _sciDot(int page) {
    final active = page == _sciPage;
    return GestureDetector(
      key: ValueKey('sci-page-$page'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _sciPage = page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: active ? 22 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: active ? Neon.equalsGradient : null,
          color: active ? null : Colors.white24,
          borderRadius: BorderRadius.circular(5),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Neon.pink.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _keyRow(List<KeySpec> row, int index) {
    var i = index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: Row(
          children: [
            for (final spec in row)
              Expanded(
                child: NeonButton(
                  key: ValueKey(spec.id),
                  spec: spec,
                  index: i++,
                  onTap: () => _handle(spec.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    var index = 0;
    final children = <Widget>[];
    if (_science) {
      for (final row in sciencePages[_sciPage]) {
        children.add(_keyRow(row, index));
        index += 4;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (var p = 0; p < sciencePages.length; p++) _sciDot(p)],
          ),
        ),
      );
    }
    for (final row in standardRows) {
      children.add(_keyRow(row, index));
      index += 4;
    }
    return Column(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Neon.background,
        body: Stack(
          children: [
            const Positioned.fill(child: AuroraBackground()),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  if (_mode == AppMode.calc) ...[
                    Expanded(
                      // 显示区（含纸带）38 / 键盘 62
                      flex: 38,
                      child: CalcDisplay(
                        tape: _tape,
                        picked: _tapePicked,
                        expression: groupExpression(
                          _justEvaluated && _evaluatedSource.isNotEmpty
                              ? _evaluatedSource
                              : _expr,
                        ),
                        result: _result,
                        isError: _isError,
                        onCopyExpression: _copyExpression,
                        onCopyResult: _copyResult,
                        onPickTape: _pickTape,
                      ),
                    ),
                    Expanded(
                      flex: 62,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        child: Column(
                          children: [
                            _buildMemoryBar(),
                            Expanded(child: _buildKeypad()),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_mode == AppMode.prog)
                    Expanded(
                      child: ProgrammerView(
                        calc: _prog,
                        error: _progError,
                        onKey: _handleProg,
                      ),
                    )
                  else
                    const Expanded(child: UnitConverterView()),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
