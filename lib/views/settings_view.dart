import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/daily_goal_store.dart';
import '../data/data_backup.dart';
import '../data/data_reset.dart';
import '../data/exam_date_store.dart';
import '../data/progress_store.dart';
import '../data/reminder_settings_store.dart';
import '../data/theme_store.dart';
import 'source_credits_view.dart';

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
    final progress = ref.watch(progressProvider);
    final reminderSettings = ref.watch(reminderSettingsProvider);
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
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                MascotWidget(
                  stage: MasteryModel.standard.stageOf(
                    MasteryInput(coverage: progress.coverage, accuracy: progress.accuracy),
                  ),
                  outfit: ref.watch(equippedOutfitProvider),
                  expression: MascotExpression.normal,
                  display: MascotDisplay.normal,
                  size: 56,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '今のテーマでの推しの見た目のプレビューです。テーマを切り替えると見た目が変わります。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
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
        Text('リマインダー', style: theme.textTheme.titleSmall),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 4),
          child: Text(
            'ホームに表示するアプリ内リマインダーを個別にオフにできます。',
            style: TextStyle(fontSize: 12, height: 1.6),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('学習リマインダー'),
          subtitle: Text('${reminderSettings.studyReminderHour}時以降に今日の目標が未達成なら知らせます'),
          value: reminderSettings.studyReminderEnabled,
          onChanged: (v) => ref.read(reminderSettingsProvider.notifier).setStudyReminderEnabled(v),
        ),
        if (reminderSettings.studyReminderEnabled)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('学習リマインダーの時刻'),
            trailing: DropdownButton<int>(
              value: reminderSettings.studyReminderHour,
              items: [
                for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text('$h時')),
              ],
              onChanged: (h) {
                if (h != null) ref.read(reminderSettingsProvider.notifier).setStudyReminderHour(h);
              },
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('模試リマインダー'),
          subtitle: const Text('前回の模擬試験から7日以上経ったら知らせます'),
          value: reminderSettings.mockReminderEnabled,
          onChanged: (v) => ref.read(reminderSettingsProvider.notifier).setMockReminderEnabled(v),
        ),
        const SizedBox(height: 24),
        Text('データの管理', style: theme.textTheme.titleSmall),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Text(
            '学習記録（解答数・正答率・模試結果・デイリーミッション・苦手問題の復習・'
            '自分用メモ等）は、テーマ・リマインダー設定・試験日・ブックマーク・'
            '用語集のお気に入りを除いて、書き出し・読み込み・リセットができます。',
            style: TextStyle(fontSize: 12, height: 1.6),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('書き出す'),
                onPressed: () => _exportBackup(context, ref),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download_outlined),
                label: const Text('読み込む'),
                onPressed: () => _showImportDialog(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
          icon: const Icon(Icons.delete_outline),
          label: const Text('学習記録をリセット'),
          onPressed: () => _confirmReset(context, ref),
        ),
        const SizedBox(height: 24),
        Text('このアプリについて', style: theme.textTheme.titleSmall),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Text(appDisclaimer, style: TextStyle(fontSize: 12, height: 1.6)),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('問題データの出典（法令）'),
            subtitle: const Text('法令問題が基づいている条文の一覧を確認できます'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SourceCreditsView()),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('学習記録をリセットしますか？'),
        content: const Text('解答数・正答率・模試結果・デイリーミッション・苦手問題の復習等の学習記録が'
            '削除され、元に戻せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('リセットする', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await resetAllLearningData(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('学習記録をリセットしました')),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final jsonText = exportLearningDataJson(ref);
    await Clipboard.setData(ClipboardData(text: jsonText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('学習記録をクリップボードにコピーしました')),
    );
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final jsonText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('学習記録を読み込む'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '書き出した学習記録のJSONテキストを貼り付けてください。'
              '現在の学習記録は上書きされます。',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{ "version": 1, ... }',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('読み込む'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (jsonText == null || jsonText.trim().isEmpty) return;
    try {
      await importLearningDataJson(ref, jsonText);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('学習記録を読み込みました')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('読み込みに失敗しました。正しいバックアップのテキストか確認してください')),
      );
    }
  }
}
