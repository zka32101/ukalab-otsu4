import 'package:flutter/material.dart';

import 'mock_history_store.dart';
import 'subject_stats_store.dart';

/// 実績バッジのカテゴリ（一覧画面のタブ分けに使う）。
enum AchievementCategory {
  /// 連続学習日数・デイリーミッションの連続達成。
  streak,

  /// 解答数・コンボ・定着問題数等、演習量に関する実績。
  practice,

  /// 模擬試験の合格・科目別の高得点。
  mock,

  /// 分野別の正答率（分野マスター）。
  subject,
}

/// 実績バッジ1件（達成条件は `buildAchievements` 側で判定済み）。
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    required this.category,
    this.progressText,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
  final AchievementCategory category;

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

/// 一問一答の連続正解数（コンボ）のマイルストーン。
const List<int> _comboMilestones = [5, 10, 20];

/// 苦手問題の復習で定着（箱5）に達した問題数のマイルストーン。
const List<int> _masteredMilestones = [10, 30, 50];

/// デイリーミッションの連続達成日数のマイルストーン。
const List<int> _achievedStreakMilestones = [3, 7, 14];

/// 進捗・模試履歴・分野別統計から、実績バッジの一覧（達成状況付き）を作る。
List<Achievement> buildAchievements({
  required int answered,
  required int streakDays,
  required List<MockHistoryEntry> mockHistory,
  required Map<String, SubjectStat> subjectStats,
  int bestCombo = 0,
  int masteredCount = 0,
  int achievedStreak = 0,
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
        category: AchievementCategory.streak,
        progressText: streakDays >= d ? null : '現在の連続学習日数: $streakDays日 / $d日',
      ),
    for (final n in _answeredMilestones)
      Achievement(
        id: 'answered_$n',
        title: '$n問解答',
        description: '一問一答・演習で合計$n問に解答した',
        icon: Icons.edit_note_outlined,
        unlocked: answered >= n,
        category: AchievementCategory.practice,
        progressText: answered >= n ? null : '現在の解答数: $answered問 / $n問',
      ),
    Achievement(
      id: 'mock_pass',
      title: '模擬試験合格',
      description: '模擬試験で合格ラインに到達した',
      icon: Icons.school_outlined,
      unlocked: mockHistory.any((e) => e.passed),
      category: AchievementCategory.mock,
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
      category: AchievementCategory.subject,
      progressText: bestMasterCandidate != null && bestMasterCandidate >= _masterAccuracyThreshold
          ? null
          : (bestMasterCandidate == null
              ? '10問以上解答した分野がまだありません'
              : '現在の最高正答率: ${(bestMasterCandidate * 100).round()}%（10問以上解答した分野のうち）'),
    ),
    for (final n in _comboMilestones)
      Achievement(
        id: 'combo_$n',
        title: '$n問連続正解',
        description: '一問一答で$n問連続して正解した',
        icon: Icons.local_fire_department_outlined,
        unlocked: bestCombo >= n,
        category: AchievementCategory.practice,
        progressText: bestCombo >= n ? null : '自己最高の連続正解数: $bestCombo問 / $n問',
      ),
    for (final n in _masteredMilestones)
      Achievement(
        id: 'mastered_$n',
        title: '定着問題$n問',
        description: '苦手問題の復習で、$n問を定着（箱5）まで育てた',
        icon: Icons.auto_awesome_outlined,
        unlocked: masteredCount >= n,
        category: AchievementCategory.practice,
        progressText: masteredCount >= n ? null : '現在の定着問題数: $masteredCount問 / $n問',
      ),
    for (final n in _achievedStreakMilestones)
      Achievement(
        id: 'achieved_streak_$n',
        title: '目標達成$n日連続',
        description: 'デイリーミッションの目標を$n日連続で達成した',
        icon: Icons.flag_outlined,
        unlocked: achievedStreak >= n,
        category: AchievementCategory.streak,
        progressText: achievedStreak >= n ? null : '現在の連続達成日数: $achievedStreak日 / $n日',
      ),
    Achievement(
      id: 'mock_all_subjects_80',
      title: '全科目80%以上',
      description: '模擬試験で、科目別データがある全ての科目の得点率80%以上を同じ回で達成した',
      icon: Icons.workspace_premium_outlined,
      unlocked: _anyMockAllSubjects80(mockHistory),
      category: AchievementCategory.mock,
      progressText: _anyMockAllSubjects80(mockHistory)
          ? null
          : (mockHistory.any((e) => e.subjectScore != null)
              ? '科目別データがある模試はまだ全科目80%以上に届いていません'
              : '科目別データがある模試の受験履歴がまだありません'),
    ),
  ];
  return achievements;
}

/// 科目別データがある模試のうち、いずれかの回ですべての科目の得点率が
/// 80%以上だったかどうか。科目別データが無い回（旧形式の記録等）は対象外。
bool _anyMockAllSubjects80(List<MockHistoryEntry> mockHistory) {
  for (final e in mockHistory) {
    final scores = e.subjectScore;
    if (scores == null || scores.isEmpty) continue;
    final allAbove80 = scores.keys.every((subjectId) {
      final pct = e.subjectPct(subjectId);
      return pct != null && pct >= 80;
    });
    if (allAbove80) return true;
  }
  return false;
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
