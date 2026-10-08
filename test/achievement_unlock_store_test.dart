import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/achievement_unlock_store.dart';

void main() {
  group('AchievementUnlockService', () {
    test('初期状態は空', () async {
      final service = AchievementUnlockService(store: _FakeStore());
      expect(service.unlockedAt, isEmpty);
      expect(service.notifiedIds, isEmpty);
    });

    test('markNotifiedで解除日時が追加される', () async {
      final service = AchievementUnlockService(store: _FakeStore());
      final at = DateTime(2026, 1, 1);
      await service.markNotified({'streak_7'}, at);
      expect(service.unlockedAt, {'streak_7': at});
      final at2 = DateTime(2026, 1, 2);
      await service.markNotified({'answered_50'}, at2);
      expect(service.unlockedAt, {'streak_7': at, 'answered_50': at2});
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = AchievementUnlockService(store: store);
      final at = DateTime(2026, 1, 1);
      await service.markNotified({'mock_pass'}, at);

      final reloaded = AchievementUnlockService(store: store);
      await reloaded.load();
      expect(reloaded.unlockedAt, {'mock_pass': at});
    });

    test('resetで空に戻る', () async {
      final service = AchievementUnlockService(store: _FakeStore());
      await service.markNotified({'mock_pass'}, DateTime(2026, 1, 1));
      await service.reset();
      expect(service.unlockedAt, isEmpty);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements AchievementUnlockStore {
  Map<String, DateTime> _saved = const {};

  @override
  Future<Map<String, DateTime>> read() async => _saved;

  @override
  Future<void> write(Map<String, DateTime> unlockedAt) async => _saved = unlockedAt;
}
