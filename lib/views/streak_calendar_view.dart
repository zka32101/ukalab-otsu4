import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/daily_goal_history_store.dart';
import '../data/streak_calendar.dart';

/// 連続学習日数のカレンダー表示。直近28日分を週7列のグリッドで見える化し、
/// 目標を達成した日・解答はしたが未達成の日・記録が無い日を色分けする
/// （`lib/data/streak_calendar.dart`）。記録タブの「連続学習日数」から開く。
class StreakCalendarView extends ConsumerWidget {
  const StreakCalendarView({super.key});

  static const _days = 28;
  static const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(dailyGoalHistoryProvider);
    final now = DateTime.now();
    final calendarDays = streakCalendarDays(history, now, days: _days);
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: _days - 1));
    final leadingEmptyCount = startDate.weekday - 1;

    final cells = <Widget>[
      for (var i = 0; i < leadingEmptyCount; i++) const SizedBox.shrink(),
      for (var i = 0; i < calendarDays.length; i++)
        _StreakDayCell(date: startDate.add(Duration(days: i)), entry: calendarDays[i]),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('学習カレンダー')),
      body: history.isEmpty
          ? const EmptyState(
              message: 'デイリーミッションに解答すると、ここに記録されます。',
              icon: Icons.calendar_month_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('直近${_days}日間の記録です', style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final label in _weekdayLabels)
                      Expanded(
                        child: Center(
                          child: Text(label, style: theme.textTheme.bodySmall),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  children: cells,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _Legend(color: theme.colorScheme.primary, label: '目標達成'),
                    _Legend(color: theme.colorScheme.primaryContainer, label: '解答あり'),
                    _Legend(color: theme.colorScheme.surfaceContainerHighest, label: '記録なし'),
                  ],
                ),
              ],
            ),
    );
  }
}

class _StreakDayCell extends StatelessWidget {
  const _StreakDayCell({required this.date, required this.entry});

  final DateTime date;
  final DailyGoalHistoryEntry? entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = entry == null
        ? theme.colorScheme.surfaceContainerHighest
        : entry!.achieved
            ? theme.colorScheme.primary
            : theme.colorScheme.primaryContainer;
    final textColor = entry != null && entry!.achieved ? theme.colorScheme.onPrimary : null;
    return Tooltip(
      message: entry == null ? '${date.month}/${date.day}　記録なし' : '${date.month}/${date.day}　${entry!.count}問',
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: Text(
          '${date.day}',
          style: theme.textTheme.bodySmall?.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
