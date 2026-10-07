import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/daily_answer_stats_store.dart';

void main() {
  group('DailyAnswerStatsService.recordAnswer', () {
    test('今日の解答数・正解数に加算する', () async {
      final service = DailyAnswerStatsService(
        store: _FakeStore(),
        clock: () => DateTime(2026, 10, 7),
      );
      await service.recordAnswer(correct: true);
      await service.recordAnswer(correct: false);
      await service.recordAnswer(correct: true);
      expect(service.history.length, 1);
      expect(service.history.first.date, DateTime(2026, 10, 7));
      expect(service.history.first.answered, 3);
      expect(service.history.first.correct, 2);
    });

    test('日付が変わると別のエントリとして追加され、古い順に並ぶ', () async {
      var now = DateTime(2026, 10, 6);
      final service = DailyAnswerStatsService(store: _FakeStore(), clock: () => now);
      await service.recordAnswer(correct: true);
      now = DateTime(2026, 10, 7);
      await service.recordAnswer(correct: false);
      expect(service.history.map((e) => e.date), [DateTime(2026, 10, 6), DateTime(2026, 10, 7)]);
    });

    test('上限日数を超えると古いものから捨てる', () async {
      var now = DateTime(2026, 1, 1);
      final service = DailyAnswerStatsService(store: _FakeStore(), clock: () => now);
      for (var i = 0; i < DailyAnswerStatsStore.maxEntries + 5; i++) {
        now = DateTime(2026, 1, 1).add(Duration(days: i));
        await service.recordAnswer(correct: true);
      }
      expect(service.history.length, DailyAnswerStatsStore.maxEntries);
      expect(service.history.first.date, DateTime(2026, 1, 6));
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = DailyAnswerStatsService(store: store, clock: () => DateTime(2026, 10, 7));
      await service.recordAnswer(correct: true);

      final reloaded = DailyAnswerStatsService(store: store);
      await reloaded.load();
      expect(reloaded.history.length, 1);
      expect(reloaded.history.first.answered, 1);
    });

    test('resetで履歴が空になる', () async {
      final service = DailyAnswerStatsService(store: _FakeStore(), clock: () => DateTime(2026, 10, 7));
      await service.recordAnswer(correct: true);
      await service.reset();
      expect(service.history, isEmpty);
    });

    test('restoreで渡した履歴に上書きされる', () async {
      final service = DailyAnswerStatsService(store: _FakeStore(), clock: () => DateTime(2026, 10, 7));
      await service.recordAnswer(correct: true);
      final restored = [
        DailyAnswerStatsEntry(date: DateTime(2026, 9, 1), answered: 10, correct: 5),
      ];
      await service.restore(restored);
      expect(service.history, restored);
    });
  });

  group('DailyAnswerStatsEntry.accuracy', () {
    test('解答数0なら0', () {
      final entry = DailyAnswerStatsEntry(date: DateTime(2026, 10, 7), answered: 0, correct: 0);
      expect(entry.accuracy, 0);
    });

    test('解答数に対する正解数の比率を返す', () {
      final entry = DailyAnswerStatsEntry(date: DateTime(2026, 10, 7), answered: 4, correct: 3);
      expect(entry.accuracy, 0.75);
    });
  });

  group('weeklyAnswerSummary', () {
    test('直近7日間を古い順に返し、データが無い日は0件で埋める', () {
      final history = [
        DailyAnswerStatsEntry(date: DateTime(2026, 10, 5), answered: 3, correct: 2),
        DailyAnswerStatsEntry(date: DateTime(2026, 10, 7), answered: 5, correct: 5),
      ];
      final weekly = weeklyAnswerSummary(history, now: DateTime(2026, 10, 7));
      expect(weekly.length, 7);
      expect(weekly.first.date, DateTime(2026, 10, 1));
      expect(weekly.last.date, DateTime(2026, 10, 7));
      expect(weekly[4].date, DateTime(2026, 10, 5));
      expect(weekly[4].answered, 3);
      expect(weekly.last.answered, 5);
      expect(weekly[0].answered, 0);
    });

    test('履歴が空ならすべて0件', () {
      final weekly = weeklyAnswerSummary(const [], now: DateTime(2026, 10, 7));
      expect(weekly.every((e) => e.answered == 0 && e.correct == 0), isTrue);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements DailyAnswerStatsStore {
  List<DailyAnswerStatsEntry> _saved = [];

  @override
  Future<List<DailyAnswerStatsEntry>> read() async => _saved;

  @override
  Future<void> write(List<DailyAnswerStatsEntry> entries) async => _saved = entries;
}
