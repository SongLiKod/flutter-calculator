# 霓虹计算器 Neon Calculator

一款带极光动效、科学模式、程序员模式、单位换算与历史记录的炫酷计算器（Flutter 实现）。

![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B) ![Dart](https://img.shields.io/badge/Dart-3.13-0175C2)

## ✨ 特性

### 视觉与交互
- **霓虹视觉**：深色底 + 三色极光光斑缓慢流动，结果区渐变辉光，按键带辉光阴影与按压动效，全键盘错峰入场动画（手势层置于入场动画外层，动画期间点击不落空）。
- **多套主题**：`霓虹紫 / 赛博青 / 熔岩橙 / 樱花粉 / 极光绿` 五套配色，右上角调色板一键切换，自动记住上次选择。
- **实体键盘**：数字、`+ - * / % ^ ( )`、`p`（π）、回车 `=`、`Backspace` 退格、`Esc` 清空均可直接输入；程序员模式下自动翻译为 `AND/OR/XOR/NOT/HEX 数位` 等键位。
- **实时预览**：边输入边计算，结果随按键平滑缩放脉冲；点按结果或算式旁的复制按钮可复制到剪贴板。
- **贴心细节**：`±` 正负号自动包裹、`%` 百分比语义（`200+50% = 300`）、除零提示、千分位分隔、超大/超小值自动科学计数、按键触觉反馈、竖屏锁定、自适应霓虹图标与深色启动页。

### 功能
- **科学模式**：两页科学键盘（圆点指示器切换）。
  - 第 1 页：`sin / cos / tan / √ / asin / acos / atan / ln / log / xʸ / n! / |x| / ( ) / π / e`，支持 **DEG / RAD** 切换。
  - 第 2 页：`sinh / cosh / tanh / asinh / acosh / atanh / x² / x³ / ∛ / 1/x / 10ˣ / eˣ / EXP / RAN# / Ans`。
- **程序员模式**：`HEX / DEC / OCT / BIN` 四进制读数实时联动，`8 / 16 / 32 / 64` 位宽（64 位按补码处理），`AND / OR / XOR / NOT / << / >> / ± / CLR / ⌫` 位运算键盘，`A–F` 数位仅在 HEX 下可用。
- **单位换算**：长度 / 重量 / 温度 / 面积 / 速度 / 时间 / 数据 7 类，双单位下拉 + 一键交换，温度为公式特例，点按结果即可复制。
- **统计计算**：输入一串数字（逗号 / 空格 / 换行分隔）自动统计 N、总和、平均值、最大最小、极差、方差与标准差，可切换 **样本 (n−1) / 总体 (n)**。
- **记忆键**：`MC / MR / M+ / M−` 记忆条常驻键盘上方，记忆值本地持久化。
- **计算历史**：毛玻璃底部面板，记录时间与原始算式，点击回填继续计算，支持单条复制与一键清空。
- **本地持久化**：历史记录、记忆值、主题选择均保存在 `shared_preferences`，重启自动恢复（读写失败自动容错）。

## 📂 结构

```
lib/
├── main.dart                  # 入口：主题恢复 + 主题监听整树重建
├── home_page.dart             # 状态机（输入规则、等号、记忆、键盘分发、实体键盘）
├── calculator/
│   ├── engine.dart            # 词法分析 + 递归下降求值 + 数值格式化
│   ├── key_spec.dart          # 键位定义（标准 / 科学两页 / 记忆 / 程序员）
│   ├── programmer.dart        # 程序员模式纯逻辑（进制、位宽、位运算）
│   ├── units.dart             # 单位换算纯逻辑（7 类 + 温度特例）
│   ├── stats.dart             # 统计量纯解析与计算
│   └── store.dart             # 历史 / 记忆 / 主题持久化
├── theme/neon_theme.dart      # 霓虹色板、渐变与 5 套主题预设
└── widgets/
    ├── aurora_background.dart # 极光光斑背景动画
    ├── display.dart           # 表达式 + 结果展示（复制入口）
    ├── neon_button.dart       # 发光按键（按压、入场动画、触感）
    ├── neon_chip.dart         # 胶囊按钮（模式 / 进制 / 类别切换）
    ├── programmer_view.dart   # 程序员模式界面
    ├── unit_converter.dart    # 单位换算界面
    ├── stats_sheet.dart       # 统计底部面板
    ├── theme_sheet.dart       # 主题底部面板
    └── history_sheet.dart     # 历史记录底部面板
```

## 🧪 测试

```bash
flutter analyze    # 静态检查（0 问题）
flutter test       # 77 例：引擎/进制/换算/统计单元测试 + UI 交互测试
```

- `test/calculator_engine_test.dart`：求值、函数、格式化
- `test/programmer_test.dart`：进制、位宽、位运算
- `test/units_test.dart` / `test/stats_test.dart`：换算与统计
- `test/app_test.dart`：基础算式、错误态、科学模式与历史
- `test/features_test.dart`：记忆键、程序员模式、换算、统计、主题、实体键盘、复制、持久化恢复、科学键盘分页

## 📦 打包

```bash
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

Release 使用 `android/key.properties` 指向的正式签名（`android/app/upload-keystore.jks`），
未配置时自动回退到 debug 签名。

## 🎮 使用

- `C` 清空，`⌫` 退格（函数名与 `±` 包裹会整体删除）
- `=` 后：数字开启新算式，运算符接续结果继续算
- `科学` 切换科学键盘，展开后可切换 `DEG / RAD` 与两页函数
- `计算 / 程序员 / 换算` 顶部胶囊切换三种模式
- 记忆条 `MC / MR / M+ / M−`：`M+` 累加当前值，`MR` 取回，`MC` 清空
- 右上角：调色板换主题、柱状图打开统计、时钟查看历史
- 实体键盘可直接输入，弹层打开时按键交给弹层处理
