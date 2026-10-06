import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/achievements.dart';
import '../data/daily_goal_history_store.dart';
import '../data/exam_repository.dart';
import '../data/mock_history_store.dart';
import '../data/progress_store.dart';
import '../data/srs_store.dart';
import '../data/subject_stats_history_store.dart';
import '../data/subject_stats_store.dart';
import 'achievements_view.dart';
import 'focus_training_view.dart';
import 'srs_calendar_view.dart';
import 'weak_review_view.dart';

/// 学習記録。正式な出題範囲（`Question`）の網羅率・正答率はまだ無い
/// （問題データ未着手）ため、`ProgressSnapshot`（演習の解答数）を暫定の
/// 記録として表示する（`lib/data/progress_store.dart`・README参照）。
/// 苦手問題の復習（間隔反復。`lib/data/srs_store.dart`）の状況と、
/// 模擬試験の結果履歴（`lib/data/mock_history_store.dart`）も表示する。
class RecordView extends ConsumerWidget {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final theme = Theme.of(context);
    final mockHistory = ref.watch(mockHistoryProvider);
    final subjectStats = ref.watch(subjectStatsProvider);
    final subjectStatsHistory = ref.watch(subjectStatsHistoryProvider);
    final dailyGoalHistory = ref.watch(dailyGoalHistoryProvider);
    final exam = ref.watch(examConfigProvider).valueOrNull;

    if (progress.answered == 0 && mockHistory.isEmpty) {
      return const EmptyState(
        message: '学習記録はまだありません。学ぶタブの演習から始めましょう。',
        icon: Icons.insights_outlined,
      );
    }

    final srs = ref.watch(srsProvider);
    final dueCount = ref.watch(dueWeakQidsProvider).length;
    final masteredCount = srs.values.where((i) => i.box == Srs.maxBox).length;
    final achievements = buildAchievements(
      answered: progress.answered,
      streakDays: progress.streakDays,
      mockHistory: mockHistory,
      subjectStats: subjectStats,
    );
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text('実績（$unlockedCount / ${achievements.length}）'),
            subtitle: const Text('連続学習日数・解答数・模試合格等のバッジを確認できます'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AchievementsView()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (progress.answered > 0) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('これまでの演習', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  _StatRow(label: '解答数', value: '${progress.answered}問'),
                  _StatRow(label: '正解数', value: '${progress.correct}問'),
                  _StatRow(
                    label: '正答率',
                    value: '${(progress.accuracy * 100).round()}%',
                  ),
                  _StatRow(label: '連続学習日数', value: '${progress.streakDays}日'),
                  if (latestStreakMilestone(progress.streakDays) != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${latestStreakMilestone(progress.streakDays)}日連続達成！',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (dailyGoalHistory.length > 1) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('デイリーミッションの達成履歴', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '直近${dailyGoalHistory.length}日分の記録です',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _DailyGoalHistoryChart(history: dailyGoalHistory),
                ],
              ),
            ),
          ),
        ],
        if (srs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('苦手問題の復習', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  _StatRow(label: '間違えて記録中の問題', value: '${srs.length}問'),
                  _StatRow(label: '復習待ち', value: '$dueCount問'),
                  _StatRow(label: '定着した問題', value: '$masteredCount問'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (dueCount > 0) ...[
                        FilledButton.tonal(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const WeakReviewView()),
                          ),
                          child: const Text('復習する'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SrsCalendarView()),
                        ),
                        child: const Text('復習カレンダー'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        if (mockHistory.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('模擬試験の結果', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  for (final entry in mockHistory.reversed.take(5)) _MockHistoryRow(entry: entry),
                  if (mockHistory.length > 1) ...[
                    const SizedBox(height: 12),
                    _MockScoreTrendChart(
                      series: [for (final e in mockHistory) e.pct / 100],
                    ),
                  ],
                  if (mockHistory.length > 1 && exam != null) ...[
                    const SizedBox(height: 8),
                    _PassPredictionRow(
                      history: mockHistory,
                      passPct: exam.levels.first.passRule.totalPct,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (subjectStats.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('分野別の正答率', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  for (final s in _orderedSubjects(exam, subjectStats))
                    _SubjectStatRow(label: s.$1, stat: s.$2),
                ],
              ),
            ),
          ),
        ],
        if (subjectStats.length > 1) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('弱点マップ', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '正答率が低い分野から順に並べています。タップするとその分野を演習できます',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  for (final s in sortedByWeaknessWithId(exam, subjectStats))
                    _WeakMapBar(
                      label: s.$2,
                      stat: s.$3,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FocusTrainingView(subjectId: s.$1, subjectName: s.$2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (subjectStatsHistory.length > 1) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('分野別正答率の推移', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '直近${subjectStatsHistory.length}日分の記録です',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  for (final s in _orderedSubjectIdsAndNames(exam, subjectStats))
                    _SubjectTrendRow(
                      label: s.$2,
                      series: [
                        for (final e in subjectStatsHistory) e.accuracyBySubject[s.$1] ?? 0,
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          '一問一答・画期的な機能（温度の実験室・貯蔵所パズル・消火マッチング・'
          '違反探しモード・現場の1日）の解答を合計した、暫定の記録です。'
          '正式な出題範囲の問題データが入ったら、科目別の網羅率・正答率に切り替わります。',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// 模擬試験の結果1回分の行。日時・得点率・合否を表示する。
class _MockHistoryRow extends StatelessWidget {
  const _MockHistoryRow({required this.entry});

  final MockHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final at = entry.at;
    final dateText =
        '${at.year}/${at.month.toString().padLeft(2, '0')}/${at.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            entry.passed ? Icons.check_circle : Icons.cancel_outlined,
            color: entry.passed ? theme.colorScheme.primary : theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(dateText, style: theme.textTheme.bodyMedium)),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (entry.pct / 100).clamp(0, 1),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.score}/${entry.max}（${entry.pct.round()}%）',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// デイリーミッションの達成履歴。古い順に、その日の解答数を目標達成の有無で
/// 色分けした横棒で表示する（復習カレンダーと同じ横棒の表現を使う）。
class _DailyGoalHistoryChart extends StatelessWidget {
  const _DailyGoalHistoryChart({required this.history});

  final List<DailyGoalHistoryEntry> history;

  static const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = history.map((e) => e.count).fold<int>(0, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final entry in history)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    '${entry.date.month}/${entry.date.day}'
                    '（${_weekdayLabels[entry.date.weekday - 1]}）',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        if (maxCount > 0 && entry.count > 0)
                          Container(
                            height: 14,
                            width: constraints.maxWidth * (entry.count / maxCount).clamp(0.08, 1.0),
                            decoration: BoxDecoration(
                              color: entry.achieved ? theme.colorScheme.primary : theme.colorScheme.outline,
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
                    '${entry.count}問',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 模擬試験の得点率の推移。古い順の得点率（0.0〜1.0）を折れ線グラフで表示する。
class _MockScoreTrendChart extends StatelessWidget {
  const _MockScoreTrendChart({required this.series});

  final List<double> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('得点率の推移', style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: CustomPaint(
            size: const Size(double.infinity, 48),
            painter: _TrendPainter(series: series, color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

/// 模試の合格ライン到達見込み1行。直近の傾向に応じたアイコン・メッセージを表示する。
class _PassPredictionRow extends StatelessWidget {
  const _PassPredictionRow({required this.history, required this.passPct});

  final List<MockHistoryEntry> history;
  final double passPct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prediction = predictPassTrend(history, passPct: passPct);
    final (icon, text, color) = switch (prediction) {
      PassPrediction.onTrack => (
          Icons.check_circle_outline,
          '直近の平均が合格ラインに達しています。この調子で続けましょう',
          theme.colorScheme.primary,
        ),
      PassPrediction.closeToTarget => (
          Icons.trending_up,
          'もう少しで合格ラインに届きそうです',
          theme.colorScheme.secondary,
        ),
      PassPrediction.needsWork => (
          Icons.priority_high,
          'まだ合格ラインまで距離があります。苦手分野の復習がおすすめです',
          theme.colorScheme.error,
        ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color))),
      ],
    );
  }
}

/// 連続学習日数のマイルストーン（節目）。
const List<int> streakMilestones = [3, 7, 14, 30, 60, 100, 200, 365];

/// 現在の連続学習日数が到達している、最も大きいマイルストーン。
/// どれにも達していなければ null。
int? latestStreakMilestone(int streakDays) {
  int? latest;
  for (final d in streakMilestones) {
    if (streakDays >= d) latest = d;
  }
  return latest;
}

/// データがある分野だけ、`ExamConfig` の並び順で（名前, 統計）を返す。
/// `exam` が未取得（読み込み中）なら subjectId をそのまま名前にする。
List<(String, SubjectStat)> _orderedSubjects(ExamConfig? exam, Map<String, SubjectStat> stats) {
  if (exam == null) {
    return [for (final e in stats.entries) (e.key, e.value)];
  }
  final subjects = [...exam.subjects]..sort((a, b) => a.order.compareTo(b.order));
  return [
    for (final s in subjects)
      if (stats.containsKey(s.subjectId)) (s.name, stats[s.subjectId]!),
  ];
}

/// データがある分野だけ、`ExamConfig` の並び順で（subjectId, 名前）を返す
/// （「分野別正答率の推移」用。履歴のキーは subjectId のため）。
List<(String, String)> _orderedSubjectIdsAndNames(ExamConfig? exam, Map<String, SubjectStat> stats) {
  if (exam == null) {
    return [for (final id in stats.keys) (id, id)];
  }
  final subjects = [...exam.subjects]..sort((a, b) => a.order.compareTo(b.order));
  return [
    for (final s in subjects)
      if (stats.containsKey(s.subjectId)) (s.subjectId, s.name),
  ];
}

/// 分野別正答率の推移1行。分野名・最新の正答率・折れ線の推移を表示する。
class _SubjectTrendRow extends StatelessWidget {
  const _SubjectTrendRow({required this.label, required this.series});

  final String label;
  final List<double> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = series.isEmpty ? 0.0 : series.last;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text('${(latest * 100).round()}%', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: CustomPaint(
              size: const Size(double.infinity, 36),
              painter: _TrendPainter(series: series, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// 折れ線グラフの描画。series は古い順の正答率（0.0〜1.0）。
class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.series, required this.color});

  final List<double> series;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    final dx = size.width / (series.length - 1);
    for (var i = 0; i < series.length; i++) {
      final x = dx * i;
      final y = size.height * (1 - series[i].clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.color != color;
}

/// データがある分野を、正答率が低い順に（名前, 統計）で返す
/// （「弱点マップ」用）。`exam` が未取得なら subjectId をそのまま名前にする。
List<(String, SubjectStat)> sortedByWeakness(ExamConfig? exam, Map<String, SubjectStat> stats) {
  final named = exam == null
      ? [for (final e in stats.entries) (e.key, e.value)]
      : _orderedSubjects(exam, stats);
  return [...named]..sort((a, b) => a.$2.accuracy.compareTo(b.$2.accuracy));
}

/// データがある分野を、正答率が低い順に（subjectId, 名前, 統計）で返す
/// （「弱点マップ」タップでその分野の演習に遷移するためsubjectIdも保持する）。
/// `exam` が未取得なら subjectId をそのまま名前にする。
List<(String, String, SubjectStat)> sortedByWeaknessWithId(
  ExamConfig? exam,
  Map<String, SubjectStat> stats,
) {
  final List<(String, String, SubjectStat)> named;
  if (exam == null) {
    named = [for (final e in stats.entries) (e.key, e.key, e.value)];
  } else {
    final subjects = [...exam.subjects]..sort((a, b) => a.order.compareTo(b.order));
    named = [
      for (final s in subjects)
        if (stats.containsKey(s.subjectId)) (s.subjectId, s.name, stats[s.subjectId]!),
    ];
  }
  return [...named]..sort((a, b) => a.$3.accuracy.compareTo(b.$3.accuracy));
}

/// 弱点マップの1行。正答率に応じて色を変えた横棒グラフ。タップでその分野の
/// 演習に遷移する。
class _WeakMapBar extends StatelessWidget {
  const _WeakMapBar({required this.label, required this.stat, required this.onTap});

  final String label;
  final SubjectStat stat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = stat.accuracy < weakSubjectAccuracyThreshold
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                Row(
                  children: [
                    Text(
                      '${(stat.accuracy * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 8,
                    width: constraints.maxWidth * stat.accuracy.clamp(0, 1),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分野別の正答率1行。解答数・正答率バーを表示する。
class _SubjectStatRow extends StatelessWidget {
  const _SubjectStatRow({required this.label, required this.stat});

  final String label;
  final SubjectStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: stat.accuracy, minHeight: 8),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${stat.correct}/${stat.answered}（${(stat.accuracy * 100).round()}%）',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
