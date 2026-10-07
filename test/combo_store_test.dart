import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/combo_store.dart';

void main() {
  group('ComboService', () {
    test('初期状態は0', () async {
      final service = ComboService(store: _FakeStore());
      expect(service.bestCombo, 0);
    });

    test('自己最高を更新したときだけ値が上がる', () async {
      final service = ComboService(store: _FakeStore());
      await service.recordCombo(3);
      expect(service.bestCombo, 3);
      await service.recordCombo(2);
      expect(service.bestCombo, 3);
      await service.recordCombo(5);
      expect(service.bestCombo, 5);
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = ComboService(store: store);
      await service.recordCombo(7);

      final reloaded = ComboService(store: store);
      await reloaded.load();
      expect(reloaded.bestCombo, 7);
    });

    test('resetで0に戻る', () async {
      final service = ComboService(store: _FakeStore());
      await service.recordCombo(5);
      await service.reset();
      expect(service.bestCombo, 0);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements ComboStore {
  int _saved = 0;

  @override
  Future<int> read() async => _saved;

  @override
  Future<void> write(int bestCombo) async => _saved = bestCombo;
}
