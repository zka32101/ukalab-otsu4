import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// これまでにホーム等で通知済みの実績バッジID（解除時スナックバー表示の重複防止）。
class AchievementUnlockStore {
  static const _key = 'ukalab_otsu4_notified_achievement_ids';

  Future<Set<String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const []).toSet();
  }

  Future<void> write(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }
}

/// 通知済み実績IDの読み込み・更新。`main()` で `load()` してから
/// `achievementUnlockServiceProvider.overrideWithValue(...)` で渡す。
class AchievementUnlockService {
  AchievementUnlockService({AchievementUnlockStore? store}) : _store = store ?? AchievementUnlockStore();

  final AchievementUnlockStore _store;
  Set<String> _notifiedIds = const {};

  Set<String> get notifiedIds => _notifiedIds;

  Future<void> load() async {
    _notifiedIds = await _store.read();
  }

  Future<void> markNotified(Set<String> ids) async {
    _notifiedIds = {..._notifiedIds, ...ids};
    await _store.write(_notifiedIds);
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<void> reset() async {
    _notifiedIds = const {};
    await _store.write(_notifiedIds);
  }
}

final achievementUnlockServiceProvider = Provider<AchievementUnlockService>(
  (ref) => throw UnimplementedError('achievementUnlockServiceProvider を override してください'),
);

class AchievementUnlockNotifier extends Notifier<Set<String>> {
  AchievementUnlockService get _s => ref.read(achievementUnlockServiceProvider);

  @override
  Set<String> build() => _s.notifiedIds;

  /// [unlockedIds] のうち、まだ通知していないIDを返し、通知済みとして記録する。
  /// 新規に解除されたバッジが無ければ空リストを返す。
  List<String> checkNewlyUnlocked(Set<String> unlockedIds) {
    final newly = [for (final id in unlockedIds) if (!state.contains(id)) id];
    if (newly.isEmpty) return const [];
    state = {...state, ...newly};
    _s.markNotified(newly.toSet());
    return newly;
  }

  Future<void> reset() async {
    await _s.reset();
    state = const {};
  }
}

final achievementUnlockProvider = NotifierProvider<AchievementUnlockNotifier, Set<String>>(
  AchievementUnlockNotifier.new,
);
