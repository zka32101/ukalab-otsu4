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

  group('monthCalendarDays', () {
    test('月の日数ぶん、1日から月末まで順に返す', () {
      final result = monthCalendarDays([], DateTime(2026, 9, 15));
      expect(result.length, 30); // 2026年9月は30日
    });

    test('うるう年でない2月は28日分を返す', () {
      final result = monthCalendarDays([], DateTime(2026, 2, 1));
      expect(result.length, 28);
    });

    test('記録が無い日はnull、該当する記録はその日付に並ぶ', () {
      final history = [
        DailyGoalHistoryEntry(date: DateTime(2026, 10, 1), count: 5, achieved: false),
        DailyGoalHistoryEntry(date: DateTime(2026, 10, 31), count: 20, achieved: true),
      ];
      final result = monthCalendarDays(history, DateTime(2026, 10, 10));
      expect(result.length, 31);
      expect(result.first?.date, DateTime(2026, 10, 1));
      expect(result[1], isNull);
      expect(result.last?.achieved, isTrue);
    });
  });

  group('addMonths', () {
    test('前月・翌月の1日を返す', () {
      expect(addMonths(DateTime(2026, 10, 15), -1), DateTime(2026, 9, 1));
      expect(addMonths(DateTime(2026, 10, 15), 1), DateTime(2026, 11, 1));
    });

    test('年をまたぐ場合も正しく計算する', () {
      expect(addMonths(DateTime(2026, 1, 5), -1), DateTime(2025, 12, 1));
      expect(addMonths(DateTime(2026, 12, 5), 1), DateTime(2027, 1, 1));
    });
  });
}
