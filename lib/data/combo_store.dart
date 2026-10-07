import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 一問一答の連続正解数（コンボ）の自己最高記録の端末内保存。
class ComboStore {
  static const _key = 'ukalab_otsu4_best_combo';

  Future<int> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  Future<void> write(int bestCombo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, bestCombo);
  }
}

/// 自己最高コンボの読み込み・更新。`main()` で `load()` してから
/// `comboServiceProvider.overrideWithValue(...)` で渡す。
class ComboService {
  ComboService({ComboStore? store}) : _store = store ?? ComboStore();

  final ComboStore _store;
  int _bestCombo = 0;

  int get bestCombo => _bestCombo;

  Future<void> load() async {
    _bestCombo = await _store.read();
  }

  /// 一問一答で正解したときに、現在のコンボ数を渡して呼ぶ。自己最高を
  /// 更新したときだけ保存する。
  Future<int> recordCombo(int combo) async {
    if (combo <= _bestCombo) return _bestCombo;
    _bestCombo = combo;
    await _store.write(_bestCombo);
    return _bestCombo;
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<int> reset() async {
    _bestCombo = 0;
    await _store.write(_bestCombo);
    return _bestCombo;
  }

  /// バックアップの読み込み時に呼ぶ。自己最高の判定を介さず [bestCombo] で上書きする。
  Future<int> restore(int bestCombo) async {
    _bestCombo = bestCombo;
    await _store.write(_bestCombo);
    return _bestCombo;
  }
}

final comboServiceProvider = Provider<ComboService>(
  (ref) => throw UnimplementedError('comboServiceProvider を override してください'),
);

class ComboNotifier extends Notifier<int> {
  ComboService get _s => ref.read(comboServiceProvider);

  @override
  int build() => _s.bestCombo;

  Future<void> recordCombo(int combo) async {
    state = await _s.recordCombo(combo);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(int bestCombo) async {
    state = await _s.restore(bestCombo);
  }
}

final comboProvider = NotifierProvider<ComboNotifier, int>(ComboNotifier.new);
