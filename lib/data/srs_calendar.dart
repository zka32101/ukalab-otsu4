import 'package:yourwish_kentei/yourwish_kentei.dart';

/// 復習予定を日付（時刻を切り捨てた日単位）ごとにグループ化した件数。
/// 期限切れ（[now] より前）の項目はすべて「今日」としてまとめる。
/// [days] 日先（今日を含む）までを対象にする。
Map<DateTime, int> srsReviewCountsByDate(
  Iterable<SrsItem> items,
  DateTime now, {
  int days = 14,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final limit = today.add(Duration(days: days - 1));
  final counts = <DateTime, int>{};
  for (final item in items) {
    final due = DateTime(item.dueAt.year, item.dueAt.month, item.dueAt.day);
    final bucket = due.isBefore(today) ? today : due;
    if (bucket.isAfter(limit)) continue;
    counts[bucket] = (counts[bucket] ?? 0) + 1;
  }
  return counts;
}
