import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 模擬試験1回分の結果。
class MockHistoryEntry {
  const MockHistoryEntry({
    required this.at,
    required this.score,
    required this.max,
    required this.passed,
  });

  final DateTime at;
  final int score;
  final int max;
  final bool passed;

  /// 得点率（%）。満点が0なら0。
  double get pct => max == 0 ? 0 : score * 100 / max;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'score': score,
        'max': max,
        'passed': passed,
      };

  static MockHistoryEntry fromJson(Map<String, dynamic> json) => MockHistoryEntry(
        at: DateTime.parse(json['at'] as String),
        score: json['score'] as int,
        max: json['max'] as int,
        passed: json['passed'] as bool,
      );
}

/// 模擬試験の結果履歴（端末内保存）。
class MockHistoryStore {
  static const _key = 'ukalab_otsu4_mock_history';

  /// 保持する件数の上限（古いものから捨てる）。
  static const maxEntries = 50;

  Future<List<MockHistoryEntry>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [for (final j in list) MockHistoryEntry.fromJson(j as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  Future<void> write(List<MockHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final e in entries) e.toJson()]));
  }
}

/// 模擬試験の結果履歴の読み込み・追加。`main()` で `load()` してから
/// `mockHistoryServiceProvider.overrideWithValue(...)` で渡す。
class MockHistoryService {
  MockHistoryService({MockHistoryStore? store}) : _store = store ?? MockHistoryStore();

  final MockHistoryStore _store;
  List<MockHistoryEntry> _history = [];

  /// 古い順。
  List<MockHistoryEntry> get history => _history;

  Future<void> load() async {
    _history = await _store.read();
  }

  /// 模擬試験を終えたときに呼ぶ。
  Future<List<MockHistoryEntry>> add(MockHistoryEntry entry) async {
    _history = [..._history, entry];
    if (_history.length > MockHistoryStore.maxEntries) {
      _history = _history.sublist(_history.length - MockHistoryStore.maxEntries);
    }
    await _store.write(_history);
    return _history;
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<List<MockHistoryEntry>> reset() async {
    _history = [];
    await _store.write(_history);
    return _history;
  }

  /// バックアップの読み込み時に呼ぶ。[history] で上書きする。
  Future<List<MockHistoryEntry>> restore(List<MockHistoryEntry> history) async {
    _history = history;
    await _store.write(_history);
    return _history;
  }
}

final mockHistoryServiceProvider = Provider<MockHistoryService>(
  (ref) => throw UnimplementedError('mockHistoryServiceProvider を override してください'),
);

class MockHistoryNotifier extends Notifier<List<MockHistoryEntry>> {
  MockHistoryService get _s => ref.read(mockHistoryServiceProvider);

  @override
  List<MockHistoryEntry> build() => _s.history;

  Future<void> add(MockHistoryEntry entry) async {
    state = await _s.add(entry);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(List<MockHistoryEntry> history) async {
    state = await _s.restore(history);
  }
}

final mockHistoryProvider =
    NotifierProvider<MockHistoryNotifier, List<MockHistoryEntry>>(MockHistoryNotifier.new);

/// 直近の模試結果から、合格ラインへの到達見込みを示す簡易判定。
enum PassPrediction {
  /// 直近の平均得点率が合格ライン以上。
  onTrack,

  /// 合格ラインまで10ポイント未満。
  closeToTarget,

  /// 合格ラインまで10ポイント以上の開きがある。
  needsWork,
}

/// 直近3回（無ければそれ以下）の模試の平均得点率から、合格ラインへの
/// 到達見込みを判定する。[history] は空であってはならない。
PassPrediction predictPassTrend(List<MockHistoryEntry> history, {required double passPct}) {
  final recent = history.length > 3 ? history.sublist(history.length - 3) : history;
  final avgPct = recent.map((e) => e.pct).reduce((a, b) => a + b) / recent.length;
  if (avgPct >= passPct) return PassPrediction.onTrack;
  if (avgPct >= passPct - 10) return PassPrediction.closeToTarget;
  return PassPrediction.needsWork;
}

/// 前回の模試からの経過日数が [days] 以上であれば、受験間隔のリマインダーを
/// 表示するべきかどうか。模試をまだ受けていなければ表示しない（未経験者を
/// 急かさない）。[history] は古い順（最後の要素が直近）。
bool shouldShowMockIntervalReminder(
  List<MockHistoryEntry> history,
  DateTime now, {
  int days = 7,
}) {
  if (history.isEmpty) return false;
  final last = history.last.at;
  final today = DateTime(now.year, now.month, now.day);
  final lastDay = DateTime(last.year, last.month, last.day);
  return today.difference(lastDay).inDays >= days;
}

/// 前回の模試から [days] 日後を、次回の模試の目安日として返す（日付のみ）。
/// [history] が空（模試を一度も受けていない）なら null。
DateTime? nextRecommendedMockDate(List<MockHistoryEntry> history, {int days = 7}) {
  if (history.isEmpty) return null;
  final last = history.last.at;
  final lastDay = DateTime(last.year, last.month, last.day);
  return lastDay.add(Duration(days: days));
}

/// ホームに表示する、次回の模試の目安の表示文言。
String nextMockDateText(DateTime recommended, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(recommended.year, recommended.month, recommended.day);
  final diff = day.difference(today).inDays;
  final dateLabel = '${day.month}/${day.day}';
  if (diff > 0) return '次回の模試の目安は$dateLabel（あと$diff日）です';
  if (diff == 0) return '次回の模試の目安は今日（$dateLabel）です';
  return '次回の模試の目安（$dateLabel）を過ぎています';
}
