import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/field_day.dart';

void main() {
  test('1日4場面、時刻の順に並ぶ', () {
    final scenario = FieldDayScenario.generate(seed: 0);
    expect(scenario.steps.length, 4);
    expect(
      scenario.steps.map((s) => s.timeLabel),
      ['08:00', '11:00', '14:00', '17:00'],
    );
  });

  test('各場面は2択で、正解のindexが範囲内', () {
    for (var seed = 0; seed < 20; seed++) {
      final scenario = FieldDayScenario.generate(seed: seed);
      for (final step in scenario.steps) {
        expect(step.choices.length, 2);
        expect(step.correctIndex, anyOf(0, 1));
        expect(step.prompt, isNotEmpty);
        expect(step.explanation, isNotEmpty);
      }
    }
  });

  test('同じseedなら同じシナリオになる（再現可能）', () {
    final a = FieldDayScenario.generate(seed: 5);
    final b = FieldDayScenario.generate(seed: 5);
    expect(a.steps.map((s) => s.prompt), b.steps.map((s) => s.prompt));
    expect(a.steps.map((s) => s.correctIndex), b.steps.map((s) => s.correctIndex));
  });
}
