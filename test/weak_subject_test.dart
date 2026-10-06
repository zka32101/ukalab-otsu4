import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/subject_stats_store.dart';

void main() {
  group('weakSubjectIds', () {
    test('解答数が十分で正答率が低い分野だけを返す', () {
      final stats = {
        'law': const SubjectStat(answered: 10, correct: 3), // 30%
        'property': const SubjectStat(answered: 10, correct: 9), // 90%
      };
      expect(weakSubjectIds(stats), ['law']);
    });

    test('解答数が最低件数未満の分野は含めない', () {
      final stats = {
        'law': const SubjectStat(answered: 2, correct: 0), // 0%だが解答数不足
      };
      expect(weakSubjectIds(stats), isEmpty);
    });

    test('正答率がしきい値以上の分野は含めない', () {
      final stats = {
        'law': const SubjectStat(answered: 10, correct: 6), // 60%
      };
      expect(weakSubjectIds(stats), isEmpty);
    });
  });
}
