import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// テーマ設定（ライト／ダーク／端末に合わせる）の端末内保存。
class ThemeStore {
  static const _key = 'ukalab_otsu4_theme_mode';

  Future<ThemeMode> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> write(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

/// テーマ設定の読み込み・更新。`main()` で `load()` してから
/// `themeServiceProvider.overrideWithValue(...)` で渡す。
class ThemeService {
  ThemeService({ThemeStore? store}) : _store = store ?? ThemeStore();

  final ThemeStore _store;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    _mode = await _store.read();
  }

  Future<ThemeMode> setMode(ThemeMode mode) async {
    _mode = mode;
    await _store.write(mode);
    return _mode;
  }
}

final themeServiceProvider = Provider<ThemeService>(
  (ref) => throw UnimplementedError('themeServiceProvider を override してください'),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  ThemeService get _s => ref.read(themeServiceProvider);

  @override
  ThemeMode build() => _s.mode;

  Future<void> setMode(ThemeMode mode) async {
    state = await _s.setMode(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
