import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ある日の解答数・正解数。ホームの「今週の学習サマリー」に使う。
class DailyAnswerStatsEntry {
  const DailyAnswerStatsEntry({required this.date, required this.answered, required this.correct});

  /// 日付のみ（時刻は0:00）。
  final DateTime date;
  final int answered;
  final int correct;

  double get accuracy => answered == 0 ? 0 : correct / answered;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'answered': answered,
        'correct': correct,
      };

  static DailyAnswerStatsEntry fromJson(Map<String, dynamic> json) => DailyAnswerStatsEntry(
        date: DateTime.parse(json['date'] as String),
        answered: json['answered'] as int,
        correct: json['correct'] as int,
      );
}

/// 日別の解答数・正解数の積み上げ（端末内保存）。1日1件、解答するたびに
/// 今日の件数へ加算する。
class DailyAnswerStatsStore {
  static const _key = 'ukalab_otsu4_daily_answer_stats';

  /// 保持する日数の上限（古いものから捨てる）。
  static const maxEntries = 30;

  Future<List<DailyAnswerStatsEntry>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [for (final j in list) DailyAnswerStatsEntry.fromJson(j as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  Future<void> write(List<DailyAnswerStatsEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final e in entries) e.toJson()]));
  }
}

/// 日別の解答数・正解数の読み込み・積み上げ。`main()` で `load()` してから
/// `dailyAnswerStatsServiceProvider.overrideWithValue(...)` で渡す。
class DailyAnswerStatsService {
  DailyAnswerStatsService({DailyAnswerStatsStore? store, DateTime Function()? clock})
      : _store = store ?? DailyAnswerStatsStore(),
        _clock = clock ?? DateTime.now;

  final DailyAnswerStatsStore _store;
  final DateTime Function() _clock;
  List<DailyAnswerStatsEntry> _history = [];

  /// 古い順。
  List<DailyAnswerStatsEntry> get history => _history;

  Future<void> load() async {
    _history = await _store.read();
  }

  /// 一問一答・模擬試験で1問答えるたびに呼ぶ。今日の件数に加算する。
  Future<List<DailyAnswerStatsEntry>> recordAnswer({required bool correct}) async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final todayMatches = _history.where((e) => e.date == today);
    final existing = todayMatches.isEmpty ? null : todayMatches.first;
    final updated = DailyAnswerStatsEntry(
      date: today,
      answered: (existing?.answered ?? 0) + 1,
      correct: (existing?.correct ?? 0) + (correct ? 1 : 0),
    );
    final withoutToday = [for (final e in _history) if (e.date != today) e];
    _history = [...withoutToday, updated]..sort((a, b) => a.date.compareTo(b.date));
    if (_history.length > DailyAnswerStatsStore.maxEntries) {
      _history = _history.sublist(_history.length - DailyAnswerStatsStore.maxEntries);
    }
    await _store.write(_history);
    return _history;
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<List<DailyAnswerStatsEntry>> reset() async {
    _history = [];
    await _store.write(_history);
    return _history;
  }

  /// バックアップの読み込み時に呼ぶ。[history] で上書きする。
  Future<List<DailyAnswerStatsEntry>> restore(List<DailyAnswerStatsEntry> history) async {
    _history = history;
    await _store.write(_history);
    return _history;
  }
}

final dailyAnswerStatsServiceProvider = Provider<DailyAnswerStatsService>(
  (ref) => throw UnimplementedError('dailyAnswerStatsServiceProvider を override してください'),
);

class DailyAnswerStatsNotifier extends Notifier<List<DailyAnswerStatsEntry>> {
  DailyAnswerStatsService get _s => ref.read(dailyAnswerStatsServiceProvider);

  @override
  List<DailyAnswerStatsEntry> build() => _s.history;

  Future<void> recordAnswer({required bool correct}) async {
    state = await _s.recordAnswer(correct: correct);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(List<DailyAnswerStatsEntry> history) async {
    state = await _s.restore(history);
  }
}

final dailyAnswerStatsProvider =
    NotifierProvider<DailyAnswerStatsNotifier, List<DailyAnswerStatsEntry>>(DailyAnswerStatsNotifier.new);

/// [history] から直近7日間（今日を含む）の解答数・正解数を、古い順に返す。
/// データが無い日は0件として埋める。
List<DailyAnswerStatsEntry> weeklyAnswerSummary(
  List<DailyAnswerStatsEntry> history, {
  DateTime? now,
}) {
  final today = () {
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }();
  final byDate = {for (final e in history) e.date: e};
  return [
    for (var i = 6; i >= 0; i--)
      byDate[today.subtract(Duration(days: i))] ??
          DailyAnswerStatsEntry(date: today.subtract(Duration(days: i)), answered: 0, correct: 0),
  ];
}
