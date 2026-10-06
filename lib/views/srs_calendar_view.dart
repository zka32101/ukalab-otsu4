import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/srs_calendar.dart';
import '../data/srs_store.dart';

/// 苦手問題の復習予定を、今日から14日先まで日別に見える化するカレンダー。
/// 記録タブの「苦手問題の復習」から開く（`lib/data/srs_calendar.dart`）。
class SrsCalendarView extends ConsumerWidget {
  const SrsCalendarView({super.key});

  static const _days = 14;
  static const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items = ref.watch(srsProvider).values;
    final now = DateTime.now();
    final counts = srsReviewCountsByDate(items, now, days: _days);
    final today = DateTime(now.year, now.month, now.day);
    final maxCount = counts.values.isEmpty ? 0 : counts.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('復習カレンダー')),
      body: counts.isEmpty
          ? const EmptyState(
              message: '復習予定の問題はまだありません。一問一答で間違えた問題が、ここに予定として表示されます。',
              icon: Icons.event_available_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _days,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final date = today.add(Duration(days: i));
                final count = counts[date] ?? 0;
                final isToday = i == 0;
                final label = isToday
                    ? '今日'
                    : '${date.month}/${date.day}（${_weekdayLabels[date.weekday - 1]}）';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          label,
                          style: isToday
                              ? theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
                              : theme.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) => Stack(
                            children: [
                              Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              if (maxCount > 0 && count > 0)
                                Container(
                                  height: 16,
                                  width: constraints.maxWidth * (count / maxCount).clamp(0.08, 1.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '$count問',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
