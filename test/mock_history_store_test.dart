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

    test('resetで履歴が空になる', () async {
      final service = MockHistoryService(store: _FakeMockHistoryStore());
      await service.add(MockHistoryEntry(at: DateTime(2026, 10, 5), score: 20, max: 35, passed: false));
      await service.reset();
      expect(service.history, isEmpty);
    });
  });

  group('MockHistoryEntry.subjectPct', () {
    test('科目のデータがあれば得点率を返す', () {
      final entry = MockHistoryEntry(
        at: DateTime(2026, 10, 5),
        score: 24,
        max: 35,
        passed: true,
        subjectScore: {'law': 12, 'physics_chem': 6},
        subjectMax: {'law': 15, 'physics_chem': 10},
      );
      expect(entry.subjectPct('law'), closeTo(80, 0.01));
      expect(entry.subjectPct('physics_chem'), closeTo(60, 0.01));
    });

    test('科目のデータが無ければnull（この項目を追加する前の記録等）', () {
      final entry = MockHistoryEntry(at: DateTime(2026, 10, 5), score: 24, max: 35, passed: true);
      expect(entry.subjectPct('law'), isNull);
    });
  });

  group('MockHistoryEntry.toJson/fromJson', () {
    test('科目別の得点・満点を含めて往復する', () {
      final entry = MockHistoryEntry(
        at: DateTime(2026, 10, 5),
        score: 24,
        max: 35,
        passed: true,
        subjectScore: {'law': 12},
        subjectMax: {'law': 15},
      );
      final restored = MockHistoryEntry.fromJson(entry.toJson());
      expect(restored.subjectPct('law'), closeTo(80, 0.01));
    });

    test('科目別データが無いJSON（旧形式）も読み込める', () {
      final json = {'at': '2026-10-05T00:00:00.000', 'score': 24, 'max': 35, 'passed': true};
      final restored = MockHistoryEntry.fromJson(json);
      expect(restored.subjectPct('law'), isNull);
      expect(restored.score, 24);
    });
  });

  group('mockSubjectTrendSeries', () {
    MockHistoryEntry entry({required int score, required int max, Map<String, int>? subjectScore, Map<String, int>? subjectMax}) =>
        MockHistoryEntry(
          at: DateTime(2026, 10, 5),
          score: score,
          max: max,
          passed: score * 100 / max >= 60,
          subjectScore: subjectScore,
          subjectMax: subjectMax,
        );

    test('指定した科目のデータがある回だけを古い順の得点率（0.0〜1.0）で返す', () {
      final history = [
        entry(score: 20, max: 35, subjectScore: {'law': 12}, subjectMax: {'law': 15}), // 80%
        entry(score: 10, max: 35), // 科目データ無し（無視される）
        entry(score: 25, max: 35, subjectScore: {'law': 9}, subjectMax: {'law': 15}), // 60%
      ];
      expect(mockSubjectTrendSeries(history, 'law'), [0.8, 0.6]);
    });

    test('対象科目のデータが1件も無ければ空を返す', () {
      final history = [entry(score: 20, max: 35)];
      expect(mockSubjectTrendSeries(history, 'law'), isEmpty);
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
