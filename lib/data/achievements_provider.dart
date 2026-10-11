import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/achievements.dart' as core;
import 'package:ukalab_core/ukalab_core.dart';

import 'achievements.dart';
import 'combo_store.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'mock_history_store.dart';
import 'progress_store.dart';
import 'srs_store.dart';
import 'subject_stats_store.dart';

/// 実績バッジの一覧（達成状況付き）。実績一覧画面・解除通知の両方で使う
/// 共通の算出ロジック（`buildAchievements`、`lib/data/achievements.dart`）。
final achievementsOverride = core.achievementsProvider.overrideWith((ref) {
  final progress = ref.watch(progressProvider);
  final mockHistory = ref.watch(mockHistoryProvider);
  final subjectStats = ref.watch(subjectStatsProvider);
  final srs = ref.watch(srsProvider);
  final masteredCount = srs.values.where((i) => i.box == Srs.maxBox).length;
  final bestCombo = ref.watch(comboProvider);
  final achievedStreak = effectiveAchievedStreak(ref.watch(dailyGoalProvider), DateTime.now());
  return buildAchievements(
    answered: progress.answered,
    streakDays: progress.streakDays,
    mockHistory: mockHistory,
    subjectStats: subjectStats,
    bestCombo: bestCombo,
    masteredCount: masteredCount,
    achievedStreak: achievedStreak,
  );
});
