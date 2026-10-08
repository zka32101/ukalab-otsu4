import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/achievement_unlock_store.dart';

void main() {
  group('AchievementUnlockService', () {
    test('初期状態は空', () async {
      final service = AchievementUnlockService(store: _FakeStore());
      expect(service.notifiedIds, isEmpty);
    });

    test('markNotifiedで通知済みIDが追加される', () async {
      final service = AchievementUnlockService(store: _FakeStore());
      await service.markNotified({'streak_7'});
      expect(service.notifiedIds, {'streak_7'});
      await service.markNotified({'answered_50'});
      expect(service.notifiedIds, {'streak_7', 'answered_50'});
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = AchievementUnlockService(store: store);
      await service.markNotified({'mock_pass'});

      final reloaded = AchievementUnlockService(store: store);
      await reloaded.load();
      expect(reloaded.notifiedIds, {'mock_pass'});
    });

    test('resetで空に戻る', () async {
      final service = AchievementUnlockService(store: _FakeStore());
      await service.markNotified({'mock_pass'});
      await service.reset();
      expect(service.notifiedIds, isEmpty);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements AchievementUnlockStore {
  Set<String> _saved = const {};

  @override
  Future<Set<String>> read() async => _saved;

  @override
  Future<void> write(Set<String> ids) async => _saved = ids;
}
