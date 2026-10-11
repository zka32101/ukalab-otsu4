import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/daily_goal.dart';

void main() {
  group('DailyGoalService', () {
    test('目標を設定できる', () async {
      final service = DailyGoalService(store: _FakeDailyGoalStore());
      await service.setTarget(20);
      expect(service.goal.target, 20);
    });

    test('nullを設定すると目標がオフになる', () async {
      final service = DailyGoalService(store: _FakeDailyGoalStore());
      await service.setTarget(20);
      await service.setTarget(null);
      expect(service.goal.target, isNull);
    });

    test('解答するたびに今日の解答数が増え、目標に達すると達成になる', () async {
      final service = DailyGoalService(store: _FakeDailyGoalStore());
      await service.setTarget(2);
      await service.recordAnswer();
      expect(service.goal.achieved, isFalse);
      await service.recordAnswer();
      expect(service.goal.todayCount, 2);
      expect(service.goal.achieved, isTrue);
    });

    test('日付が変わると今日の解答数がリセットされる', () async {
      var now = DateTime(2026, 10, 5, 9);
      final service = DailyGoalService(store: _FakeDailyGoalStore(), clock: () => now);
      await service.setTarget(10);
      await service.recordAnswer();
      expect(service.goal.todayCount, 1);

      now = now.add(const Duration(days: 1));
      await service.recordAnswer();
      expect(service.goal.todayCount, 1);
      expect(service.goal.target, 10);
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeDailyGoalStore();
      final service = DailyGoalService(store: store);
      await service.setTarget(20);
      await service.recordAnswer();

      final reloaded = DailyGoalService(store: store);
      await reloaded.load();
      expect(reloaded.goal.target, 20);
      expect(reloaded.goal.todayCount, 1);
    });

    test('resetで目標設定を含め初期状態に戻る', () async {
      final service = DailyGoalService(store: _FakeDailyGoalStore());
      await service.setTarget(20);
      await service.recordAnswer();
      final goal = await service.reset();
      expect(goal.target, isNull);
      expect(goal.todayCount, 0);
      expect(service.goal.target, isNull);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeDailyGoalStore implements DailyGoalStore {
  @override
  String get appId => 'test';

  DailyGoal _saved = const DailyGoal();

  @override
  Future<DailyGoal> read() async => _saved;

  @override
  Future<void> write(DailyGoal goal) async => _saved = goal;
}
