import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/storage_puzzle.dart';
import 'package:otsu4/data/substance.dart';

void main() {
  const gasoline = Substance(
    id: 'gasoline',
    name: 'ガソリン',
    category: 'test',
    flashPointC: -40,
    specificGravity: 0.7,
    waterSoluble: false,
    designatedQuantityL: 200,
    sourceRef: 'test',
  );
  const kerosene = Substance(
    id: 'kerosene',
    name: '灯油',
    category: 'test',
    flashPointC: 40,
    specificGravity: 0.8,
    waterSoluble: false,
    designatedQuantityL: 1000,
    sourceRef: 'test',
  );

  test('StorageItem.ratioは量÷指定数量', () {
    const item = StorageItem(substance: gasoline, amountL: 100);
    expect(item.ratio, 0.5);
  });

  test('商の和が1未満なら指定数量未満', () {
    const puzzle = StoragePuzzle([
      StorageItem(substance: gasoline, amountL: 100), // 0.5
      StorageItem(substance: kerosene, amountL: 400), // 0.4
    ]);
    expect(puzzle.totalRatio, closeTo(0.9, 1e-9));
    expect(puzzle.requiresPermit, isFalse);
  });

  test('商の和が1以上なら指定数量以上（許可が必要）', () {
    const puzzle = StoragePuzzle([
      StorageItem(substance: gasoline, amountL: 200), // 1.0
    ]);
    expect(puzzle.requiresPermit, isTrue);
  });

  test('空の貯蔵では指定数量未満', () {
    const puzzle = StoragePuzzle([]);
    expect(puzzle.totalRatio, 0);
    expect(puzzle.requiresPermit, isFalse);
  });

  test('generateは2〜3種類の異なる物質を10L単位の量で返す（再現可能）', () {
    final puzzle = StoragePuzzle.generate(seed: 1);
    expect(puzzle.items.length, anyOf(2, 3));
    final ids = puzzle.items.map((i) => i.substance.id).toSet();
    expect(ids.length, puzzle.items.length);
    for (final item in puzzle.items) {
      expect(item.amountL % 10, 0);
      expect(item.amountL, greaterThan(0));
    }

    final again = StoragePuzzle.generate(seed: 1);
    expect(again.items.map((i) => i.substance.id), puzzle.items.map((i) => i.substance.id));
    expect(again.items.map((i) => i.amountL), puzzle.items.map((i) => i.amountL));
  });
}
