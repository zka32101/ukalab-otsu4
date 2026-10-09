import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/source_credits.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _q({
  required String qid,
  required String subjectId,
  required QuestionSource source,
  required String sourceRef,
}) =>
    Question(
      qid: qid,
      examId: 'hazmat4',
      subjectId: subjectId,
      topicId: 'topic',
      prompt: '問題文',
      explanation: '解説文',
      source: source,
      sourceRef: sourceRef,
      contentVer: '2026.10.0',
    );

void main() {
  group('lawSourceReferences', () {
    test('法令の条文出典だけを、出現順・重複無しで返す', () {
      final pool = [
        _q(qid: 'l1', subjectId: 'law', source: QuestionSource.statute, sourceRef: '消防法第10条'),
        _q(qid: 'l2', subjectId: 'law', source: QuestionSource.statute, sourceRef: '消防法第11条'),
        _q(qid: 'l3', subjectId: 'law', source: QuestionSource.statute, sourceRef: '消防法第10条'),
      ];
      expect(lawSourceReferences(pool), ['消防法第10条', '消防法第11条']);
    });

    test('法令以外の分野は含めない', () {
      final pool = [
        _q(
          qid: 'pc1',
          subjectId: 'physics_chem',
          source: QuestionSource.original,
          sourceRef: '独自作成',
        ),
      ];
      expect(lawSourceReferences(pool), isEmpty);
    });

    test('source: originalの法令問題は含めない', () {
      final pool = [
        _q(qid: 'l1', subjectId: 'law', source: QuestionSource.original, sourceRef: '独自作成'),
      ];
      expect(lawSourceReferences(pool), isEmpty);
    });
  });
}
