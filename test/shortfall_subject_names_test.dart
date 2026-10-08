import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/mock_history_store.dart';
import 'package:otsu4/views/record_view.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

void main() {
  group('shortfallSubjectNames', () {
    final exam = ExamConfig(
      examId: 'hazmat4',
      name: '危険物取扱者乙種第4類',
      audience: Audience.adult,
      levels: const [
        LevelConfig(
          levelId: 'hazmat4',
          name: '乙種第4類',
          questionCount: 35,
          passRule: PassRule(totalPct: 60, subjectMinPct: 60),
        ),
      ],
      subjects: const [
        SubjectConfig(subjectId: 'law', name: '法令', order: 0),
        SubjectConfig(subjectId: 'physics_chem', name: '物理化学', order: 1),
        SubjectConfig(subjectId: 'property_extinguish', name: '性質消火', order: 2),
      ],
    );

    test('しきい値未満の科目の名前を返す', () {
      final entry = MockHistoryEntry(
        at: DateTime(2026, 1, 1),
        score: 20,
        max: 35,
        passed: false,
        subjectScore: {'law': 5, 'physics_chem': 8, 'property_extinguish': 7},
        subjectMax: {'law': 15, 'physics_chem': 10, 'property_extinguish': 10},
      );
      expect(shortfallSubjectNames(entry, exam), ['法令']);
    });

    test('全科目がしきい値以上なら空', () {
      final entry = MockHistoryEntry(
        at: DateTime(2026, 1, 1),
        score: 30,
        max: 35,
        passed: true,
        subjectScore: {'law': 10, 'physics_chem': 8, 'property_extinguish': 8},
        subjectMax: {'law': 15, 'physics_chem': 10, 'property_extinguish': 10},
      );
      expect(shortfallSubjectNames(entry, exam), isEmpty);
    });

    test('科目別データが無ければ空', () {
      final entry = MockHistoryEntry(at: DateTime(2026, 1, 1), score: 20, max: 35, passed: false);
      expect(shortfallSubjectNames(entry, exam), isEmpty);
    });

    test('examがnullなら空', () {
      final entry = MockHistoryEntry(
        at: DateTime(2026, 1, 1),
        score: 20,
        max: 35,
        passed: false,
        subjectScore: {'law': 5},
        subjectMax: {'law': 15},
      );
      expect(shortfallSubjectNames(entry, null), isEmpty);
    });
  });
}
