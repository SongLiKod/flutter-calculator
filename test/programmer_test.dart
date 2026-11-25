import 'package:flutter_test/flutter_test.dart';
import 'package:neon_calculator/calculator/engine.dart';
import 'package:neon_calculator/calculator/programmer.dart';

void main() {
  group('进制转换', () {
    test('十进制值的四种进制展示', () {
      final c = ProgrammerCalc();
      for (final d in '255'.split('')) {
        c.inputDigit(d);
      }
      expect(c.format(as: ProgBase.dec), '255');
      expect(c.format(as: ProgBase.hex), 'FF');
      expect(c.format(as: ProgBase.bin), '11111111');
      expect(c.format(as: ProgBase.oct), '377');
    });

    test('分组展示', () {
      final c = ProgrammerCalc();
      for (final d in '65535'.split('')) {
        c.inputDigit(d);
      }
      expect(c.format(as: ProgBase.bin, group: true), '1111 1111 1111 1111');
      expect(c.format(as: ProgBase.hex, group: true), 'FFFF');
      expect(c.format(as: ProgBase.oct, group: true), '177 777');
      expect(c.format(as: ProgBase.dec, group: true), '65535');
    });

    test('HEX 输入与位宽无关的解析', () {
      final c = ProgrammerCalc();
      c.setBase(ProgBase.hex);
      c.inputDigit('F');
      c.inputDigit('f');
      expect(c.format(as: ProgBase.dec), '255');
      expect(c.format(as: ProgBase.bin), '11111111');
    });

    test('非法数位按当前进制忽略', () {
      final c = ProgrammerCalc();
      expect(c.canInput('A'), isFalse);
      expect(c.canInput('8'), isTrue);
      c.inputDigit('8');
      c.inputDigit('A'); // 十进制下忽略
      expect(c.format(as: ProgBase.dec), '8');

      c.clear();
      c.setBase(ProgBase.oct);
      expect(c.canInput('8'), isFalse);
      c.inputDigit('9');
      expect(c.entry, isNull);
      c.inputDigit('7');
      expect(c.format(as: ProgBase.oct), '7');

      c.clear();
      c.setBase(ProgBase.bin);
      expect(c.canInput('2'), isFalse);
      expect(c.canInput('1'), isTrue);
    });

    test('切换进制保留输入串', () {
      final c = ProgrammerCalc();
      c.setBase(ProgBase.hex);
      c.inputDigit('F');
      c.inputDigit('F');
      c.setBase(ProgBase.dec);
      expect(c.entry, '255');
      expect(c.format(as: ProgBase.dec), '255');
      expect(c.entry, '255');
    });

    test('前导零折叠与退格', () {
      final c = ProgrammerCalc();
      c.inputDigit('0');
      c.inputDigit('0');
      c.inputDigit('5');
      expect(c.entry, '5');
      c.backspace();
      expect(c.entry, isNull);
      expect(c.value, 0);
    });
  });

  group('位宽与补码', () {
    test('负数按位宽显示补码', () {
      final c = ProgrammerCalc();
      c.value = -1;
      c.setWidth(BitWidth.w8);
      expect(c.format(as: ProgBase.dec), '-1');
      expect(c.format(as: ProgBase.hex), 'FF');
      expect(c.format(as: ProgBase.bin), '11111111');

      c.setWidth(BitWidth.w32);
      expect(c.format(as: ProgBase.hex), 'FFFFFFFF');
      expect(c.format(as: ProgBase.dec), '-1');
    });

    test('超位宽截断', () {
      final c = ProgrammerCalc();
      c.setWidth(BitWidth.w8);
      for (final d in '200'.split('')) {
        c.inputDigit(d);
      }
      c.selectOp(ProgOp.add);
      for (final d in '100'.split('')) {
        c.inputDigit(d);
      }
      c.equals(); // 300 → 44
      expect(c.format(as: ProgBase.dec), '44');
      expect(c.format(as: ProgBase.hex), '2C');
    });

    test('切换位宽重新归一化', () {
      final c = ProgrammerCalc();
      c.value = -1;
      c.setWidth(BitWidth.w32);
      expect(c.format(as: ProgBase.dec), '-1');
      c.setWidth(BitWidth.w8);
      expect(c.format(as: ProgBase.dec), '-1');
      expect(c.format(as: ProgBase.hex), 'FF');
    });

    test('64 位负数补码', () {
      final c = ProgrammerCalc();
      c.setWidth(BitWidth.w64);
      c.value = -2;
      expect(c.format(as: ProgBase.hex), 'FFFFFFFFFFFFFFFE');
      expect(c.format(as: ProgBase.dec), '-2');
    });
  });

  group('位运算与算术', () {
    test('AND / OR / XOR', () {
      final c = ProgrammerCalc();
      for (final d in '12'.split('')) {
        c.inputDigit(d);
      }
      c.selectOp(ProgOp.and);
      for (final d in '10'.split('')) {
        c.inputDigit(d);
      }
      expect(c.equals(), 8); // 1100 & 1010 = 1000

      c.clear();
      c.inputDigit('1');
      c.inputDigit('2');
      c.selectOp(ProgOp.or);
      c.inputDigit('3');
      expect(c.equals(), 15); // 1100 | 0011 = 1111

      c.clear();
      for (final d in '12'.split('')) {
        c.inputDigit(d);
      }
      c.selectOp(ProgOp.xor);
      for (final d in '10'.split('')) {
        c.inputDigit(d);
      }
      expect(c.equals(), 6); // 1100 ^ 1010 = 0110
    });

    test('NOT 与取负', () {
      final c = ProgrammerCalc();
      c.bitNot();
      expect(c.format(as: ProgBase.dec), '-1');
      c.setWidth(BitWidth.w8);
      c.value = 5;
      c.negate();
      expect(c.format(as: ProgBase.dec), '-5');
      expect(c.format(as: ProgBase.hex), 'FB');
    });

    test('移位', () {
      final c = ProgrammerCalc();
      c.inputDigit('1');
      c.selectOp(ProgOp.shl);
      c.inputDigit('4');
      expect(c.equals(), 16);

      c.clear();
      c.inputDigit('2');
      c.inputDigit('5');
      c.inputDigit('6');
      c.selectOp(ProgOp.shr);
      c.inputDigit('4');
      expect(c.equals(), 16);
    });

    test('链式运算与重复等号前的状态', () {
      final c = ProgrammerCalc();
      c.inputDigit('5');
      c.selectOp(ProgOp.add);
      c.inputDigit('3');
      c.selectOp(ProgOp.mul); // 先算 5+3=8，再暂存 ×
      c.inputDigit('2');
      expect(c.equals(), 16);
      expect(c.pendingOp, isNull);
    });

    test('连续按运算符只替换运算', () {
      final c = ProgrammerCalc();
      c.inputDigit('7');
      c.selectOp(ProgOp.sub);
      c.selectOp(ProgOp.add);
      c.inputDigit('2');
      expect(c.equals(), 9);
    });

    test('除法向零截断与除零', () {
      final c = ProgrammerCalc();
      c.inputDigit('7');
      c.selectOp(ProgOp.div);
      c.inputDigit('2');
      expect(c.equals(), 3);

      c.clear();
      c.inputDigit('7');
      c.selectOp(ProgOp.div);
      c.inputDigit('0');
      expect(() => c.equals(), throwsA(isA<CalcException>()));
    });

    test('等号无挂起运算时提交输入', () {
      final c = ProgrammerCalc();
      for (final d in '42'.split('')) {
        c.inputDigit(d);
      }
      expect(c.equals(), 42);
      expect(c.entry, isNull);
    });
  });
}
