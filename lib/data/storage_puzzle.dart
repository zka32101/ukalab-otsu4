import 'dart:math';

import 'substance.dart';

/// 貯蔵所パズル（画期的な機能C）の1問。複数物質の貯蔵量から
/// 指定数量の倍数の合計（商の和）を計算する。
///
/// 根拠: 消防法第10条。品名又は指定数量を異にする2以上の危険物を
/// 同一の場所で貯蔵・取扱う場合、それぞれの数量を指定数量で除し、
/// その商の和が1以上となるときは指定数量以上とみなす
/// （2026-10-03、WebSearch経由で複数資料が一致する内容を確認）。
class StorageItem {
  const StorageItem({required this.substance, required this.amountL});

  final Substance substance;
  final int amountL;

  /// 指定数量に対する比率（商）。
  double get ratio => amountL / substance.designatedQuantityL;
}

class StoragePuzzle {
  const StoragePuzzle(this.items);

  final List<StorageItem> items;

  /// 商の和。
  double get totalRatio =>
      items.fold(0.0, (sum, item) => sum + item.ratio);

  /// 指定数量以上（許可が必要）かどうか。
  bool get requiresPermit => totalRatio >= 1.0;

  /// 2〜3種類の物質をランダムに選び、量もランダムに決めて1問を作る。
  static StoragePuzzle generate({int seed = 0}) {
    final random = Random(seed);
    final pool = List<Substance>.from(substances)..shuffle(random);
    final count = 2 + random.nextInt(2); // 2〜3種類
    final chosen = pool.take(count).toList();
    final items = [
      for (final s in chosen)
        StorageItem(
          substance: s,
          // 指定数量の約10%〜120%の範囲でランダムに決め、
          // 10の倍数に丸めて読みやすい数にする。
          amountL: _roundToTen(
            (s.designatedQuantityL * (0.1 + random.nextDouble() * 1.1))
                .round(),
          ),
        ),
    ];
    return StoragePuzzle(items);
  }

  static int _roundToTen(int v) => ((v + 5) ~/ 10) * 10;
}
