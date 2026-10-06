import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/daily_goal_store.dart';
import '../data/exam_date_store.dart';
import '../data/theme_store.dart';

/// 免責表示（うかラボ共通方針）。ストア説明文の冒頭の注意書きと趣旨を揃える。
const String appDisclaimer =
    '本アプリは、消防試験研究センター等の危険物取扱者試験の実施団体・主催者とは一切関係のない、'
    'Your Wish が制作した非公式の学習アプリです。\n'
    '試験名は、学習の対象を示すためにのみ使用しています。問題・解説は独自に作成したもので、'
    '実際の試験の出題内容や合格を保証するものではありません。\n'
    '最新の試験情報は、実施団体の公式サイトでご確認ください。';

/// デイリーミッションで選べる目標問題数。
const List<int> dailyGoalChoices = [10, 20, 30];

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final target = ref.watch(dailyGoalProvider).target;
    final themeMode = ref.watch(themeModeProvider);
    final examDate = ref.watch(examDateProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('テーマ', style: theme.textTheme.titleSmall),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Text(
            '画面の明るさを選べます。',
            style: TextStyle(fontSize: 12, height: 1.6),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('端末に合わせる'),
              selected: themeMode == ThemeMode.system,
              onSelected: (_) => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
            ),
            ChoiceChip(
              label: const Text('ライト'),
              selected: themeMode == ThemeMode.light,
              onSelected: (_) => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
            ),
            ChoiceChip(
              label: const Text('ダーク'),
              selected: themeMode == ThemeMode.dark,
              onSelected: (_) => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('デイリーミッション', style: theme.textTheme.titleSmall),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Text(
            '1日の目標問題数を決めて、学ぶタブで達成状況を確認できます。',
            style: TextStyle(fontSize: 12, height: 1.6),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('オフ'),
              selected: target == null,
              onSelected: (_) => ref.read(dailyGoalProvider.notifier).setTarget(null),
            ),
            for (final n in dailyGoalChoices)
              ChoiceChip(
                label: Text('$n問/日'),
                selected: target == n,
                onSelected: (_) => ref.read(dailyGoalProvider.notifier).setTarget(n),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('試験日', style: theme.textTheme.titleSmall),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Text(
            '本番の日付を設定すると、ホームに残り日数が表示されます。',
            style: TextStyle(fontSize: 12, height: 1.6),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: examDate ?? now,
                    firstDate: now.subtract(const Duration(days: 1)),
                    lastDate: now.add(const Duration(days: 730)),
                  );
                  if (picked != null) {
                    ref.read(examDateProvider.notifier).setDate(picked);
                  }
                },
                child: Text(
                  examDate == null
                      ? '試験日を設定'
                      : '${examDate.year}/${examDate.month}/${examDate.day}',
                ),
              ),
            ),
            if (examDate != null) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: '試験日の設定を解除',
                onPressed: () => ref.read(examDateProvider.notifier).setDate(null),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Text('このアプリについて', style: theme.textTheme.titleSmall),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 24),
          child: Text(appDisclaimer, style: TextStyle(fontSize: 12, height: 1.6)),
        ),
      ],
    );
  }
}
