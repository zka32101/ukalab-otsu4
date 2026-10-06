import 'package:flutter/material.dart';

import 'mock_history_store.dart';
import 'subject_stats_store.dart';

/// 実績バッジ1件（達成条件は `buildAchievements` 側で判定済み）。
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
}

/// 連続学習日数のマイルストーン（`record_view.dart` の `streakMilestones` と同じ値）。
const List<int> _streakMilestones = [3, 7, 14, 30, 60, 100, 200, 365];

/// 解答数のマイルストーン。
const List<int> _answeredMilestones = [50, 100, 300, 500];

/// 「分野マスター」とみなす最低解答数・正答率のしきい値。
const _masterMinAnswered = 10;
const _masterAccuracyThreshold = 0.9;

/// 進捗・模試履歴・分野別統計から、実績バッジの一覧（達成状況付き）を作る。
List<Achievement> buildAchievements({
  required int answered,
  required int streakDays,
  required List<MockHistoryEntry> mockHistory,
  required Map<String, SubjectStat> subjectStats,
}) {
  final achievements = <Achievement>[
    for (final d in _streakMilestones)
      Achievement(
        id: 'streak_$d',
        title: '$d日連続学習',
        description: '$d日間、毎日学習を続けた',
        icon: Icons.local_fire_department_outlined,
        unlocked: streakDays >= d,
      ),
    for (final n in _answeredMilestones)
      Achievement(
        id: 'answered_$n',
        title: '$n問解答',
        description: '一問一答・演習で合計$n問に解答した',
        icon: Icons.edit_note_outlined,
        unlocked: answered >= n,
      ),
    Achievement(
      id: 'mock_pass',
      title: '模擬試験合格',
      description: '模擬試験で合格ラインに到達した',
      icon: Icons.school_outlined,
      unlocked: mockHistory.any((e) => e.passed),
    ),
    Achievement(
      id: 'subject_master',
      title: '分野マスター',
      description: 'いずれかの分野で正答率90%以上（10問以上解答）に到達した',
      icon: Icons.verified_outlined,
      unlocked: subjectStats.values.any(
        (s) => s.answered >= _masterMinAnswered && s.accuracy >= _masterAccuracyThreshold,
      ),
    ),
  ];
  return achievements;
}
