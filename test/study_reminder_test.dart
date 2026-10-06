import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/daily_goal_store.dart';
import 'package:otsu4/views/home_view.dart';

void main() {
  group('shouldShowStudyReminder', () {
    test('目標が未設定なら表示しない', () {
      final goal = const DailyGoal(target: null, todayCount: 0);
      expect(shouldShowStudyReminder(goal: goal, now: DateTime(2026, 10, 6, 20)), isFalse);
    });

    test('目標を達成していれば表示しない', () {
      final goal = const DailyGoal(target: 10, todayCount: 10);
      expect(shouldShowStudyReminder(goal: goal, now: DateTime(2026, 10, 6, 20)), isFalse);
    });

    test('夜（18時以降）で未達成なら表示する', () {
      final goal = const DailyGoal(target: 10, todayCount: 3);
      expect(shouldShowStudyReminder(goal: goal, now: DateTime(2026, 10, 6, 18)), isTrue);
      expect(shouldShowStudyReminder(goal: goal, now: DateTime(2026, 10, 6, 23)), isTrue);
    });

    test('日中（18時より前）で未達成でも表示しない', () {
      final goal = const DailyGoal(target: 10, todayCount: 3);
      expect(shouldShowStudyReminder(goal: goal, now: DateTime(2026, 10, 6, 17)), isFalse);
    });
  });
}
