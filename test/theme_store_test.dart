import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/theme_store.dart';

void main() {
  group('ThemeService', () {
    test('初期状態は端末に合わせる（system）', () async {
      final service = ThemeService(store: _FakeThemeStore());
      await service.load();
      expect(service.mode, ThemeMode.system);
    });

    test('モードを設定できる', () async {
      final service = ThemeService(store: _FakeThemeStore());
      await service.setMode(ThemeMode.dark);
      expect(service.mode, ThemeMode.dark);
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeThemeStore();
      final service = ThemeService(store: store);
      await service.setMode(ThemeMode.light);

      final reloaded = ThemeService(store: store);
      await reloaded.load();
      expect(reloaded.mode, ThemeMode.light);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeThemeStore implements ThemeStore {
  ThemeMode _saved = ThemeMode.system;

  @override
  Future<ThemeMode> read() async => _saved;

  @override
  Future<void> write(ThemeMode mode) async => _saved = mode;
}
