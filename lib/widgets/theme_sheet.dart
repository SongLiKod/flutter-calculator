import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/neon_theme.dart';

/// 主题选择底部面板。
void showThemeSheet(
  BuildContext context, {
  required int current,
  required ValueChanged<int> onSelect,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    builder: (sheetContext) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xF015151F), Color(0xF70A0A12)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: const Color(0x33FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: Neon.violet.withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 46,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: Row(
              children: [
                Icon(Icons.palette_rounded, color: Neon.cyan, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '主题配色',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: neonPresets.length,
              itemBuilder: (context, index) {
                final preset = neonPresets[index];
                final active = index == current;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(sheetContext).pop();
                      onSelect(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        gradient: active ? Neon.equalsGradient : null,
                        color: active ? null : const Color(0x14FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? Colors.white54 : const Color(0x22FFFFFF),
                        ),
                      ),
                      child: Row(
                        children: [
                          // 三色预览
                          Container(
                            width: 52,
                            height: 34,
                            decoration: BoxDecoration(
                              color: preset.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0x33FFFFFF)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _dot(preset.violet),
                                _dot(preset.pink),
                                _dot(preset.amber),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              preset.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          if (active)
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _dot(Color color) => Container(
      width: 9,
      height: 9,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 5)],
      ),
    );
