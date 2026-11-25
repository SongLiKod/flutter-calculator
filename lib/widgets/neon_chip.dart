import 'package:flutter/material.dart';

import '../theme/neon_theme.dart';

/// 霓虹胶囊按钮（头部模式切换、进制/位宽选择、换算类别等通用）。
class NeonChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;

  const NeonChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: active ? Neon.equalsGradient : null,
          color: active ? null : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active ? Colors.white38 : const Color(0x22FFFFFF),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Neon.pink.withValues(alpha: 0.45),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
