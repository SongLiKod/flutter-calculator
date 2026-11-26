import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_calculator/calculator/store.dart';
import 'package:neon_calculator/main.dart';
import 'package:neon_calculator/theme/neon_theme.dart';
import 'package:neon_calculator/widgets/neon_button.dart';
import 'package:neon_calculator/widgets/neon_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const NeonCalculatorApp());
    await tester.pump(const Duration(milliseconds: 900));
  }

  Future<void> tapKey(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(NeonButton, label));
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> tapChip(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(NeonChip, label));
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// 打开底部弹层：先 pump 构建路由，再 pump 播放入场动画。
  Future<void> settleSheet(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// 收集树上所有非按键（NeonButton）非胶囊（NeonChip）的可见文本，
  /// 用于在键盘同屏时断言读数/统计卡片。
  Set<String> plainTexts(WidgetTester tester) {
    final out = <String>{};
    for (final element in find.byType(Text).evaluate()) {
      var skip = false;
      element.visitAncestorElements((ancestor) {
        final widget = ancestor.widget;
        if (widget is NeonButton || widget is NeonChip) {
          skip = true;
          return false;
        }
        return true;
      });
      if (skip) continue;
      final data = (element.widget as Text).data;
      if (data != null && data.trim().isNotEmpty) out.add(data.trim());
    }
    return out;
  }

  /// 拦截平台通道，收集写入剪贴板的文本。
  List<String> mockClipboard(WidgetTester tester) {
    final copied = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        final args = call.arguments as Map<dynamic, dynamic>;
        copied.add(args['text'] as String);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    return copied;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    selectTheme(0);
  });

  testWidgets('记忆键 M+ / M− / MR / MC 并持久化', (tester) async {
    await pumpApp(tester);
    expect(find.text('M ∅'), findsOneWidget);

    await tapKey(tester, '1');
    await tapKey(tester, '2');
    await tester.tap(find.text('M+'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('M=12'), findsOneWidget);

    // 记忆值已写入本地存储
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble(AppStore.kMemoryKey), 12);

    // 清空表达式后用 MR 取回（记忆值不受影响）
    await tapKey(tester, 'C');
    expect(find.text('M=12'), findsOneWidget);
    await tester.tap(find.text('MR'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('12'), findsWidgets);

    // M− 把当前值减掉 → 归零
    await tester.tap(find.text('M−'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('M=0'), findsOneWidget);

    await tester.tap(find.text('MC'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('M ∅'), findsOneWidget);
    expect(prefs.getDouble(AppStore.kMemoryKey), isNull);
  });

  testWidgets('程序员模式：四进制读数与位运算', (tester) async {
    await pumpApp(tester);
    await tapChip(tester, '程序员');

    await tapKey(tester, '1');
    await tapKey(tester, '0');
    expect(
      plainTexts(tester),
      containsAll(<String>['10', 'A', '12', '1010']),
    );

    // 5 AND 3 = 1
    await tapKey(tester, 'CLR');
    await tapKey(tester, '5');
    await tapKey(tester, 'AND');
    await tapKey(tester, '3');
    await tapKey(tester, '=');
    expect(plainTexts(tester), contains('1'));

    // HEX 输入 F → DEC 15 / OCT 17 / BIN 1111
    await tapKey(tester, 'CLR');
    await tapChip(tester, 'HEX');
    await tapKey(tester, 'F');
    expect(
      plainTexts(tester),
      containsAll(<String>['F', '15', '17', '1111']),
    );

    // 位宽切换到 8 位
    await tapChip(tester, '8位');
    expect(plainTexts(tester), contains('15'));
  });

  testWidgets('单位换算：长度、温度与点按复制', (tester) async {
    final copied = mockClipboard(tester);
    await pumpApp(tester);
    await tapChip(tester, '换算');

    expect(find.text('单位换算'), findsOneWidget);
    expect(find.text('0.1'), findsOneWidget); // 1 mm → cm

    await tester.enterText(find.byType(TextField), '100');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('10'), findsOneWidget); // 100 mm → 10 cm

    await tapChip(tester, '温度');
    await tester.enterText(find.byType(TextField), '100');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('212'), findsOneWidget); // 100 ℃ → ℉

    await tester.tap(find.text('212'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('已复制换算结果'), findsOneWidget);
    expect(copied, contains('212'));
  });

  testWidgets('统计面板：样本与总体切换', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.analytics_rounded));
    await settleSheet(tester);
    expect(find.text('统计计算'), findsOneWidget);
    expect(find.text('输入数字后自动统计'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1 2 3 4');
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      plainTexts(tester),
      containsAll(<String>['个数 N', '总和', '平均值', '10', '2.5', '样本方差']),
    );

    await tester.tap(find.text('总体 (n)'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      plainTexts(tester),
      containsAll(<String>['总体方差', '总体标准差']),
    );

    await tester.tap(find.text('清空'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('输入数字后自动统计'), findsOneWidget);
  });

  testWidgets('主题切换并持久化', (tester) async {
    await pumpApp(tester);
    expect(Neon.violet, neonPresets[0].violet);

    await tester.tap(find.byIcon(Icons.palette_rounded));
    await settleSheet(tester);
    expect(find.text('主题配色'), findsOneWidget);

    await tester.tap(find.text('赛博青'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(themeIndex.value, 1);
    expect(Neon.violet, neonPresets[1].violet);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(AppStore.kThemeKey), 1);
    addTearDown(() => selectTheme(0));
  });

  testWidgets('实体键盘：数字、运算符、回车与清空', (tester) async {
    await pumpApp(tester);

    Future<void> press(LogicalKeyboardKey key, {String? character}) async {
      await tester.sendKeyEvent(key, character: character);
      await tester.pump(const Duration(milliseconds: 100));
    }

    await press(LogicalKeyboardKey.digit7);
    await press(LogicalKeyboardKey.digit8, character: '*');
    await press(LogicalKeyboardKey.digit8);
    expect(find.text('7×8'), findsOneWidget);

    await press(LogicalKeyboardKey.enter);
    expect(find.text('56'), findsWidgets); // 结果行与纸带各一处

    await press(LogicalKeyboardKey.backspace);
    expect(find.text('5'), findsWidgets);

    await press(LogicalKeyboardKey.escape);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('重启后恢复历史记录与记忆值', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppStore.kMemoryKey: 42.0,
      AppStore.kHistoryKey: jsonEncode(<Map<String, Object>>[
        {'e': '1+1', 'r': '2', 't': 1700000000000},
      ]),
    });
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('M=42'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.history_rounded));
    await settleSheet(tester);
    expect(find.text('计算历史'), findsOneWidget);
    expect(find.text('1+1'), findsOneWidget);
    expect(find.text('2'), findsWidgets);

    Navigator.of(tester.element(find.text('计算历史'))).pop();
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('复制算式与复制结果', (tester) async {
    final copied = mockClipboard(tester);
    await pumpApp(tester);

    await tapKey(tester, '7');
    await tapKey(tester, '×');
    await tapKey(tester, '8');
    await tapKey(tester, '=');

    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('已复制算式'), findsOneWidget);
    expect(copied, contains('7×8'));

    // 结果在纸带与大结果各出现一次：取最后（大结果）进行点按复制
    await tester.tap(find.text('56').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('已复制结果'), findsOneWidget);
    expect(copied, contains('56'));

    // 长按大结果 → 复制人民币大写
    await tester.longPress(find.text('56').last);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('已复制大写'), findsOneWidget);
    expect(copied.last, '伍拾陆元整');
  });

  testWidgets('科学键盘两页切换', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('科学'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.widgetWithText(NeonButton, 'sin'), findsOneWidget);
    expect(find.widgetWithText(NeonButton, 'sinh'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('sci-page-1')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.widgetWithText(NeonButton, 'sinh'), findsOneWidget);
    expect(find.widgetWithText(NeonButton, 'sin'), findsNothing);

    await tapKey(tester, '0');
    await tapKey(tester, 'x²');
    await tapKey(tester, '=');
    expect(find.text('0^2'), findsWidgets);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('全屏查看：进入、复制、点纸带行取用、退出', (tester) async {
    final copied = mockClipboard(tester);
    await pumpApp(tester);

    // 空纸带也能进入：显示占位提示，关闭按钮退出
    await tester.tap(find.byIcon(Icons.fullscreen_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('全屏查看'), findsOneWidget);
    expect(find.textContaining('点行可取用结果'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('全屏查看'), findsNothing);

    // 7×8 = 56 后进入全屏
    await tapKey(tester, '7');
    await tapKey(tester, '×');
    await tapKey(tester, '8');
    await tapKey(tester, '=');
    await tester.tap(find.byIcon(Icons.fullscreen_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('全屏查看'), findsOneWidget);
    expect(find.text('7×8'), findsWidgets); // 主界面与全屏各一处
    expect(find.text('Σ 56'), findsWidgets);
    expect(find.byKey(const ValueKey('fullscreen-result')), findsOneWidget);

    // 全屏内长按纸带行：四项菜单可弹出，反馈走行内提示条（主界面 SnackBar 被全屏挡住）
    await tester.longPress(find.text('7×8').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('复制和'), findsOneWidget);
    expect(find.text('复制和（大写）'), findsOneWidget);
    expect(find.text('复制和的结果链'), findsOneWidget);
    expect(find.text('复制和的算式链'), findsOneWidget);
    await tester.tap(find.text('复制和的算式链'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('已复制和的算式链')), findsOneWidget);
    expect(copied.last, '7×8 = 56');

    // 全屏内复制结果：行内提示（带 key，避免与主界面 SnackBar 文本混淆）
    await tester.tap(find.byKey(const ValueKey('fullscreen-copy-result')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('已复制结果')), findsOneWidget);
    expect(copied, contains('56'));

    // 长按大结果 → 复制人民币大写（行内提示）
    await tester.longPress(find.byKey(const ValueKey('fullscreen-result')));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey('已复制大写')), findsOneWidget);
    expect(copied.last, '伍拾陆元整');

    // 点纸带行 → 取用结果并自动关闭
    await tester.tap(find.text('7×8').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('全屏查看'), findsNothing);
    expect(find.text('7×8'), findsWidgets); // 取入后算式行显示来源等式

    // Esc 退出（等同系统返回键）
    await tester.tap(find.byIcon(Icons.fullscreen_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('全屏查看'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('全屏查看'), findsNothing);
    expect(find.text('7×8'), findsWidgets); // 退出后计算状态不变
  });

  testWidgets('长按纸带行：复制和 / 大写 / 结果链 / 算式链', (tester) async {
    final copied = mockClipboard(tester);
    await pumpApp(tester);

    await tapKey(tester, '7');
    await tapKey(tester, '×');
    await tapKey(tester, '8');
    await tapKey(tester, '=');
    await tapKey(tester, '6');
    await tapKey(tester, '×');
    await tapKey(tester, '7');
    await tapKey(tester, '=');

    // 长按纸带行 → 四项菜单
    await tester.longPress(find.text('7×8'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('复制和'), findsOneWidget);
    expect(find.text('复制和（大写）'), findsOneWidget);
    expect(find.text('复制和的结果链'), findsOneWidget);
    expect(find.text('复制和的算式链'), findsOneWidget);

    // 复制和 → 纯数值（无千分位）
    await tester.tap(find.text('复制和'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(copied.last, '56');
    expect(find.text('已复制和'), findsOneWidget);

    // 长按首行 → 复制和（大写）
    await tester.longPress(find.text('7×8'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('复制和（大写）'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(copied.last, '伍拾陆元整');
    // 上一条 SnackBar 可能还在退场，等待新提示排队进场完成
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('已复制和（大写）'), findsOneWidget);

    // 长按第二行（纸带倒序，first 即较新一行）→ 结果链
    await tester.longPress(find.text('6×7').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('复制和的结果链'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(copied.last, '56 + 42 = 98');
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('已复制和的结果链'), findsOneWidget);

    // 再长按首行 → 算式链
    await tester.longPress(find.text('7×8'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('复制和的算式链'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(copied.last, '7×8 = 56');
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('已复制和的算式链'), findsOneWidget);

    // 菜单不影响「点按取用」：点第一笔再点第二笔连续累加
    await tester.tap(find.text('7×8'));
    await tester.pump(const Duration(milliseconds: 200));
    await tapKey(tester, '+');
    await tester.tap(find.text('6×7'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('56+42'), findsOneWidget);
  });
}
