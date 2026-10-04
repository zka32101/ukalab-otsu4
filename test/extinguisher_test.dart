import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/extinguisher.dart';

void main() {
  group('Extinguisher.isEffectiveFor', () {
    test('水は水溶性・非水溶性のどちらにも不適', () {
      expect(Extinguisher.water.isEffectiveFor(waterSoluble: true), isFalse);
      expect(Extinguisher.water.isEffectiveFor(waterSoluble: false), isFalse);
    });

    test('一般泡は非水溶性のみ有効', () {
      expect(Extinguisher.foam.isEffectiveFor(waterSoluble: false), isTrue);
      expect(Extinguisher.foam.isEffectiveFor(waterSoluble: true), isFalse);
    });

    test('耐アルコール泡はどちらにも有効', () {
      expect(Extinguisher.alcoholFoam.isEffectiveFor(waterSoluble: true), isTrue);
      expect(Extinguisher.alcoholFoam.isEffectiveFor(waterSoluble: false), isTrue);
    });

    test('粉末はどちらにも有効', () {
      expect(Extinguisher.powder.isEffectiveFor(waterSoluble: true), isTrue);
      expect(Extinguisher.powder.isEffectiveFor(waterSoluble: false), isTrue);
    });
  });

  test('reasonForは空文字を返さない', () {
    for (final e in Extinguisher.values) {
      expect(e.reasonFor(waterSoluble: true), isNotEmpty);
      expect(e.reasonFor(waterSoluble: false), isNotEmpty);
    }
  });
}
