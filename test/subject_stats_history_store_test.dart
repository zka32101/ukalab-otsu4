import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/subject_stats_history_store.dart';
import 'package:otsu4/data/subject_stats_store.dart';

void main() {
  group('SubjectStatsHistoryService.recordSnapshot', () {
    test('スナップショットを記録すると履歴に積まれる', () async {
      final now = DateTime(2026, 10, 6, 9);
      final service = SubjectStatsHistoryService(store: _FakeStore(), clock: () => now);
      await service.recordSnapshot({'law': const SubjectStat(answered: 2, correct: 1)});
      expect(service.history, hasLength(1));
      expect(service.history.single.accuracyBySubject['law'], 0.5);
    });

    test('同じ日に複数回記録すると最新の値で上書きされる', () async {
      final now = DateTime(2026, 10, 6, 9);
      final service = SubjectStatsHistoryService(store: _FakeStore(), clock: () => now);
      await service.recordSnapshot({'law': const SubjectStat(answered: 2, correct: 1)});
      await service.recordSnapshot({'law': const SubjectStat(answered: 4, correct: 3)});
      expect(service.history, hasLength(1));
      expect(service.history.single.accuracyBySubject['law'], 0.75);
    });

    test('日付が変わると新しいエントリが追加される', () async {
      var now = DateTime(2026, 10, 6, 9);
      final service = SubjectStatsHistoryService(store: _FakeStore(), clock: () => now);
      await service.recordSnapshot({'law': const SubjectStat(answered: 2, correct: 1)});

      now = now.add(const Duration(days: 1));
      await service.recordSnapshot({'law': const SubjectStat(answered: 4, correct: 3)});
      expect(service.history, hasLength(2));
      expect(service.history.first.accuracyBySubject['law'], 0.5);
      expect(service.history.last.accuracyBySubject['law'], 0.75);
    });

    test('上限日数を超えると古いものから捨てる', () async {
      var now = DateTime(2026, 1, 1, 9);
      final service = SubjectStatsHistoryService(store: _FakeStore(), clock: () => now);
      for (var i = 0; i < SubjectStatsHistoryStore.maxEntries + 3; i++) {
        await service.recordSnapshot({'law': SubjectStat(answered: i + 1, correct: 0)});
        now = now.add(const Duration(days: 1));
      }
      expect(service.history, hasLength(SubjectStatsHistoryStore.maxEntries));
      expect(service.history.first.accuracyBySubject['law'], 0);
    });

    test('保存・再読み込みで履歴が復元される', () async {
      final store = _FakeStore();
      final now = DateTime(2026, 10, 6, 9);
      final service = SubjectStatsHistoryService(store: store, clock: () => now);
      await service.recordSnapshot({'law': const SubjectStat(answered: 2, correct: 1)});

      final reloaded = SubjectStatsHistoryService(store: store, clock: () => now);
      await reloaded.load();
      expect(reloaded.history, hasLength(1));
      expect(reloaded.history.single.accuracyBySubject['law'], 0.5);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements SubjectStatsHistoryStore {
  List<SubjectStatsHistoryEntry> _saved = [];

  @override
  Future<List<SubjectStatsHistoryEntry>> read() async => _saved;

  @override
  Future<void> write(List<SubjectStatsHistoryEntry> entries) async => _saved = entries;
}
