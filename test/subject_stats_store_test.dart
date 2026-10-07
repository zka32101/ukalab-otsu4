import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/subject_stats_store.dart';

void main() {
  group('SubjectStatsService.recordAnswer', () {
    test('分野ごとに解答数・正解数が積み上がる', () async {
      final service = SubjectStatsService(store: _FakeSubjectStatsStore());
      await service.recordAnswer(subjectId: 'law', correct: true);
      await service.recordAnswer(subjectId: 'law', correct: false);
      final law = service.stats['law']!;
      expect(law.answered, 2);
      expect(law.correct, 1);
      expect(law.accuracy, 0.5);
    });

    test('分野ごとに独立して記録される', () async {
      final service = SubjectStatsService(store: _FakeSubjectStatsStore());
      await service.recordAnswer(subjectId: 'law', correct: true);
      await service.recordAnswer(subjectId: 'property', correct: false);
      expect(service.stats['law']!.answered, 1);
      expect(service.stats['property']!.answered, 1);
      expect(service.stats['property']!.correct, 0);
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeSubjectStatsStore();
      final service = SubjectStatsService(store: store);
      await service.recordAnswer(subjectId: 'law', correct: true);

      final reloaded = SubjectStatsService(store: store);
      await reloaded.load();
      expect(reloaded.stats['law']!.answered, 1);
      expect(reloaded.stats['law']!.correct, 1);
    });

    test('resetで統計が空になる', () async {
      final service = SubjectStatsService(store: _FakeSubjectStatsStore());
      await service.recordAnswer(subjectId: 'law', correct: true);
      await service.reset();
      expect(service.stats, isEmpty);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeSubjectStatsStore implements SubjectStatsStore {
  Map<String, SubjectStat> _saved = {};

  @override
  Future<Map<String, SubjectStat>> read() async => _saved;

  @override
  Future<void> write(Map<String, SubjectStat> stats) async => _saved = stats;
}
