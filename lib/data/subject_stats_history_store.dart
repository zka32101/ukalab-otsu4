import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'subject_stats_store.dart';

/// ある日時点での、分野別累積正答率のスナップショット。
class SubjectStatsHistoryEntry {
  const SubjectStatsHistoryEntry({required this.date, required this.accuracyBySubject});

  /// 日付のみ（時刻は0:00）。
  final DateTime date;
  final Map<String, double> accuracyBySubject;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'accuracyBySubject': accuracyBySubject,
      };

  static SubjectStatsHistoryEntry fromJson(Map<String, dynamic> json) => SubjectStatsHistoryEntry(
        date: DateTime.parse(json['date'] as String),
        accuracyBySubject: (json['accuracyBySubject'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      );
}

/// 分野別正答率の推移（端末内保存）。1日1件、最新の累積正答率で上書きする。
class SubjectStatsHistoryStore {
  static const _key = 'ukalab_otsu4_subject_stats_history';

  /// 保持する日数の上限（古いものから捨てる）。
  static const maxEntries = 30;

  Future<List<SubjectStatsHistoryEntry>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [for (final j in list) SubjectStatsHistoryEntry.fromJson(j as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  Future<void> write(List<SubjectStatsHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final e in entries) e.toJson()]));
  }
}

/// 分野別正答率の推移の読み込み・記録。`main()` で `load()` してから
/// `subjectStatsHistoryServiceProvider.overrideWithValue(...)` で渡す。
class SubjectStatsHistoryService {
  SubjectStatsHistoryService({SubjectStatsHistoryStore? store, DateTime Function()? clock})
      : _store = store ?? SubjectStatsHistoryStore(),
        _clock = clock ?? DateTime.now;

  final SubjectStatsHistoryStore _store;
  final DateTime Function() _clock;
  List<SubjectStatsHistoryEntry> _history = [];

  /// 古い順。
  List<SubjectStatsHistoryEntry> get history => _history;

  Future<void> load() async {
    _history = await _store.read();
  }

  DateTime _today() {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  /// 一問一答・模擬試験で解答した直後、最新の分野別統計を渡して呼ぶ。
  /// 今日の日付のスナップショットを最新の値で置き換える（同日複数回は上書き）。
  Future<List<SubjectStatsHistoryEntry>> recordSnapshot(Map<String, SubjectStat> stats) async {
    final today = _today();
    final accuracy = {for (final e in stats.entries) e.key: e.value.accuracy};
    final withoutToday = [for (final e in _history) if (e.date != today) e];
    _history = [...withoutToday, SubjectStatsHistoryEntry(date: today, accuracyBySubject: accuracy)]
      ..sort((a, b) => a.date.compareTo(b.date));
    if (_history.length > SubjectStatsHistoryStore.maxEntries) {
      _history = _history.sublist(_history.length - SubjectStatsHistoryStore.maxEntries);
    }
    await _store.write(_history);
    return _history;
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<List<SubjectStatsHistoryEntry>> reset() async {
    _history = [];
    await _store.write(_history);
    return _history;
  }

  /// バックアップの読み込み時に呼ぶ。[history] で上書きする。
  Future<List<SubjectStatsHistoryEntry>> restore(List<SubjectStatsHistoryEntry> history) async {
    _history = history;
    await _store.write(_history);
    return _history;
  }
}

final subjectStatsHistoryServiceProvider = Provider<SubjectStatsHistoryService>(
  (ref) => throw UnimplementedError('subjectStatsHistoryServiceProvider を override してください'),
);

class SubjectStatsHistoryNotifier extends Notifier<List<SubjectStatsHistoryEntry>> {
  SubjectStatsHistoryService get _s => ref.read(subjectStatsHistoryServiceProvider);

  @override
  List<SubjectStatsHistoryEntry> build() => _s.history;

  Future<void> recordSnapshot(Map<String, SubjectStat> stats) async {
    state = await _s.recordSnapshot(stats);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(List<SubjectStatsHistoryEntry> history) async {
    state = await _s.restore(history);
  }
}

final subjectStatsHistoryProvider =
    NotifierProvider<SubjectStatsHistoryNotifier, List<SubjectStatsHistoryEntry>>(
        SubjectStatsHistoryNotifier.new);
