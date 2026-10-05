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
}

final mockHistoryProvider =
    NotifierProvider<MockHistoryNotifier, List<MockHistoryEntry>>(MockHistoryNotifier.new);
