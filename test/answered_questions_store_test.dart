import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/answered_questions_store.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

Question _q({required String qid, required String subjectId}) => Question(
      qid: qid,
      examId: 'hazmat4',
      subjectId: subjectId,
      topicId: 'topic',
      prompt: '問題文',
      explanation: '解説文',
      source: QuestionSource.original,
      sourceRef: 'test',
      contentVer: '2026.10.0',
    );

void main() {
  group('AnsweredQuestionsService.record', () {
    test('解答した問題のqidを記録できる', () async {
      final service = AnsweredQuestionsService(store: _FakeStore());
      await service.record('q1');
      expect(service.qids, {'q1'});
    });

    test('同じqidを複数回記録しても1件のまま', () async {
      final service = AnsweredQuestionsService(store: _FakeStore());
      await service.record('q1');
      await service.record('q1');
      expect(service.qids, {'q1'});
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = AnsweredQuestionsService(store: store);
      await service.record('q1');
      await service.record('q2');

      final reloaded = AnsweredQuestionsService(store: store);
      await reloaded.load();
      expect(reloaded.qids, {'q1', 'q2'});
    });

    test('resetで記録が空になる', () async {
      final service = AnsweredQuestionsService(store: _FakeStore());
      await service.record('q1');
      await service.reset();
      expect(service.qids, isEmpty);
    });
  });

  group('subjectCoverage', () {
    final pool = [
      _q(qid: 'law1', subjectId: 'law'),
      _q(qid: 'law2', subjectId: 'law'),
      _q(qid: 'pc1', subjectId: 'physics_chem'),
    ];

    test('分野ごとに解答済みの割合を計算する', () {
      final coverage = subjectCoverage(pool, {'law1'});
      expect(coverage['law'], 0.5);
      expect(coverage['physics_chem'], 0.0);
    });

    test('全問解答済みなら1.0', () {
      final coverage = subjectCoverage(pool, {'law1', 'law2'});
      expect(coverage['law'], 1.0);
    });

    test('未解答なら0.0', () {
      final coverage = subjectCoverage(pool, {});
      expect(coverage['law'], 0.0);
      expect(coverage['physics_chem'], 0.0);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements AnsweredQuestionsStore {
  Set<String> _saved = {};

  @override
  Future<Set<String>> read() async => _saved;

  @override
  Future<void> write(Set<String> qids) async => _saved = qids;
}
