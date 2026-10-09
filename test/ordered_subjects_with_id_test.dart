import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/subject_stats_store.dart';
import 'package:otsu4/views/record_view.dart';
import 'package:ukalab_core/ukalab_core.dart';

void main() {
  group('orderedSubjectsWithId', () {
    final exam = ExamConfig(
      examId: 'hazmat4',
      name: '危険物取扱者乙種第4類',
      audience: Audience.adult,
      levels: const [],
      subjects: const [
        SubjectConfig(subjectId: 'property_extinguish', name: '性質消火', order: 2),
        SubjectConfig(subjectId: 'law', name: '法令', order: 0),
        SubjectConfig(subjectId: 'physics_chem', name: '物理化学', order: 1),
      ],
    );

    test('examのsubjects順で、subjectId・名前・統計を返す', () {
      final stats = {
        'law': const SubjectStat(answered: 10, correct: 8),
        'property_extinguish': const SubjectStat(answered: 5, correct: 3),
      };
      final result = orderedSubjectsWithId(exam, stats);
      expect(result.map((e) => e.$1), ['law', 'property_extinguish']);
      expect(result.map((e) => e.$2), ['法令', '性質消火']);
      expect(result[0].$3.answered, 10);
    });

    test('データが無い分野は含まれない', () {
      final stats = {'law': const SubjectStat(answered: 10, correct: 8)};
      final result = orderedSubjectsWithId(exam, stats);
      expect(result.length, 1);
      expect(result.single.$1, 'law');
    });

    test('examが未取得ならsubjectIdをそのまま名前にする', () {
      final stats = {'law': const SubjectStat(answered: 10, correct: 8)};
      final result = orderedSubjectsWithId(null, stats);
      expect(result, [('law', 'law', stats['law'])]);
    });
  });
}
