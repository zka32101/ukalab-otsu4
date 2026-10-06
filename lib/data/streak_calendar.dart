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
