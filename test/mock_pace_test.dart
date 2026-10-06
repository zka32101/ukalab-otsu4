import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/mock_pace.dart';
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
  group('subjectPaceBudgetSec', () {
    test('問題数の比率で時間を配分する', () {
      final budget = subjectPaceBudgetSec(
        subjectQuestionCounts: {'law': 15, 'physics_chem': 10, 'property_extinguish': 10},
        totalTimeSec: 7200,
      );
      expect(budget['law'], 3086); // 7200 * 15/35
      expect(budget['physics_chem'], 2057); // 7200 * 10/35
      expect(budget['property_extinguish'], 2057);
    });

    test('問題数の合計が0なら空を返す', () {
      expect(subjectPaceBudgetSec(subjectQuestionCounts: {}, totalTimeSec: 7200), isEmpty);
    });
  });

  group('cumulativeBudgetSecAt', () {
    final picked = [
      _q(qid: 'l1', subjectId: 'law'),
      _q(qid: 'l2', subjectId: 'law'),
      _q(qid: 'p1', subjectId: 'physics_chem'),
      _q(qid: 'p2', subjectId: 'physics_chem'),
    ];
    final counts = {'law': 2, 'physics_chem': 2};
    final budget = {'law': 100, 'physics_chem': 200}; // law:1問50秒、physics_chem:1問100秒

    test('科目の切り替わりをまたいで累計時間を計算する', () {
      expect(cumulativeBudgetSecAt(
        picked: picked,
        index: 0,
        subjectQuestionCounts: counts,
        subjectBudgetSec: budget,
      ), 50);
      expect(cumulativeBudgetSecAt(
        picked: picked,
        index: 1,
        subjectQuestionCounts: counts,
        subjectBudgetSec: budget,
      ), 100);
      expect(cumulativeBudgetSecAt(
        picked: picked,
        index: 2,
        subjectQuestionCounts: counts,
        subjectBudgetSec: budget,
      ), 200);
      expect(cumulativeBudgetSecAt(
        picked: picked,
        index: 3,
        subjectQuestionCounts: counts,
        subjectBudgetSec: budget,
      ), 300);
    });
  });

  group('isBehindPace', () {
    test('経過時間が目安を超えていれば遅れている', () {
      expect(isBehindPace(elapsedSec: 101, cumulativeBudgetSec: 100), isTrue);
    });

    test('経過時間が目安以下なら遅れていない', () {
      expect(isBehindPace(elapsedSec: 100, cumulativeBudgetSec: 100), isFalse);
      expect(isBehindPace(elapsedSec: 50, cumulativeBudgetSec: 100), isFalse);
    });
  });
}
