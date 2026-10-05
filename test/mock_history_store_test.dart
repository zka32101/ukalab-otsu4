import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/mock_history_store.dart';

void main() {
  group('MockHistoryService.add', () {
    test('結果を追加すると履歴に積まれる', () async {
      final service = MockHistoryService(store: _FakeMockHistoryStore());
      await service.add(
        MockHistoryEntry(at: DateTime(2026, 10, 5), score: 24, max: 35, passed: true),
      );
      expect(service.history, hasLength(1));
      expect(service.history.single.passed, isTrue);
    });

    test('上限件数を超えると古いものから捨てる', () async {
      final service = MockHistoryService(store: _FakeMockHistoryStore());
      for (var i = 0; i < MockHistoryStore.maxEntries + 3; i++) {
        await service.add(
          MockHistoryEntry(at: DateTime(2026, 1, 1).add(Duration(days: i)), score: i, max: 35, passed: false),
        );
      }
      expect(service.history, hasLength(MockHistoryStore.maxEntries));
      expect(service.history.first.score, 3);
    });

    test('保存・再読み込みで履歴が復元される', () async {
      final store = _FakeMockHistoryStore();
      final service = MockHistoryService(store: store);
      await service.add(
        MockHistoryEntry(at: DateTime(2026, 10, 5), score: 20, max: 35, passed: false),
      );

      final reloaded = MockHistoryService(store: store);
      await reloaded.load();
      expect(reloaded.history, hasLength(1));
      expect(reloaded.history.single.score, 20);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeMockHistoryStore implements MockHistoryStore {
  List<MockHistoryEntry> _saved = [];

  @override
  Future<List<MockHistoryEntry>> read() async => _saved;

  @override
  Future<void> write(List<MockHistoryEntry> entries) async => _saved = entries;
}
