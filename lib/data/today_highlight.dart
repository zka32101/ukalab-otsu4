import 'package:ukalab_core/achievements.dart';

import 'daily_answer_stats_store.dart';

/// 設定タブの「本日の学習ハイライト」カードに表示する内容。
class TodayHighlight {
  const TodayHighlight({required this.answered, required this.correct, required this.unlockedTitles});

  final int answered;
  final int correct;

  /// 今日解除された実績バッジのタイトル（解除順）。
  final List<String> unlockedTitles;

  double get accuracy => answered == 0 ? 0 : correct / answered;

  /// 今日まだ何も学習していない（解答もバッジ解除も無い）か。
  bool get isEmpty => answered == 0 && unlockedTitles.isEmpty;
}

/// [now] と同じ日付の [dailyAnswerStats] のエントリ、及び同じ日付に
/// [unlockedAt] に記録された実績バッジ（[achievements] から名前を引く）から
/// 「本日の学習ハイライト」を作る。
TodayHighlight buildTodayHighlight({
  required List<DailyAnswerStatsEntry> dailyAnswerStats,
  required List<Achievement> achievements,
  required Map<String, DateTime> unlockedAt,
  required DateTime now,
}) {
  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  final todayEntries = dailyAnswerStats.where((e) => isSameDay(e.date, now));
  final todayEntry = todayEntries.isEmpty ? null : todayEntries.first;
  final unlockedTitles = [
    for (final a in achievements)
      if (unlockedAt[a.id] != null && isSameDay(unlockedAt[a.id]!, now)) a.title,
  ];
  return TodayHighlight(
    answered: todayEntry?.answered ?? 0,
    correct: todayEntry?.correct ?? 0,
    unlockedTitles: unlockedTitles,
  );
}
