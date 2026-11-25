/// 本地持久化：历史记录、记忆值、主题（基于 shared_preferences）。
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/history_sheet.dart';

class AppStore {
  AppStore._();

  static const String kThemeKey = 'theme';
  static const String kMemoryKey = 'memory';
  static const String kHistoryKey = 'history_v1';

  static const int maxHistory = 50;

  /// 读取历史（失败返回空表）。
  static Future<List<HistoryEntry>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(kHistoryKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      final entries = <HistoryEntry>[];
      for (final item in list) {
        try {
          final map = item as Map<String, dynamic>;
          entries.add(HistoryEntry(
            map['e'] as String,
            map['r'] as String,
            DateTime.fromMillisecondsSinceEpoch(map['t'] as int),
          ));
        } catch (_) {
          // 跳过损坏条目
        }
      }
      return entries;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveHistory(List<HistoryEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = entries
          .take(maxHistory)
          .map((e) => {
                'e': e.expression,
                'r': e.result,
                't': e.time.millisecondsSinceEpoch,
              })
          .toList();
      await prefs.setString(kHistoryKey, jsonEncode(list));
    } catch (_) {
      // 持久化失败不影响使用
    }
  }

  static Future<double?> loadMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(kMemoryKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveMemory(double? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(kMemoryKey);
      } else {
        await prefs.setDouble(kMemoryKey, value);
      }
    } catch (_) {
      // 忽略
    }
  }

  static Future<void> saveTheme(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kThemeKey, index);
    } catch (_) {
      // 忽略
    }
  }
}
