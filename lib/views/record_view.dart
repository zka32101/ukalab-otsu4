import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_store.dart';

/// 学習記録。正式な出題範囲（`Question`）の網羅率・正答率はまだ無い
/// （問題データ未着手）ため、`ProgressSnapshot`（演習の解答数）を暫定の
/// 記録として表示する（`lib/data/progress_store.dart`・README参照）。
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
