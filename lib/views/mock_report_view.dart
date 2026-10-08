import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exam_repository.dart';
import '../data/mock_history_store.dart';
import '../data/subject_stats_store.dart';
import 'focus_training_view.dart';
import 'record_view.dart'
    show MockHistoryRow, MockScoreTrendChart, PassPredictionRow, SubjectStatRow, orderedSubjectsWithId;

/// 模試結果の推移をまとめて見る成績レポート。記録タブでは直近5回までしか
/// 表示しない模試結果を、受験回数・合格回数・平均/自己最高得点率とともに
/// 全件確認できる（`lib/views/record_view.dart` の表示部品を再利用）。
/// 得点率の推移は、総合に加えて科目別にも切り替えて見られる（`null` が総合）。
/// 科目別データは `MockHistoryEntry.subjectScore`/`subjectMax` を追加する前の
/// 模試結果には無く、その回はグラフから除かれる。
class MockReportView extends ConsumerStatefulWidget {
  const MockReportView({super.key});

  @override
  ConsumerState<MockReportView> createState() => _MockReportViewState();
}

class _MockReportViewState extends ConsumerState<MockReportView> {
  String? _selectedSubject;

  @override
  Widget build(BuildContext context) {
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
    final subjects = [...?exam?.subjects]..sort((a, b) => a.order.compareTo(b.order));
    final selectedSubject = _selectedSubject;
    final trendSeries = selectedSubject == null
        ? [for (final e in mockHistory) e.pct / 100]
        : [
            for (final e in mockHistory)
              if (e.subjectPct(selectedSubject) != null) e.subjectPct(selectedSubject)! / 100,
          ];
    final trendTitle = selectedSubject == null
        ? '得点率の推移（総合）'
        : '得点率の推移（${subjects.firstWhere((s) => s.subjectId == selectedSubject).name}）';

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
                    if (subjects.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ChoiceChip(
                            label: const Text('総合'),
                            selected: selectedSubject == null,
                            onSelected: (_) => setState(() => _selectedSubject = null),
                          ),
                          for (final s in subjects)
                            ChoiceChip(
                              label: Text(s.name),
                              selected: selectedSubject == s.subjectId,
                              onSelected: (_) => setState(() => _selectedSubject = s.subjectId),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (trendSeries.length > 1)
                      MockScoreTrendChart(series: trendSeries, title: trendTitle)
                    else
                      Text('この科目のデータが揃った回がまだ2回未満です。', style: theme.textTheme.bodySmall),
                    if (exam != null) ...[
                      const SizedBox(height: 8),
                      PassPredictionRow(
                        history: mockHistory,
                        passPct: selectedSubject == null
                            ? exam.levels.first.passRule.totalPct
                            : exam.levels.first.passRule.subjectMinPct ??
                                exam.levels.first.passRule.totalPct,
                        subjectId: selectedSubject,
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
                      '直近の模試に限らず、これまでの演習全体の正答率です。タップするとその分野を演習できます',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    for (final s in orderedSubjectsWithId(exam, subjectStats))
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FocusTrainingView(subjectId: s.$1, subjectName: s.$2),
                          ),
                        ),
                        child: SubjectStatRow(label: s.$2, stat: s.$3),
                      ),
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
