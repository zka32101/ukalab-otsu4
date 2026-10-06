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
    this.progressText,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;

  /// 未解除のバッジをタップしたときに見せる、現在の進捗状況の説明。
  /// 解除済みのバッジ、または進捗を数値で示せないバッジでは null。
  final String? progressText;
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
  final bestMasterCandidate = _bestMasterCandidate(subjectStats);
  final achievements = <Achievement>[
    for (final d in _streakMilestones)
      Achievement(
        id: 'streak_$d',
        title: '$d日連続学習',
        description: '$d日間、毎日学習を続けた',
        icon: Icons.local_fire_department_outlined,
        unlocked: streakDays >= d,
        progressText: streakDays >= d ? null : '現在の連続学習日数: $streakDays日 / $d日',
      ),
    for (final n in _answeredMilestones)
      Achievement(
        id: 'answered_$n',
        title: '$n問解答',
        description: '一問一答・演習で合計$n問に解答した',
        icon: Icons.edit_note_outlined,
        unlocked: answered >= n,
        progressText: answered >= n ? null : '現在の解答数: $answered問 / $n問',
      ),
    Achievement(
      id: 'mock_pass',
      title: '模擬試験合格',
      description: '模擬試験で合格ラインに到達した',
      icon: Icons.school_outlined,
      unlocked: mockHistory.any((e) => e.passed),
      progressText: mockHistory.any((e) => e.passed)
          ? null
          : (mockHistory.isEmpty ? '模擬試験の受験履歴がまだありません' : '直近の模試はまだ合格ラインに届いていません'),
    ),
    Achievement(
      id: 'subject_master',
      title: '分野マスター',
      description: 'いずれかの分野で正答率90%以上（10問以上解答）に到達した',
      icon: Icons.verified_outlined,
      unlocked: bestMasterCandidate != null && bestMasterCandidate >= _masterAccuracyThreshold,
      progressText: bestMasterCandidate != null && bestMasterCandidate >= _masterAccuracyThreshold
          ? null
          : (bestMasterCandidate == null
              ? '10問以上解答した分野がまだありません'
              : '現在の最高正答率: ${(bestMasterCandidate * 100).round()}%（10問以上解答した分野のうち）'),
    ),
  ];
  return achievements;
}

/// 10問以上解答した分野のうち、最も正答率が高い値。対象の分野が無ければ null。
double? _bestMasterCandidate(Map<String, SubjectStat> subjectStats) {
  double? best;
  for (final s in subjectStats.values) {
    if (s.answered < _masterMinAnswered) continue;
    if (best == null || s.accuracy > best) best = s.accuracy;
  }
  return best;
}
