import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/neon_theme.dart';

class HistoryEntry {
  final String expression;
  final String result;
  final DateTime time;

  const HistoryEntry(this.expression, this.result, this.time);
}

String _two(int v) => v < 10 ? '0$v' : '$v';

void showHistorySheet(
  BuildContext context, {
  required List<HistoryEntry> entries,
  required ValueChanged<HistoryEntry> onPick,
  required VoidCallback onClear,
  required ValueChanged<HistoryEntry> onCopy,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => _HistoryPanel(
        entries: entries,
        scrollController: scrollController,
        onPick: (entry) {
          HapticFeedback.selectionClick();
          Navigator.of(sheetContext).pop();
          onPick(entry);
        },
        onCopy: (entry) {
          HapticFeedback.selectionClick();
          onCopy(entry);
        },
        onClear: onClear,
      ),
    ),
  );
}

class _HistoryPanel extends StatelessWidget {
  final List<HistoryEntry> entries;
  final ScrollController scrollController;
  final ValueChanged<HistoryEntry> onPick;
  final ValueChanged<HistoryEntry> onCopy;
  final VoidCallback onClear;

  const _HistoryPanel({
    required this.entries,
    required this.scrollController,
    required this.onPick,
    required this.onCopy,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xF015151F), Color(0xF70A0A12)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Neon.violet.withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
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
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: Neon.cyan, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '计算历史',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                if (entries.isNotEmpty)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: Icon(Icons.delete_sweep_rounded,
                        size: 18, color: Neon.pink),
                    label: Text(
                      '清空',
                      style: TextStyle(color: Neon.pink, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _HistoryTile(
                        entry: entry,
                        onTap: () => onPick(entry),
                        onCopy: () => onCopy(entry),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final time =
        '${_two(entry.time.hour)}:${_two(entry.time.minute)}:${_two(entry.time.second)}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onCopy,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0x1AFFFFFF), Color(0x0AFFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x22FFFFFF)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.expression,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 14,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.result,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onCopy,
                tooltip: '复制',
                constraints:
                    const BoxConstraints.tightFor(width: 34, height: 34),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: Color(0x66FFFFFF),
                ),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.north_east_rounded,
                      size: 16, color: Neon.violetSoft),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Neon.violet, Neon.pink],
              ),
              boxShadow: [
                BoxShadow(
                  color: Neon.violet.withValues(alpha: 0.5),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(Icons.calculate_outlined,
                color: Colors.white, size: 34),
          ),
          const SizedBox(height: 16),
          const Text(
            '还没有计算记录',
            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 15),
          ),
        ],
      ),
    );
  }
}
