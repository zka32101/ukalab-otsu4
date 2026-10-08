import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/achievements.dart';
import '../data/achievements_provider.dart';
import '../widgets/achievement_share_card.dart';

/// カテゴリタブの表示名（「すべて」はnull）。
const _categoryTabs = <AchievementCategory?, String>{
  null: 'すべて',
  AchievementCategory.streak: '学習継続',
  AchievementCategory.practice: '解答数',
  AchievementCategory.mock: '模試',
  AchievementCategory.subject: '分野マスター',
};

/// 実績バッジの一覧。連続学習日数・解答数・模試合格・分野マスターの
/// 達成状況を、カテゴリ別タブで切り替えて一覧表示する
/// （`lib/data/achievements.dart`）。
class AchievementsView extends ConsumerStatefulWidget {
  const AchievementsView({super.key});

  @override
  ConsumerState<AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends ConsumerState<AchievementsView> {
  AchievementCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementsProvider);
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final category = _selectedCategory;
    final filtered = category == null
        ? achievements
        : [for (final a in achievements) if (a.category == category) a];

    return Scaffold(
      appBar: AppBar(title: const Text('実績')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '$unlockedCount / ${achievements.length} 個達成',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final entry in _categoryTabs.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _selectedCategory == entry.key,
                  onSelected: (_) => setState(() => _selectedCategory = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final a in filtered) _AchievementTile(achievement: a),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final Achievement achievement;

  void _showDetail(BuildContext context) {
    final a = achievement;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(a.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.description),
            if (a.progressText != null) ...[
              const SizedBox(height: 12),
              Text(a.progressText!, style: Theme.of(context).textTheme.bodySmall),
            ] else if (a.unlocked) ...[
              const SizedBox(height: 12),
              Text('達成済みです。', style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
        actions: [
          if (a.unlocked)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showShareCard(context);
              },
              child: const Text('達成カードを見る'),
            ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる')),
        ],
      ),
    );
  }

  void _showShareCard(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AchievementShareCard(achievement: achievement, date: DateTime.now()),
              const SizedBox(height: 12),
              Text(
                'スクリーンショットで共有できます。カードに名前などの個人情報は入りません。',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = achievement.unlocked;
    final color = unlocked ? theme.colorScheme.primary : theme.disabledColor;
    return Card(
      child: ListTile(
        onTap: () => _showDetail(context),
        leading: Icon(achievement.icon, color: color),
        title: Text(
          achievement.title,
          style: theme.textTheme.titleSmall?.copyWith(color: unlocked ? null : theme.disabledColor),
        ),
        subtitle: Text(
          achievement.description,
          style: theme.textTheme.bodySmall?.copyWith(color: unlocked ? null : theme.disabledColor),
        ),
        trailing: unlocked
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : const Icon(Icons.lock_outline),
      ),
    );
  }
}
