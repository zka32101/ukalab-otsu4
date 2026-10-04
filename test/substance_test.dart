import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/substance.dart';

void main() {
  group('Substance.isFlammableAt', () {
    test('気温が引火点と同じなら危険', () {
      const s = Substance(
        id: 'x',
        name: 'x',
        category: 'x',
        flashPointC: 20,
        specificGravity: 1,
        waterSoluble: false,
        designatedQuantityL: 100,
        sourceRef: 'test',
      );
      expect(s.isFlammableAt(20), isTrue);
    });

    test('気温が引火点未満なら安全', () {
      const s = Substance(
        id: 'x',
        name: 'x',
        category: 'x',
        flashPointC: 20,
        specificGravity: 1,
        waterSoluble: false,
        designatedQuantityL: 100,
        sourceRef: 'test',
      );
      expect(s.isFlammableAt(19.9), isFalse);
    });
  });

  test('代表6物質が重複しないIDで定義されている', () {
    final ids = substances.map((s) => s.id).toSet();
    expect(ids.length, substances.length);
    expect(ids.length, 6);
  });
}
