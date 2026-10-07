import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/daily_goal_history_store.dart';
import '../data/streak_calendar.dart';

/// 連続学習日数のカレンダー表示。月単位でページ送りして、目標を達成した日・
/// 解答はしたが未達成の日・記録が無い日を色分けして見える化する
/// （`lib/data/streak_calendar.dart`）。記録タブの「連続学習日数」から開く。
/// 記録の保存件数には上限（直近30日分）があるため、それより前の月は
/// 「記録なし」の表示になる。
class StreakCalendarView extends ConsumerStatefulWidget {
  const StreakCalendarView({super.key});

  @override
  ConsumerState<StreakCalendarView> createState() => _StreakCalendarViewState();
}

class _StreakCalendarViewState extends ConsumerState<StreakCalendarView> {
  static const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  int _monthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = ref.watch(dailyGoalHistoryProvider);
    final now = DateTime.now();
    final displayedMonth = addMonths(DateTime(now.year, now.month, 1), _monthOffset);
    final monthDays = monthCalendarDays(history, displayedMonth);
    final leadingEmptyCount = displayedMonth.weekday - 1;
    final canGoNext = _monthOffset < 0;

    final cells = <Widget>[
      for (var i = 0; i < leadingEmptyCount; i++) const SizedBox.shrink(),
      for (var i = 0; i < monthDays.length; i++)
        _StreakDayCell(date: displayedMonth.add(Duration(days: i)), entry: monthDays[i]),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: '前の月',
                      onPressed: () => setState(() => _monthOffset -= 1),
                    ),
                    Text('${displayedMonth.year}年${displayedMonth.month}月', style: theme.textTheme.titleSmall),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: '次の月',
                      onPressed: canGoNext ? () => setState(() => _monthOffset += 1) : null,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
                const SizedBox(height: 8),
                Text(
                  '記録の保存件数には上限（直近30日分）があり、それより前の月は「記録なし」と表示されます。',
                  style: theme.textTheme.bodySmall,
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
