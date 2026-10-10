import 'package:flutter/material.dart';

/// 模擬試験の最終結果のシェア用サマリーカード。スクリーンショットでの共有を
/// 想定した見た目（名前・メール等の個人情報は入れない）。`AchievementShareCard`
/// と同じ方針で、OSの共有シート連携は未実装（`share_plus` 等の新規ネイティブ
/// 依存が必要でこのクラウド環境では検証できないため。README参照）。
class MockResultShareCard extends StatelessWidget {
  const MockResultShareCard({
    super.key,
    required this.score,
    required this.max,
    required this.passed,
    required this.date,
    this.examName = 'うかラボ 危険物取扱者乙種',
  });

  final int score;
  final int max;
  final bool passed;
  final DateTime date;

  /// カード上部の試験名表示。選択中の類（例: 「うかラボ 危険物取扱者乙種第4類」）
  /// を渡すと、乙種のどの類の結果かが分かるようになる。未指定なら乙種全体の
  /// 汎用ラベル。
  final String examName;

  double get _pct => max == 0 ? 0 : score * 100 / max;

  String get _dateText => '${date.year}年${date.month}月${date.day}日';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = passed ? scheme.primary : scheme.error;
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent, width: 4),
        ),
        padding: const EdgeInsets.all(24),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(examName, style: theme.textTheme.labelMedium, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Icon(
                  passed ? Icons.emoji_events : Icons.timer_outlined,
                  size: 96,
                  color: accent,
                ),
                const SizedBox(height: 16),
                Text('模擬試験の結果', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  passed ? '合格ライン到達' : '科目の足切りに注意',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$score / $max 問正解（得点率 ${_pct.toStringAsFixed(0)}%）',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
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
