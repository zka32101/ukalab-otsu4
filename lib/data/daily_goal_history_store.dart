import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ある日のデイリーミッションの達成状況のスナップショット。
class DailyGoalHistoryEntry {
  const DailyGoalHistoryEntry({required this.date, required this.count, required this.achieved});

  /// 日付のみ（時刻は0:00）。
  final DateTime date;

  /// その日に解答した問題数。
  final int count;

  /// その日に目標を達成したか。
  final bool achieved;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'count': count,
        'achieved': achieved,
      };

  static DailyGoalHistoryEntry fromJson(Map<String, dynamic> json) => DailyGoalHistoryEntry(
        date: DateTime.parse(json['date'] as String),
        count: json['count'] as int,
        achieved: json['achieved'] as bool,
      );
}

/// デイリーミッションの達成履歴（端末内保存）。1日1件、最新の解答数で上書きする。
class DailyGoalHistoryStore {
  static const _key = 'ukalab_otsu4_daily_goal_history';

  /// 保持する日数の上限（古いものから捨てる）。
  static const maxEntries = 30;

  Future<List<DailyGoalHistoryEntry>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [for (final j in list) DailyGoalHistoryEntry.fromJson(j as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  Future<void> write(List<DailyGoalHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final e in entries) e.toJson()]));
  }
}

/// デイリーミッションの達成履歴の読み込み・記録。`main()` で `load()` してから
/// `dailyGoalHistoryServiceProvider.overrideWithValue(...)` で渡す。
class DailyGoalHistoryService {
  DailyGoalHistoryService({DailyGoalHistoryStore? store}) : _store = store ?? DailyGoalHistoryStore();

  final DailyGoalHistoryStore _store;
  List<DailyGoalHistoryEntry> _history = [];

  /// 古い順。
  List<DailyGoalHistoryEntry> get history => _history;

  Future<void> load() async {
    _history = await _store.read();
  }

  /// 一問一答・模擬試験で解答した直後、今日の最新の解答数・達成状況を渡して
  /// 呼ぶ。今日の日付のスナップショットを最新の値で置き換える。
  Future<List<DailyGoalHistoryEntry>> recordSnapshot({
    required DateTime date,
    required int count,
    required bool achieved,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final withoutToday = [for (final e in _history) if (e.date != day) e];
    _history = [...withoutToday, DailyGoalHistoryEntry(date: day, count: count, achieved: achieved)]
      ..sort((a, b) => a.date.compareTo(b.date));
    if (_history.length > DailyGoalHistoryStore.maxEntries) {
      _history = _history.sublist(_history.length - DailyGoalHistoryStore.maxEntries);
    }
    await _store.write(_history);
    return _history;
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<List<DailyGoalHistoryEntry>> reset() async {
    _history = [];
    await _store.write(_history);
    return _history;
  }

  /// バックアップの読み込み時に呼ぶ。[history] で上書きする。
  Future<List<DailyGoalHistoryEntry>> restore(List<DailyGoalHistoryEntry> history) async {
    _history = history;
    await _store.write(_history);
    return _history;
  }
}

final dailyGoalHistoryServiceProvider = Provider<DailyGoalHistoryService>(
  (ref) => throw UnimplementedError('dailyGoalHistoryServiceProvider を override してください'),
);

class DailyGoalHistoryNotifier extends Notifier<List<DailyGoalHistoryEntry>> {
  DailyGoalHistoryService get _s => ref.read(dailyGoalHistoryServiceProvider);

  @override
  List<DailyGoalHistoryEntry> build() => _s.history;

  Future<void> recordSnapshot({required DateTime date, required int count, required bool achieved}) async {
    state = await _s.recordSnapshot(date: date, count: count, achieved: achieved);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(List<DailyGoalHistoryEntry> history) async {
    state = await _s.restore(history);
  }
}

final dailyGoalHistoryProvider =
    NotifierProvider<DailyGoalHistoryNotifier, List<DailyGoalHistoryEntry>>(DailyGoalHistoryNotifier.new);
