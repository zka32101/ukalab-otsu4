import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// これまでに解除を検知した実績バッジID→その時点の日時。
/// 解除時スナックバー通知の重複防止と、実績一覧での獲得日表示の両方に使う。
class AchievementUnlockStore {
  static const _key = 'ukalab_otsu4_notified_achievement_ids';

  Future<Map<String, DateTime>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {for (final e in map.entries) e.key: DateTime.parse(e.value as String)};
    } catch (_) {
      return {};
    }
  }

  Future<void> write(Map<String, DateTime> unlockedAt) async {
    final prefs = await SharedPreferences.getInstance();
    final json = {for (final e in unlockedAt.entries) e.key: e.value.toIso8601String()};
    await prefs.setString(_key, jsonEncode(json));
  }
}

/// 実績解除日時の読み込み・更新。`main()` で `load()` してから
/// `achievementUnlockServiceProvider.overrideWithValue(...)` で渡す。
class AchievementUnlockService {
  AchievementUnlockService({AchievementUnlockStore? store}) : _store = store ?? AchievementUnlockStore();

  final AchievementUnlockStore _store;
  Map<String, DateTime> _unlockedAt = const {};

  Map<String, DateTime> get unlockedAt => _unlockedAt;
  Set<String> get notifiedIds => _unlockedAt.keys.toSet();

  Future<void> load() async {
    _unlockedAt = await _store.read();
  }

  Future<void> markNotified(Set<String> ids, DateTime now) async {
    _unlockedAt = {..._unlockedAt, for (final id in ids) id: now};
    await _store.write(_unlockedAt);
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<void> reset() async {
    _unlockedAt = const {};
    await _store.write(_unlockedAt);
  }
}

final achievementUnlockServiceProvider = Provider<AchievementUnlockService>(
  (ref) => throw UnimplementedError('achievementUnlockServiceProvider を override してください'),
);

class AchievementUnlockNotifier extends Notifier<Map<String, DateTime>> {
  AchievementUnlockService get _s => ref.read(achievementUnlockServiceProvider);

  @override
  Map<String, DateTime> build() => _s.unlockedAt;

  /// [unlockedIds] のうち、まだ記録していないIDを返し、[now] を解除日時として
  /// 記録する。新規に解除されたバッジが無ければ空リストを返す。
  List<String> checkNewlyUnlocked(Set<String> unlockedIds, DateTime now) {
    final newly = [for (final id in unlockedIds) if (!state.containsKey(id)) id];
    if (newly.isEmpty) return const [];
    state = {...state, for (final id in newly) id: now};
    _s.markNotified(newly.toSet(), now);
    return newly;
  }

  Future<void> reset() async {
    await _s.reset();
    state = const {};
  }
}

final achievementUnlockProvider = NotifierProvider<AchievementUnlockNotifier, Map<String, DateTime>>(
  AchievementUnlockNotifier.new,
);
