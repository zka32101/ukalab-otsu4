import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/question_repository.dart';
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
  group('filterBySubject', () {
    final pool = [
      _q(qid: 'law1', subjectId: 'law'),
      _q(qid: 'pc1', subjectId: 'physics_chem'),
      _q(qid: 'law2', subjectId: 'law'),
    ];

    test('subjectIdがnullならそのまま返す', () {
      expect(filterBySubject(pool, null), pool);
    });

    test('subjectIdを指定すると、その分野だけに絞り込む', () {
      final filtered = filterBySubject(pool, 'law');
      expect(filtered.map((q) => q.qid), ['law1', 'law2']);
    });

    test('一致する問題が無ければ空を返す', () {
      expect(filterBySubject(pool, 'property_extinguish'), isEmpty);
    });
  });
}
