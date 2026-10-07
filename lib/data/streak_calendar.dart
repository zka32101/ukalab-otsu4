import 'daily_goal_history_store.dart';

/// 直近[days]日分の学習記録を、古い日から新しい日の順で返す（カレンダー表示用）。
/// [history] に記録が無い日（保存件数の上限を超えて切り捨てられた日・未学習の日）
/// は null になる。
List<DailyGoalHistoryEntry?> streakCalendarDays(
  List<DailyGoalHistoryEntry> history,
  DateTime now, {
  int days = 28,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final byDate = {for (final e in history) e.date: e};
  return [
    for (var i = days - 1; i >= 0; i--) byDate[today.subtract(Duration(days: i))],
  ];
}

/// [monthAnchor] と同じ年月の、1日から月末までの学習記録を日付順に返す
/// （学習カレンダーの月表示用）。記録が無い日は null になる。
List<DailyGoalHistoryEntry?> monthCalendarDays(
  List<DailyGoalHistoryEntry> history,
  DateTime monthAnchor,
) {
  final byDate = {for (final e in history) e.date: e};
  final firstDay = DateTime(monthAnchor.year, monthAnchor.month, 1);
  final daysInMonth = DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
  return [
    for (var d = 0; d < daysInMonth; d++) byDate[firstDay.add(Duration(days: d))],
  ];
}

/// [monthAnchor] から [offsetMonths] ヵ月分ずらした月の1日を返す
/// （前月・翌月への移動に使う）。
DateTime addMonths(DateTime monthAnchor, int offsetMonths) =>
    DateTime(monthAnchor.year, monthAnchor.month + offsetMonths, 1);
