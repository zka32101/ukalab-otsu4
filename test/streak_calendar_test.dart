import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/daily_goal_history_store.dart';
import 'package:otsu4/data/streak_calendar.dart';

void main() {
  group('streakCalendarDays', () {
    final now = DateTime(2026, 10, 10);

    test('記録が無い日はnullになる', () {
      final result = streakCalendarDays([], now, days: 3);
      expect(result, [null, null, null]);
    });

    test('古い日から新しい日の順で、該当する記録を並べる', () {
      final history = [
        DailyGoalHistoryEntry(date: DateTime(2026, 10, 8), count: 5, achieved: false),
        DailyGoalHistoryEntry(date: DateTime(2026, 10, 10), count: 20, achieved: true),
      ];
      final result = streakCalendarDays(history, now, days: 3);
      expect(result.length, 3);
      expect(result[0]?.date, DateTime(2026, 10, 8));
      expect(result[1], isNull);
      expect(result[2]?.achieved, isTrue);
    });

    test('指定した日数ぶんだけ返す', () {
      final result = streakCalendarDays([], now, days: 28);
      expect(result.length, 28);
    });
  });
}
