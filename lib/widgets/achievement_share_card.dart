import 'package:flutter/material.dart';

import '../data/achievements.dart';

/// 実績バッジの達成カード。スクリーンショットでの共有を想定した見た目
/// （名前・メール等の個人情報は入れない）。OSの共有シート連携は
/// `share_plus` 等の新規ネイティブ依存が必要でこのクラウド環境では
/// 検証できないため、このセッションでは見た目のプレビューのみを実装する
/// （`app_common_kit` の合格報告カードも、このアプリでは同様に共有シートへは
/// 未接続。README参照）。
class AchievementShareCard extends StatelessWidget {
  const AchievementShareCard({super.key, required this.achievement, required this.date});

  final Achievement achievement;
  final DateTime date;

  String get _dateText => '${date.year}年${date.month}月${date.day}日';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.primary, width: 4),
        ),
        padding: const EdgeInsets.all(24),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('うかラボ 危険物取扱者乙種第4類', style: theme.textTheme.labelMedium, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Icon(achievement.icon, size: 96, color: scheme.primary),
                const SizedBox(height: 16),
                Text('実績解除', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  achievement.title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(achievement.description, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(_dateText, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
