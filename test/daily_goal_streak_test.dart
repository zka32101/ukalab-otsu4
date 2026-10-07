import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/daily_goal_store.dart';

void main() {
  group('nextAchievedStreak', () {
    test('初回達成（lastAchievedDateが無い）なら1', () {
      expect(
        nextAchievedStreak(previousStreak: 0, lastAchievedDate: null, today: DateTime(2026, 10, 6)),
        1,
      );
    });

    test('前日に達成していれば連続して+1', () {
      expect(
        nextAchievedStreak(
          previousStreak: 3,
          lastAchievedDate: DateTime(2026, 10, 5),
          today: DateTime(2026, 10, 6),
        ),
        4,
      );
    });

    test('同日ならそのまま', () {
      expect(
        nextAchievedStreak(
          previousStreak: 3,
          lastAchievedDate: DateTime(2026, 10, 6),
          today: DateTime(2026, 10, 6),
        ),
        3,
      );
    });

    test('2日以上空いていれば1にリセット', () {
      expect(
        nextAchievedStreak(
          previousStreak: 5,
          lastAchievedDate: DateTime(2026, 10, 1),
          today: DateTime(2026, 10, 6),
        ),
        1,
      );
    });
  });

  group('effectiveAchievedStreak', () {
    test('lastAchievedDateが今日なら、そのままの値', () {
      final g = DailyGoal(achievedStreak: 5, lastAchievedDate: DateTime(2026, 10, 6));
      expect(effectiveAchievedStreak(g, DateTime(2026, 10, 6, 20)), 5);
    });

    test('lastAchievedDateが昨日なら、そのままの値（途切れていない）', () {
      final g = DailyGoal(achievedStreak: 5, lastAchievedDate: DateTime(2026, 10, 5));
      expect(effectiveAchievedStreak(g, DateTime(2026, 10, 6)), 5);
    });

    test('lastAchievedDateが2日以上前なら途切れているとみなし0', () {
      final g = DailyGoal(achievedStreak: 5, lastAchievedDate: DateTime(2026, 10, 1));
      expect(effectiveAchievedStreak(g, DateTime(2026, 10, 6)), 0);
    });

    test('lastAchievedDateが無ければ0', () {
      expect(effectiveAchievedStreak(const DailyGoal(), DateTime(2026, 10, 6)), 0);
    });
  });

  group('DailyGoalService.recordAnswer と連続達成記録', () {
    test('目標に達した瞬間にachievedStreakが1になる', () async {
      final service = DailyGoalService(store: _FakeStore(), clock: () => DateTime(2026, 10, 6, 9));
      await service.setTarget(2);
      await service.recordAnswer();
      expect(service.goal.achievedStreak, 0);
      await service.recordAnswer();
      expect(service.goal.achievedStreak, 1);
      expect(service.goal.lastAchievedDate, DateTime(2026, 10, 6));
    });

    test('達成した翌日にまた達成すると連続記録が+1される', () async {
      var now = DateTime(2026, 10, 6, 9);
      final service = DailyGoalService(store: _FakeStore(), clock: () => now);
      await service.setTarget(1);
      await service.recordAnswer();
      expect(service.goal.achievedStreak, 1);

      now = DateTime(2026, 10, 7, 9);
      await service.recordAnswer();
      expect(service.goal.achievedStreak, 2);
    });

    test('1日空けて達成すると連続記録が1に戻る', () async {
      var now = DateTime(2026, 10, 6, 9);
      final service = DailyGoalService(store: _FakeStore(), clock: () => now);
      await service.setTarget(1);
      await service.recordAnswer();
      expect(service.goal.achievedStreak, 1);

      now = DateTime(2026, 10, 9, 9);
      await service.recordAnswer();
      expect(service.goal.achievedStreak, 1);
    });

    test('同日に目標を超えて解答してもachievedStreakは変わらない', () async {
      final service = DailyGoalService(store: _FakeStore(), clock: () => DateTime(2026, 10, 6, 9));
      await service.setTarget(1);
      await service.recordAnswer();
      expect(service.goal.achievedStreak, 1);
      await service.recordAnswer();
      expect(service.goal.achievedStreak, 1);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements DailyGoalStore {
  DailyGoal _saved = const DailyGoal();

  @override
  Future<DailyGoal> read() async => _saved;

  @override
  Future<void> write(DailyGoal goal) async => _saved = goal;
}
