import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exam_repository.dart';
import '../data/mock_history_store.dart';
import '../data/subject_stats_store.dart';
import 'record_view.dart'
    show MockHistoryRow, MockScoreTrendChart, PassPredictionRow, SubjectStatRow, orderedSubjects;

/// 模試結果の推移をまとめて見る成績レポート。記録タブでは直近5回までしか
/// 表示しない模試結果を、受験回数・合格回数・平均/自己最高得点率とともに
/// 全件確認できる（`lib/views/record_view.dart` の表示部品を再利用）。
class MockReportView extends ConsumerWidget {
  const MockReportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mockHistory = ref.watch(mockHistoryProvider);
    final subjectStats = ref.watch(subjectStatsProvider);
    final exam = ref.watch(examConfigProvider).valueOrNull;

    if (mockHistory.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('成績レポート')),
        body: const EmptyState(
          message: '模擬試験を受けると、ここに成績の推移がまとまります。',
          icon: Icons.insights_outlined,
        ),
      );
    }

    final passCount = mockHistory.where((e) => e.passed).length;
    final avgPct = mockHistory.map((e) => e.pct).reduce((a, b) => a + b) / mockHistory.length;
    final bestPct = mockHistory.map((e) => e.pct).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('成績レポート')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('概要', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  _ReportStatRow(label: '受験回数', value: '${mockHistory.length}回'),
                  _ReportStatRow(label: '合格回数', value: '$passCount回'),
                  _ReportStatRow(label: '平均得点率', value: '${avgPct.round()}%'),
                  _ReportStatRow(label: '自己最高得点率', value: '${bestPct.round()}%'),
                ],
              ),
            ),
          ),
          if (mockHistory.length > 1) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MockScoreTrendChart(series: [for (final e in mockHistory) e.pct / 100]),
                    if (exam != null) ...[
                      const SizedBox(height: 8),
                      PassPredictionRow(
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
                    Text('現在の分野別正答率', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      '直近の模試に限らず、これまでの演習全体の正答率です',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    for (final s in orderedSubjects(exam, subjectStats))
                      SubjectStatRow(label: s.$1, stat: s.$2),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('受験履歴（全${mockHistory.length}回）', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  for (final entry in mockHistory.reversed) MockHistoryRow(entry: entry),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportStatRow extends StatelessWidget {
  const _ReportStatRow({required this.label, required this.value});

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
