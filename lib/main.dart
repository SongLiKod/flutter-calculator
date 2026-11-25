import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';
import 'theme/neon_theme.dart';

const String kThemePrefKey = 'theme';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 恢复上次选择的主题（失败时使用默认）。
  try {
    final prefs = await SharedPreferences.getInstance();
    selectTheme(prefs.getInt(kThemePrefKey) ?? 0);
  } catch (_) {
    // 忽略持久化异常
  }

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Neon.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const NeonCalculatorApp());
}

class NeonCalculatorApp extends StatelessWidget {
  const NeonCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 监听主题下标：换肤时整树重建，刷新所有非 const 的霓虹色。
    return ValueListenableBuilder<int>(
      valueListenable: themeIndex,
      builder: (context, index, _) {
        Neon.applyPreset(neonPresets[index]);
        return MaterialApp(
          title: '霓虹计算器',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Neon.violet,
            scaffoldBackgroundColor: Neon.background,
            splashFactory: InkRipple.splashFactory,
          ),
          home: const HomePage(),
        );
      },
    );
  }
}
