/// 程序员模式：进制转换与位运算状态机（纯 Dart，便于单测）。
///
/// 语义参考桌面计算器：立即求值（无优先级），
/// 按位运算在指定位宽下以补码处理；HEX/BIN/OCT 显示无符号值，DEC 显示有符号值。
library;

import 'engine.dart' show CalcException;

enum BitWidth {
  w8(8),
  w16(16),
  w32(32),
  w64(64);

  final int bits;
  const BitWidth(this.bits);
}

/// 程序员计算器支持的进制。
enum ProgBase {
  bin(2, 'BIN'),
  oct(8, 'OCT'),
  dec(10, 'DEC'),
  hex(16, 'HEX');

  final int radix;
  final String label;
  const ProgBase(this.radix, this.label);
}

/// 二元运算符（立即求值）。
enum ProgOp {
  add('+', '加'),
  sub('−', '减'),
  mul('×', '乘'),
  div('÷', '除'),
  and('AND', '与'),
  or('OR', '或'),
  xor('XOR', '异或'),
  shl('<<', '左移'),
  shr('>>', '右移');

  final String symbol;
  final String name;
  const ProgOp(this.symbol, this.name);
}

class ProgrammerCalc {
  BitWidth width = BitWidth.w32;
  ProgBase base = ProgBase.dec;

  /// 当前值（始终为当前位宽下的有符号值）。
  int value = 0;

  /// 正在输入的数位串（按 [base] 进制），null 表示没有输入中的数字。
  String? entry;

  /// 挂起的二元运算，等待右操作数。
  ProgOp? pendingOp;

  /// 挂起运算的左操作数。
  int accumulator = 0;

  int get _mask => width == BitWidth.w64 ? -1 : (1 << width.bits) - 1;

  /// 按位宽截断并符号扩展。
  int normalize(int v) {
    if (width == BitWidth.w64) return v;
    final m = _mask;
    final masked = v & m;
    final signBit = 1 << (width.bits - 1);
    return (masked & signBit) != 0 ? masked - (m + 1) : masked;
  }

  /// 当前有效值：输入中为输入串按当前进制解析，否则为 [value]。
  int get currentValue {
    final e = entry;
    if (e == null || e.isEmpty) return value;
    final parsed = int.tryParse(e, radix: base.radix);
    return parsed ?? value;
  }

  /// 当前位宽下是否允许输入该数位（0-9 / A-F）。
  bool canInput(String digit) {
    if (digit.length != 1) return false;
    final c = digit.toUpperCase().codeUnitAt(0);
    if (c >= 48 && c <= 57) return c - 48 < base.radix;
    if (c >= 65 && c <= 70) return base == ProgBase.hex;
    return false;
  }

  /// 输入一个数位（0-9 / A-F），非法输入直接忽略。
  void inputDigit(String digit) {
    if (!canInput(digit)) return;
    final d = digit.toUpperCase();
    entry ??= '';
    if (entry == '0' && d == '0') return; // 前导零折叠
    entry = entry == '0' ? d : '$entry$d';
  }

  /// 取负：对当前值按位宽取相反数（补码语义）。
  void negate() {
    commitEntry();
    value = normalize(-value);
  }

  /// 切换位宽：先提交输入串，再把所有状态重新归一化。
  void setWidth(BitWidth w) {
    commitEntry();
    width = w;
    value = normalize(value);
    accumulator = normalize(accumulator);
  }

  /// 切换进制：输入串按旧进制解析后以新进制继续编辑。
  void setBase(ProgBase b) {
    if (b == base) return;
    final e = entry;
    if (e != null && e.isNotEmpty) {
      final parsed = int.tryParse(e, radix: base.radix);
      if (parsed != null) entry = parsed.toRadixString(b.radix).toUpperCase();
    }
    base = b;
  }

  /// 清空全部状态。
  void clear() {
    value = 0;
    entry = null;
    pendingOp = null;
    accumulator = 0;
  }

  /// 退格：删除输入串最后一位。
  void backspace() {
    final e = entry;
    if (e == null || e.isEmpty) return;
    entry = e.length <= 1 ? null : e.substring(0, e.length - 1);
  }

  /// 提交输入串到 [value]。
  void commitEntry() {
    value = normalize(currentValue);
    entry = null;
  }

  /// 选择运算符：正在输入则先提交；已有挂起运算则先求值（链式计算）。
  void selectOp(ProgOp op) {
    if (pendingOp != null && entry != null) {
      equals();
    } else {
      commitEntry();
    }
    accumulator = value;
    pendingOp = op;
  }

  int _apply(ProgOp op, int a, int b) {
    switch (op) {
      case ProgOp.add:
        return normalize(a + b);
      case ProgOp.sub:
        return normalize(a - b);
      case ProgOp.mul:
        return normalize(a * b);
      case ProgOp.div:
        if (b == 0) throw const CalcException('除数不能为零');
        return normalize(a ~/ b); // Dart ~/ 向零截断
      case ProgOp.and:
        return normalize(a & b);
      case ProgOp.or:
        return normalize(a | b);
      case ProgOp.xor:
        return normalize(a ^ b);
      case ProgOp.shl:
        return normalize(a << (b & 63));
      case ProgOp.shr:
        return normalize(a >> (b & 63));
    }
  }

  /// 等号：执行挂起运算并返回结果。
  int equals() {
    final op = pendingOp;
    if (op == null) {
      commitEntry();
      return value;
    }
    final right = currentValue;
    final left = accumulator;
    value = _apply(op, left, right);
    entry = null;
    pendingOp = null;
    accumulator = value;
    return value;
  }

  /// NOT：按位取反。
  void bitNot() {
    commitEntry();
    value = normalize(~value);
  }

  /// 按目标进制格式化当前值；[group] 按 4 位（八进制按 3 位）分组。
  ///
  /// HEX/BIN/OCT 显示当前位宽下的无符号补码，DEC 显示有符号值。
  String format({ProgBase? as, bool group = false}) {
    final b = as ?? base;
    if (b == ProgBase.dec) return normalize(currentValue).toString();
    final signed = normalize(currentValue);
    final digits =
        BigInt.from(signed).toUnsigned(width.bits).toRadixString(b.radix).toUpperCase();
    if (!group) return digits;
    final size = b == ProgBase.oct ? 3 : 4;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % size == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
