import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/exam_repository.dart';
import '../data/mock_history_store.dart';
import '../data/progress_store.dart';
import '../data/srs_store.dart';
import '../data/subject_stats_store.dart';
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                  if (dueCount > 0) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WeakReviewView()),
                      ),
                      child: const Text('復習する'),
                    ),
                  ],
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
