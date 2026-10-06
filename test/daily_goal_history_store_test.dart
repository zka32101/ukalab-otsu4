import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/daily_goal_history_store.dart';

void main() {
  group('DailyGoalHistoryService.recordSnapshot', () {
    test('今日のスナップショットを記録できる', () async {
      final service = DailyGoalHistoryService(store: _FakeStore());
      await service.recordSnapshot(date: DateTime(2026, 10, 6), count: 5, achieved: true);
      expect(service.history.length, 1);
      expect(service.history.first.date, DateTime(2026, 10, 6));
      expect(service.history.first.count, 5);
      expect(service.history.first.achieved, isTrue);
    });

    test('同日に複数回記録すると最新の値で上書きする', () async {
      final service = DailyGoalHistoryService(store: _FakeStore());
      await service.recordSnapshot(date: DateTime(2026, 10, 6), count: 3, achieved: false);
      await service.recordSnapshot(date: DateTime(2026, 10, 6), count: 10, achieved: true);
      expect(service.history.length, 1);
      expect(service.history.first.count, 10);
      expect(service.history.first.achieved, isTrue);
    });

    test('日付が変わると別のエントリとして追加され、古い順に並ぶ', () async {
      final service = DailyGoalHistoryService(store: _FakeStore());
      await service.recordSnapshot(date: DateTime(2026, 10, 6), count: 10, achieved: true);
      await service.recordSnapshot(date: DateTime(2026, 10, 7), count: 5, achieved: false);
      expect(service.history.map((e) => e.date), [DateTime(2026, 10, 6), DateTime(2026, 10, 7)]);
    });

    test('上限日数を超えると古いものから捨てる', () async {
      final service = DailyGoalHistoryService(store: _FakeStore());
      for (var i = 0; i < DailyGoalHistoryStore.maxEntries + 5; i++) {
        await service.recordSnapshot(
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          count: i,
          achieved: false,
        );
      }
      expect(service.history.length, DailyGoalHistoryStore.maxEntries);
      expect(service.history.first.count, 5);
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = DailyGoalHistoryService(store: store);
      await service.recordSnapshot(date: DateTime(2026, 10, 6), count: 5, achieved: true);

      final reloaded = DailyGoalHistoryService(store: store);
      await reloaded.load();
      expect(reloaded.history.length, 1);
      expect(reloaded.history.first.count, 5);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements DailyGoalHistoryStore {
  List<DailyGoalHistoryEntry> _saved = [];

  @override
  Future<List<DailyGoalHistoryEntry>> read() async => _saved;

  @override
  Future<void> write(List<DailyGoalHistoryEntry> entries) async => _saved = entries;
}
