import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/subject_stats_store.dart';
import 'package:otsu4/views/record_view.dart';

void main() {
  group('sortedByWeakness', () {
    test('examが無いとき、正答率が低い分野から順に並ぶ', () {
      final stats = {
        'law': const SubjectStat(answered: 10, correct: 9), // 90%
        'property': const SubjectStat(answered: 10, correct: 3), // 30%
        'physics': const SubjectStat(answered: 10, correct: 6), // 60%
      };
      final sorted = sortedByWeakness(null, stats);
      expect(sorted.map((s) => s.$1).toList(), ['property', 'physics', 'law']);
    });
  });
}
