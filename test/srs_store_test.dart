import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/srs_store.dart';
import 'package:ukalab_core/ukalab_core.dart';

void main() {
  group('SrsService.review', () {
    test('不正解の問題はすぐ復習対象（due）になる', () async {
      final now = DateTime(2026, 10, 5, 9);
      final service = SrsService(store: _FakeSrsStore(), clock: () => now);
      await service.review(qid: 'q1', correct: false);
      expect(service.dueQids(), ['q1']);
    });

    test('正解の問題は復習間隔が空くまでdueにならない', () async {
      final now = DateTime(2026, 10, 5, 9);
      final service = SrsService(store: _FakeSrsStore(), clock: () => now);
      await service.review(qid: 'q1', correct: true);
      expect(service.dueQids(), isEmpty);
    });

    test('一度正解した問題を間違えると再びdueになる', () async {
      var now = DateTime(2026, 10, 5, 9);
      final service = SrsService(store: _FakeSrsStore(), clock: () => now);
      await service.review(qid: 'q1', correct: true);
      now = now.add(const Duration(days: 1));
      await service.review(qid: 'q1', correct: false);
      expect(service.dueQids(), ['q1']);
    });

    test('保存・再読み込みで状態が復元される', () async {
      final now = DateTime(2026, 10, 5, 9);
      final store = _FakeSrsStore();
      final service = SrsService(store: store, clock: () => now);
      await service.review(qid: 'q1', correct: false);

      final reloaded = SrsService(store: store, clock: () => now);
      await reloaded.load();
      expect(reloaded.dueQids(), ['q1']);
    });

    test('resetで記録が空になる', () async {
      final now = DateTime(2026, 10, 5, 9);
      final service = SrsService(store: _FakeSrsStore(), clock: () => now);
      await service.review(qid: 'q1', correct: false);
      await service.reset();
      expect(service.dueQids(), isEmpty);
    });
  });

  group('srsBoxDistribution', () {
    test('項目が無ければ、すべての箱が0件', () {
      final dist = srsBoxDistribution([]);
      expect(dist.keys.toSet(), {for (var b = 0; b <= Srs.maxBox; b++) b});
      expect(dist.values.every((v) => v == 0), isTrue);
    });

    test('箱ごとに件数を数える', () {
      final items = [
        SrsItem(qid: 'a', box: 0, dueAt: DateTime(2026, 10, 1)),
        SrsItem(qid: 'b', box: 0, dueAt: DateTime(2026, 10, 1)),
        SrsItem(qid: 'c', box: 2, dueAt: DateTime(2026, 10, 1)),
        SrsItem(qid: 'd', box: Srs.maxBox, dueAt: DateTime(2026, 10, 1)),
      ];
      final dist = srsBoxDistribution(items);
      expect(dist[0], 2);
      expect(dist[1], 0);
      expect(dist[2], 1);
      expect(dist[Srs.maxBox], 1);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeSrsStore implements SrsStore {
  Map<String, SrsItem> _saved = {};

  @override
  Future<Map<String, SrsItem>> read() async => _saved;

  @override
  Future<void> write(Map<String, SrsItem> items) async => _saved = items;
}
