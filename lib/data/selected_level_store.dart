import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ukalab_core.dart';

/// 選択中の類（`ExamConfig.levels` の `levelId`）の端末内保存。乙4アプリに
/// 複数類（乙1〜乙6）対応を検証する最初の一歩として、乙4・乙1の2類だけを
/// 切り替えられるようにする（README参照）。`ukalab_core` の `ExamConfig` は
/// 既に1つの試験に複数の `LevelConfig` を持てる設計のため、パッケージ側の
/// 変更は不要で、このストアと `currentLevel` ヘルパーだけで対応できた。
class SelectedLevelStore {
  static const _key = 'ukalab_otsu4_selected_level_id';

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> write(String? levelId) async {
    final prefs = await SharedPreferences.getInstance();
    if (levelId == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, levelId);
    }
  }
}

/// 選択中の類の読み込み・変更。`main()` で `load()` してから
/// `selectedLevelServiceProvider.overrideWithValue(...)` で渡す。
class SelectedLevelService {
  SelectedLevelService({SelectedLevelStore? store}) : _store = store ?? SelectedLevelStore();

  final SelectedLevelStore _store;
  String? _levelId;

  /// 未選択（初回起動等）なら null。null の場合は `ExamConfig.levels.first` を使う。
  String? get levelId => _levelId;

  Future<void> load() async {
    _levelId = await _store.read();
  }

  Future<String?> select(String? levelId) async {
    _levelId = levelId;
    await _store.write(levelId);
    return _levelId;
  }
}

final selectedLevelServiceProvider = Provider<SelectedLevelService>(
  (ref) => throw UnimplementedError('selectedLevelServiceProvider を override してください'),
);

class SelectedLevelNotifier extends Notifier<String?> {
  SelectedLevelService get _s => ref.read(selectedLevelServiceProvider);

  @override
  String? build() => _s.levelId;

  Future<void> select(String? levelId) async {
    state = await _s.select(levelId);
  }
}

final selectedLevelIdProvider =
    NotifierProvider<SelectedLevelNotifier, String?>(SelectedLevelNotifier.new);

/// 選択中の [LevelConfig] を返す。選択されていない、又は選択中のIDが
/// 現在の `ExamConfig` に存在しない場合は `exam.levels.first`（従来の挙動）
/// にフォールバックする。
LevelConfig currentLevel(ExamConfig exam, String? selectedLevelId) {
  if (selectedLevelId != null) {
    final match = exam.level(selectedLevelId);
    if (match != null) return match;
  }
  return exam.levels.first;
}
