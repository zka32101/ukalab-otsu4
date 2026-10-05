import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/progress_store.dart';
import '../data/srs_store.dart';
import 'weak_review_view.dart';

/// 学習記録。正式な出題範囲（`Question`）の網羅率・正答率はまだ無い
/// （問題データ未着手）ため、`ProgressSnapshot`（演習の解答数）を暫定の
/// 記録として表示する（`lib/data/progress_store.dart`・README参照）。
/// 苦手問題の復習（間隔反復。`lib/data/srs_store.dart`）の状況も表示する。
class RecordView extends ConsumerWidget {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final theme = Theme.of(context);

    if (progress.answered == 0) {
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
