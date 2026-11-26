import 'dart:math' as math;

/// 计算过程中的可展示错误（例如除数为零）。
class CalcException implements Exception {
  final String message;
  const CalcException(this.message);

  @override
  String toString() => message;
}

/// 表达式尚未输入完整（例如末尾是运算符），预览时静默忽略。
class IncompleteException implements Exception {}

enum TokenType { number, op, leftParen, rightParen, func, constant, percent, factorial }

class Token {
  final TokenType type;
  final double number;
  final String text;
  const Token(this.type, {this.number = 0, this.text = ''});
}

const List<String> _funcNames = [
  'sin', 'cos', 'tan',
  'asin', 'acos', 'atan',
  'sinh', 'cosh', 'tanh',
  'asinh', 'acosh', 'atanh',
  'ln', 'log', 'abs',
];

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

/// 把展示用的表达式字符串切分为记号。
List<Token> tokenize(String source) {
  final tokens = <Token>[];
  var i = 0;
  while (i < source.length) {
    final c = source[i];
    if (c == ' ') {
      i++;
      continue;
    }
    if (_isDigit(c) || c == '.') {
      var j = i;
      while (j < source.length && (_isDigit(source[j]) || source[j] == '.')) {
        j++;
      }
      // 科学计数法：数字后紧跟 e/E（可带符号指数）时并入同一个数字，
      // 例如 `6.02e23`、`1.5e-3`；`2×e` 这种写法不受影响（e 前是运算符）。
      if (j < source.length && (source[j] == 'e' || source[j] == 'E')) {
        var k = j + 1;
        if (k < source.length &&
            (source[k] == '+' || source[k] == '-' || source[k] == '−')) {
          k++;
        }
        if (k < source.length && _isDigit(source[k])) {
          while (k < source.length && _isDigit(source[k])) {
            k++;
          }
          j = k;
        }
      }
      var text = source.substring(i, j);
      if (text.endsWith('.')) text = '${text}0';
      final value = double.tryParse(text.replaceAll('−', '-'));
      if (value == null) throw const CalcException('格式错误');
      tokens.add(Token(TokenType.number, number: value));
      i = j;
      continue;
    }
    if (c == '+' ||
        c == '−' ||
        c == '-' ||
        c == '×' ||
        c == '*' ||
        c == '÷' ||
        c == '/' ||
        c == '^') {
      // 兼容 ASCII 写法：- * /
      final normalized =
          c == '-' ? '−' : c == '*' ? '×' : c == '/' ? '÷' : c;
      tokens.add(Token(TokenType.op, text: normalized));
      i++;
      continue;
    }
    if (c == '(') {
      tokens.add(const Token(TokenType.leftParen));
      i++;
      continue;
    }
    if (c == ')') {
      tokens.add(const Token(TokenType.rightParen));
      i++;
      continue;
    }
    if (c == '%') {
      tokens.add(const Token(TokenType.percent));
      i++;
      continue;
    }
    if (c == '!') {
      tokens.add(const Token(TokenType.factorial));
      i++;
      continue;
    }
    if (c == 'π') {
      tokens.add(const Token(TokenType.constant, text: 'π'));
      i++;
      continue;
    }
    if (c == '√') {
      tokens.add(const Token(TokenType.func, text: '√'));
      i++;
      continue;
    }
    if (c == '∛') {
      tokens.add(const Token(TokenType.func, text: '∛'));
      i++;
      continue;
    }
    if (c == 'e') {
      tokens.add(const Token(TokenType.constant, text: 'e'));
      i++;
      continue;
    }
    if (c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122) {
      var j = i;
      while (j < source.length &&
          source[j].codeUnitAt(0) >= 97 &&
          source[j].codeUnitAt(0) <= 122) {
        j++;
      }
      final word = source.substring(i, j);
      if (_funcNames.contains(word)) {
        tokens.add(Token(TokenType.func, text: word));
        i = j;
        continue;
      }
      throw IncompleteException();
    }
    throw IncompleteException();
  }
  return tokens;
}

double _factorial(double v) {
  if (v < 0 || (v - v.roundToDouble()).abs() > 1e-9) {
    throw const CalcException('错误');
  }
  final n = v.round();
  if (n > 170) throw const CalcException('错误');
  var result = 1.0;
  for (var i = 2; i <= n; i++) {
    result *= i;
    if (!result.isFinite) throw const CalcException('错误');
  }
  return result;
}

// dart:math 未提供双曲函数，按定义实现。
double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;

double _cosh(double x) => (math.exp(x) + math.exp(-x)) / 2;

double _tanh(double x) {
  if (x > 20) return 1;
  if (x < -20) return -1;
  final e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}

double _asinh(double x) => math.log(x + math.sqrt(x * x + 1));

double _acosh(double x) => math.log(x + math.sqrt(x * x - 1));

double _atanh(double x) => 0.5 * math.log((1 + x) / (1 - x));

double _toDegrees(double radians) => radians * 180 / math.pi;

double _applyFunc(String name, double v, bool degrees) {
  switch (name) {
    case 'sin':
      return math.sin(degrees ? v * math.pi / 180 : v);
    case 'cos':
      return math.cos(degrees ? v * math.pi / 180 : v);
    case 'tan':
      if (degrees) {
        final d = v % 180;
        if ((d - 90).abs() < 1e-9 || (d + 90).abs() < 1e-9) {
          throw const CalcException('错误');
        }
      }
      return math.tan(degrees ? v * math.pi / 180 : v);
    case 'ln':
      if (v <= 0) throw const CalcException('错误');
      return math.log(v);
    case 'log':
      if (v <= 0) throw const CalcException('错误');
      return math.log(v) / math.ln10;
    case '√':
      if (v < 0) throw const CalcException('错误');
      return math.sqrt(v);
    case '∛':
      return v < 0
          ? -math.pow(-v, 1 / 3).toDouble()
          : math.pow(v, 1 / 3).toDouble();
    case 'asin':
      if (v < -1 || v > 1) throw const CalcException('错误');
      return degrees ? _toDegrees(math.asin(v)) : math.asin(v);
    case 'acos':
      if (v < -1 || v > 1) throw const CalcException('错误');
      return degrees ? _toDegrees(math.acos(v)) : math.acos(v);
    case 'atan':
      return degrees ? _toDegrees(math.atan(v)) : math.atan(v);
    case 'sinh':
      return _sinh(v);
    case 'cosh':
      return _cosh(v);
    case 'tanh':
      return _tanh(v);
    case 'asinh':
      return _asinh(v);
    case 'acosh':
      if (v < 1) throw const CalcException('错误');
      return _acosh(v);
    case 'atanh':
      if (v <= -1 || v >= 1) throw const CalcException('错误');
      return _atanh(v);
    case 'abs':
      return v.abs();
  }
  throw IncompleteException();
}

/// 递归下降文法：
///   expr   := term (('+' | '−') term)*
///   term   := unary (('×' | '÷') unary)*
///   unary  := ('+' | '−') unary | power
///   power  := postfix ('^' unary)?
///   postfix:= primary ('%' | '!')*
///   primary:= number | constant | '(' expr ')' | func '(' expr ')'
/// 百分号语义：`200+50%` == 300，`200×50%` == 100。
class _Parser {
  final List<Token> tokens;
  final bool degrees;
  int pos = 0;
  bool factorPercent = false;
  bool termPercent = false;

  _Parser(this.tokens, this.degrees);

  Token? _peek() => pos < tokens.length ? tokens[pos] : null;

  Token _next() => tokens[pos++];

  double parseAll() {
    if (tokens.isEmpty) throw IncompleteException();
    final value = parseExpression();
    if (pos != tokens.length) throw IncompleteException();
    if (!value.isFinite || value.isNaN) throw const CalcException('错误');
    return value;
  }

  double parseExpression() {
    var left = parseTerm();
    while (true) {
      final tk = _peek();
      if (tk == null || tk.type != TokenType.op) break;
      if (tk.text != '+' && tk.text != '−') break;
      _next();
      var right = parseTerm();
      if (termPercent) right = left * right;
      left = tk.text == '+' ? left + right : left - right;
    }
    return left;
  }

  double parseTerm() {
    termPercent = false;
    var left = parseUnary();
    var lastPercent = factorPercent;
    while (true) {
      final tk = _peek();
      if (tk == null || tk.type != TokenType.op) break;
      if (tk.text != '×' && tk.text != '÷') break;
      final dividing = tk.text == '÷';
      _next();
      final right = parseUnary();
      if (dividing) {
        if (right == 0) throw const CalcException('除数不能为零');
        left /= right;
      } else {
        left *= right;
      }
      lastPercent = factorPercent;
    }
    termPercent = lastPercent;
    return left;
  }

  double parseUnary() {
    final tk = _peek();
    if (tk != null && tk.type == TokenType.op && (tk.text == '+' || tk.text == '−')) {
      _next();
      final value = parseUnary();
      factorPercent = false;
      return tk.text == '−' ? -value : value;
    }
    return parsePower();
  }

  double parsePower() {
    final base = parsePostfix();
    final tk = _peek();
    if (tk != null && tk.type == TokenType.op && tk.text == '^') {
      _next();
      final exponent = parseUnary();
      factorPercent = false;
      final value = math.pow(base, exponent).toDouble();
      if (!value.isFinite) throw const CalcException('错误');
      return value;
    }
    return base;
  }

  double parsePostfix() {
    var value = parsePrimary();
    factorPercent = false;
    while (true) {
      final tk = _peek();
      if (tk == null) break;
      if (tk.type != TokenType.percent && tk.type != TokenType.factorial) break;
      _next();
      if (tk.type == TokenType.percent) {
        value = value / 100;
        factorPercent = true;
      } else {
        value = _factorial(value);
        factorPercent = false;
      }
    }
    return value;
  }

  double parsePrimary() {
    final tk = _peek();
    if (tk == null) throw IncompleteException();
    switch (tk.type) {
      case TokenType.number:
        _next();
        factorPercent = false;
        return tk.number;
      case TokenType.constant:
        _next();
        factorPercent = false;
        return tk.text == 'π' ? math.pi : math.e;
      case TokenType.func:
        _next();
        if (_peek()?.type != TokenType.leftParen) throw IncompleteException();
        _next();
        final arg = parseExpression();
        if (_peek()?.type != TokenType.rightParen) throw IncompleteException();
        _next();
        factorPercent = false;
        return _applyFunc(tk.text, arg, degrees);
      case TokenType.leftParen:
        _next();
        final value = parseExpression();
        if (_peek()?.type != TokenType.rightParen) throw IncompleteException();
        _next();
        factorPercent = false;
        return value;
      default:
        throw IncompleteException();
    }
  }
}

/// 求值入口。抛出 [CalcException] 表示计算错误，[IncompleteException] 表示输入未完成。
double evaluate(String source, {bool degrees = true}) {
  final tokens = tokenize(source);
  return _Parser(tokens, degrees).parseAll();
}

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// 把计算结果格式化为友好展示文本（去除浮点噪声，可选千分位）。
/// 内部存储使用 `grouped: false`（纯数字，不含分隔符），展示时再加分隔符。
String formatNumber(double raw, {bool grouped = true}) {
  if (!raw.isFinite || raw.isNaN) throw const CalcException('错误');
  var value = raw;
  if (value != 0) {
    value = double.parse(value.toStringAsPrecision(12));
    if (!value.isFinite) throw const CalcException('错误');
  }
  if (value == 0) return '0';

  final abs = value.abs();
  if (abs >= 1e12 || abs < 1e-9) {
    final parts = value.toStringAsExponential(6).split('e');
    var mantissa = parts[0];
    if (mantissa.contains('.')) {
      mantissa = mantissa.replaceAll(RegExp(r'0+$'), '');
      mantissa = mantissa.replaceAll(RegExp(r'\.$'), '');
    }
    final exp = int.parse(parts[1]);
    final sign = exp < 0 ? '-' : '+';
    return '${mantissa}e$sign${exp.abs()}';
  }

  // 小数位数按 12 位有效数字决定（整数部分占几位就留几位），
  // 让 toStringAsFixed 的取整吸收掉 double 末位噪声；若固定输出 10 位小数，
  // 大数会把噪声放大出来（如 1234000000.2999999523，应为 1234000000.3）。
  // 小数（整数部分 ≤ 2 位）仍取满 10 位，行为与原先一致。
  final intDigits = value.abs().truncate().toString().length;
  final decimals = (12 - intDigits).clamp(0, 10).toInt();
  var text = value.toStringAsFixed(decimals);
  if (text.contains('.')) {
    text = text.replaceAll(RegExp(r'0+$'), '');
    text = text.replaceAll(RegExp(r'\.$'), '');
  }
  final negative = text.startsWith('-');
  final body = negative ? text.substring(1) : text;
  final dot = body.indexOf('.');
  final integer = dot < 0 ? body : body.substring(0, dot);
  final fraction = dot < 0 ? '' : body.substring(dot);
  final head = grouped ? _groupThousands(integer) : integer;
  return '${negative ? '-' : ''}$head$fraction';
}

/// 把纯数字文本（`formatNumber(grouped: false)` 的输出）转为人民币大写。
/// `56146.5` → `伍万陆仟壹佰肆拾陆元伍角`；整数带「整」（`56` → `伍拾陆元整`）、
/// 负数带「负」；小数依次为角分厘毫丝忽微纤沙尘，逐位转换、不四舍五入。
/// 科学计数法或无法识别的输入原样返回。
String toChineseUpper(String plain) {
  var text = plain.trim();
  if (text.isEmpty || text.contains('e') || text.contains('E')) return plain;
  var negative = false;
  if (text.startsWith('-') || text.startsWith('−')) {
    negative = true;
    text = text.substring(1);
  }
  final dot = text.indexOf('.');
  final intText = dot < 0 ? text : text.substring(0, dot);
  final fracText = dot < 0 ? '' : text.substring(dot + 1);
  if (!RegExp(r'^\d+$').hasMatch(intText)) return plain;
  if (fracText.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fracText)) {
    return plain;
  }

  const digitChars = ['零', '壹', '贰', '叁', '肆', '伍', '陆', '柒', '捌', '玖'];
  const smallUnits = ['', '拾', '佰', '仟']; // 组内：个、十、百、千
  const bigUnits = ['', '万', '亿', '万亿']; // 组后缀：个级、万级、亿级…
  const fracUnits = ['角', '分', '厘', '毫', '丝', '忽', '微', '纤', '沙', '尘'];

  // 整数从右按 4 位分组（个级 / 万级 / 亿级…），超出可表达范围原样返回。
  final groups = <String>[];
  var rest = intText;
  while (rest.isNotEmpty) {
    final start = rest.length > 4 ? rest.length - 4 : 0;
    groups.add(rest.substring(start));
    rest = rest.substring(0, start);
  }
  if (groups.length > bigUnits.length) return plain;

  final buf = StringBuffer();
  var hasInt = false; // 整数部分是否输出过非零内容
  var pendingZero = false; // 是否需要补一个「零」
  for (var g = groups.length - 1; g >= 0; g--) {
    final digits4 = groups[g].padLeft(4, '0');
    var groupEmitted = false;
    for (var pos = 3; pos >= 0; pos--) {
      // pos 是位权（3=千…0=个），字符串索引与之相反（0=千…3=个）。
      final digit = digits4.codeUnitAt(3 - pos) - 0x30;
      if (digit == 0) {
        pendingZero = true;
        continue;
      }
      if (pendingZero && hasInt) buf.write('零');
      buf.write(digitChars[digit]);
      buf.write(smallUnits[pos]);
      hasInt = true;
      groupEmitted = true;
      pendingZero = false;
    }
    if (groupEmitted) buf.write(bigUnits[g]);
  }
  if (hasInt) buf.write('元');

  // 小数：角分厘…；整数为 0 时直接写小数（0.5 → 伍角）。
  var hasFrac = false;
  var fracPendingZero = false;
  for (var i = 0; i < fracText.length && i < fracUnits.length; i++) {
    final digit = fracText.codeUnitAt(i) - 0x30;
    if (digit == 0) {
      fracPendingZero = true;
      continue;
    }
    // 角为 0 而后面有值：整数与小数之间补一个零（100.05 → 壹佰元零伍分）。
    if (fracPendingZero && (hasInt || hasFrac)) buf.write('零');
    buf.write(digitChars[digit]);
    buf.write(fracUnits[i]);
    fracPendingZero = false;
    hasFrac = true;
  }
  if (!hasFrac && hasInt) buf.write('整');

  final body = buf.toString();
  if (body.isEmpty) return '零元整'; // 0 / 0.00
  return negative ? '负$body' : body;
}

/// 为表达式中的普通数字添加千分位（含科学计数法时原样返回）。
String groupExpression(String expression) {
  if (expression.contains('e') || expression.contains('E')) return expression;
  return expression.replaceAllMapped(RegExp(r'\d+(\.\d+)?'), (match) {
    final full = match.group(0)!;
    final dot = full.indexOf('.');
    if (dot < 0) return _groupThousands(full);
    return '${_groupThousands(full.substring(0, dot))}${full.substring(dot)}';
  });
}

class Preview {
  final String text;
  final bool error;
  const Preview(this.text, {this.error = false});
}

const Preview previewEmpty = Preview('');

/// 实时预览：输入未完成时返回空文本，计算错误时返回「错误」。
Preview livePreview(String source, {bool degrees = true}) {
  if (source.trim().isEmpty) return previewEmpty;
  try {
    final value = evaluate(source, degrees: degrees);
    return Preview(formatNumber(value));
  } on CalcException catch (e) {
    return Preview(e.message == '除数不能为零' ? '除数为零' : '错误', error: true);
  } on IncompleteException {
    return previewEmpty;
  }
}
