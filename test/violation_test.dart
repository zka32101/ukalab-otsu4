import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/violation.dart';

void main() {
  test('4つの行動のうちちょうど1つが違反になっている', () {
    for (var seed = 0; seed < 20; seed++) {
      final scenario = ViolationScenario.generate(seed: seed);
      expect(scenario.statements.length, 4);
      final violations = scenario.statements.where((s) => s.isViolation);
      expect(violations.length, 1, reason: 'seed=$seed');
      expect(scenario.violationIndex, isNonNegative);
    }
  });

  test('同じseedなら同じシナリオになる（再現可能）', () {
    final a = ViolationScenario.generate(seed: 7);
    final b = ViolationScenario.generate(seed: 7);
    expect(a.statements.map((s) => s.text), b.statements.map((s) => s.text));
    expect(a.violationIndex, b.violationIndex);
  });

  test('説明文は空文字を返さない', () {
    final scenario = ViolationScenario.generate(seed: 3);
    for (final s in scenario.statements) {
      expect(s.explanation, isNotEmpty);
      expect(s.text, isNotEmpty);
    }
  });
}
