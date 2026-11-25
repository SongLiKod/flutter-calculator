enum KeyKind { number, operator, func, action, constant, equals, memory }

class KeySpec {
  final String id;
  final String label;
  final KeyKind kind;
  final double fontSize;

  const KeySpec({
    required this.id,
    required this.label,
    required this.kind,
    this.fontSize = 28,
  });
}

const KeySpec _k7 = KeySpec(id: '7', label: '7', kind: KeyKind.number);
const KeySpec _k8 = KeySpec(id: '8', label: '8', kind: KeyKind.number);
const KeySpec _k9 = KeySpec(id: '9', label: '9', kind: KeyKind.number);
const KeySpec _k4 = KeySpec(id: '4', label: '4', kind: KeyKind.number);
const KeySpec _k5 = KeySpec(id: '5', label: '5', kind: KeyKind.number);
const KeySpec _k6 = KeySpec(id: '6', label: '6', kind: KeyKind.number);
const KeySpec _k1 = KeySpec(id: '1', label: '1', kind: KeyKind.number);
const KeySpec _k2 = KeySpec(id: '2', label: '2', kind: KeyKind.number);
const KeySpec _k3 = KeySpec(id: '3', label: '3', kind: KeyKind.number);
const KeySpec _k0 = KeySpec(id: '0', label: '0', kind: KeyKind.number);
const KeySpec _dot = KeySpec(id: '.', label: '.', kind: KeyKind.number);

const List<List<KeySpec>> standardRows = [
  [
    KeySpec(id: 'clear', label: 'C', kind: KeyKind.action, fontSize: 26),
    KeySpec(id: 'back', label: '⌫', kind: KeyKind.action, fontSize: 26),
    KeySpec(id: 'percent', label: '%', kind: KeyKind.number, fontSize: 26),
    KeySpec(id: '÷', label: '÷', kind: KeyKind.operator),
  ],
  [_k7, _k8, _k9, KeySpec(id: '×', label: '×', kind: KeyKind.operator)],
  [_k4, _k5, _k6, KeySpec(id: '−', label: '−', kind: KeyKind.operator)],
  [_k1, _k2, _k3, KeySpec(id: '+', label: '+', kind: KeyKind.operator)],
  [
    KeySpec(id: 'sign', label: '±', kind: KeyKind.action, fontSize: 24),
    _k0,
    _dot,
    KeySpec(id: '=', label: '=', kind: KeyKind.equals, fontSize: 30),
  ],
];

// ---------------------------------------------------------------- 科学键盘（两页）

const List<List<KeySpec>> sciencePage1 = [
  [
    KeySpec(id: 'sin', label: 'sin', kind: KeyKind.func, fontSize: 20),
    KeySpec(id: 'cos', label: 'cos', kind: KeyKind.func, fontSize: 20),
    KeySpec(id: 'tan', label: 'tan', kind: KeyKind.func, fontSize: 20),
    KeySpec(id: '√', label: '√', kind: KeyKind.func, fontSize: 24),
  ],
  [
    KeySpec(id: 'asin', label: 'asin', kind: KeyKind.func, fontSize: 17),
    KeySpec(id: 'acos', label: 'acos', kind: KeyKind.func, fontSize: 17),
    KeySpec(id: 'atan', label: 'atan', kind: KeyKind.func, fontSize: 17),
    KeySpec(id: 'ln', label: 'ln', kind: KeyKind.func, fontSize: 21),
  ],
  [
    KeySpec(id: 'log', label: 'log', kind: KeyKind.func, fontSize: 21),
    KeySpec(id: '^', label: 'xʸ', kind: KeyKind.func, fontSize: 21),
    KeySpec(id: 'fact', label: 'n!', kind: KeyKind.func, fontSize: 21),
    KeySpec(id: 'abs', label: '|x|', kind: KeyKind.func, fontSize: 22),
  ],
  [
    KeySpec(id: '(', label: '(', kind: KeyKind.constant, fontSize: 26),
    KeySpec(id: ')', label: ')', kind: KeyKind.constant, fontSize: 26),
    KeySpec(id: 'pi', label: 'π', kind: KeyKind.constant, fontSize: 24),
    KeySpec(id: 'e', label: 'e', kind: KeyKind.constant, fontSize: 24),
  ],
];

const List<List<KeySpec>> sciencePage2 = [
  [
    KeySpec(id: 'sinh', label: 'sinh', kind: KeyKind.func, fontSize: 17),
    KeySpec(id: 'cosh', label: 'cosh', kind: KeyKind.func, fontSize: 17),
    KeySpec(id: 'tanh', label: 'tanh', kind: KeyKind.func, fontSize: 17),
    KeySpec(id: 'sq', label: 'x²', kind: KeyKind.func, fontSize: 24),
  ],
  [
    KeySpec(id: 'asinh', label: 'asinh', kind: KeyKind.func, fontSize: 15),
    KeySpec(id: 'acosh', label: 'acosh', kind: KeyKind.func, fontSize: 15),
    KeySpec(id: 'atanh', label: 'atanh', kind: KeyKind.func, fontSize: 15),
    KeySpec(id: 'inv', label: '1/x', kind: KeyKind.func, fontSize: 22),
  ],
  [
    KeySpec(id: 'pow10', label: '10ˣ', kind: KeyKind.func, fontSize: 21),
    KeySpec(id: 'epow', label: 'eˣ', kind: KeyKind.func, fontSize: 21),
    KeySpec(id: 'exp', label: 'EXP', kind: KeyKind.func, fontSize: 17),
    KeySpec(id: 'rand', label: 'RAN#', kind: KeyKind.func, fontSize: 15),
  ],
  [
    KeySpec(id: 'ans', label: 'Ans', kind: KeyKind.constant, fontSize: 20),
    KeySpec(id: 'cube', label: 'x³', kind: KeyKind.func, fontSize: 24),
    KeySpec(id: '∛', label: '∛', kind: KeyKind.func, fontSize: 24),
    KeySpec(id: 'percent', label: '%', kind: KeyKind.number, fontSize: 26),
  ],
];

/// 科学键盘两页。
const List<List<List<KeySpec>>> sciencePages = [sciencePage1, sciencePage2];

// ---------------------------------------------------------------- 记忆键

const List<KeySpec> memoryKeys = [
  KeySpec(id: 'mc', label: 'MC', kind: KeyKind.memory, fontSize: 15),
  KeySpec(id: 'mr', label: 'MR', kind: KeyKind.memory, fontSize: 15),
  KeySpec(id: 'mplus', label: 'M+', kind: KeyKind.memory, fontSize: 15),
  KeySpec(id: 'mminus', label: 'M−', kind: KeyKind.memory, fontSize: 15),
];

// ---------------------------------------------------------------- 程序员键盘

const KeySpec _p7 = KeySpec(id: '7', label: '7', kind: KeyKind.number, fontSize: 26);
const KeySpec _p8 = KeySpec(id: '8', label: '8', kind: KeyKind.number, fontSize: 26);
const KeySpec _p9 = KeySpec(id: '9', label: '9', kind: KeyKind.number, fontSize: 26);
const KeySpec _p4 = KeySpec(id: '4', label: '4', kind: KeyKind.number, fontSize: 26);
const KeySpec _p5 = KeySpec(id: '5', label: '5', kind: KeyKind.number, fontSize: 26);
const KeySpec _p6 = KeySpec(id: '6', label: '6', kind: KeyKind.number, fontSize: 26);
const KeySpec _p1 = KeySpec(id: '1', label: '1', kind: KeyKind.number, fontSize: 26);
const KeySpec _p2 = KeySpec(id: '2', label: '2', kind: KeyKind.number, fontSize: 26);
const KeySpec _p3 = KeySpec(id: '3', label: '3', kind: KeyKind.number, fontSize: 26);
const KeySpec _p0 = KeySpec(id: '0', label: '0', kind: KeyKind.number, fontSize: 26);

const List<List<KeySpec>> programRows = [
  [
    KeySpec(id: 'clr', label: 'CLR', kind: KeyKind.action, fontSize: 15),
    KeySpec(id: 'bk', label: '⌫', kind: KeyKind.action, fontSize: 24),
    KeySpec(id: 'not', label: 'NOT', kind: KeyKind.func, fontSize: 15),
    KeySpec(id: 'and', label: 'AND', kind: KeyKind.func, fontSize: 15),
    KeySpec(id: 'or', label: 'OR', kind: KeyKind.func, fontSize: 15),
    KeySpec(id: 'xor', label: 'XOR', kind: KeyKind.func, fontSize: 15),
  ],
  [
    KeySpec(id: 'shl', label: '<<', kind: KeyKind.func, fontSize: 22),
    KeySpec(id: 'shr', label: '>>', kind: KeyKind.func, fontSize: 22),
    KeySpec(id: '÷', label: '÷', kind: KeyKind.operator),
    KeySpec(id: '×', label: '×', kind: KeyKind.operator),
    KeySpec(id: '−', label: '−', kind: KeyKind.operator),
    KeySpec(id: '+', label: '+', kind: KeyKind.operator),
  ],
  [
    _p7, _p8, _p9,
    KeySpec(id: 'A', label: 'A', kind: KeyKind.constant, fontSize: 24),
    KeySpec(id: 'B', label: 'B', kind: KeyKind.constant, fontSize: 24),
    KeySpec(id: 'C', label: 'C', kind: KeyKind.constant, fontSize: 24),
  ],
  [
    _p4, _p5, _p6,
    KeySpec(id: 'D', label: 'D', kind: KeyKind.constant, fontSize: 24),
    KeySpec(id: 'E', label: 'E', kind: KeyKind.constant, fontSize: 24),
    KeySpec(id: 'F', label: 'F', kind: KeyKind.constant, fontSize: 24),
  ],
  [
    _p1, _p2, _p3,
    _p0,
    KeySpec(id: 'psign', label: '±', kind: KeyKind.action, fontSize: 22),
    KeySpec(id: 'peq', label: '=', kind: KeyKind.equals, fontSize: 28),
  ],
];

/// 进制选择（程序员模式）。
const List<(String, String)> progBases = [
  ('dec', 'DEC'),
  ('hex', 'HEX'),
  ('oct', 'OCT'),
  ('bin', 'BIN'),
];

/// 位宽选择（程序员模式）。
const List<(int, String)> progWidths = [
  (8, '8位'),
  (16, '16位'),
  (32, '32位'),
  (64, '64位'),
];
