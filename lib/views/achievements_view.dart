import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/achievements.dart';
import '../data/mock_history_store.dart';
import '../data/progress_store.dart';
import '../data/subject_stats_store.dart';

/// 実績バッジの一覧。連続学習日数・解答数・模試合格・分野マスターの
/// 達成状況を一覧表示する（`lib/data/achievements.dart`）。
class AchievementsView extends ConsumerWidget {
  const AchievementsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final mockHistory = ref.watch(mockHistoryProvider);
    final subjectStats = ref.watch(subjectStatsProvider);
    final achievements = buildAchievements(
      answered: progress.answered,
      streakDays: progress.streakDays,
      mockHistory: mockHistory,
      subjectStats: subjectStats,
    );
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return Scaffold(
      appBar: AppBar(title: const Text('実績')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '$unlockedCount / ${achievements.length} 個達成',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          for (final a in achievements) _AchievementTile(achievement: a),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = achievement.unlocked;
    final color = unlocked ? theme.colorScheme.primary : theme.disabledColor;
    return Card(
      child: ListTile(
        leading: Icon(achievement.icon, color: color),
        title: Text(
          achievement.title,
          style: theme.textTheme.titleSmall?.copyWith(color: unlocked ? null : theme.disabledColor),
        ),
        subtitle: Text(
          achievement.description,
          style: theme.textTheme.bodySmall?.copyWith(color: unlocked ? null : theme.disabledColor),
        ),
        trailing: unlocked
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : const Icon(Icons.lock_outline),
      ),
    );
  }
}
