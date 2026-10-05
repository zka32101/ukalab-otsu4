import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 今日の目標問題数と、その達成状況。
class DailyGoal {
  const DailyGoal({this.target, this.todayCount = 0, this.todayDate});

  /// 1日あたりの目標問題数。未設定（オフ）なら null。
  final int? target;

  /// 今日すでに解答した問題数。
  final int todayCount;

  /// [todayCount] の対象日（日付のみ）。
  final DateTime? todayDate;

  bool get achieved => target != null && todayCount >= target!;

  DailyGoal copyWith({int? target, bool clearTarget = false, int? todayCount, DateTime? todayDate}) =>
      DailyGoal(
        target: clearTarget ? null : (target ?? this.target),
        todayCount: todayCount ?? this.todayCount,
        todayDate: todayDate ?? this.todayDate,
      );

  Map<String, dynamic> toJson() => {
        'target': target,
        'todayCount': todayCount,
        'todayDate': todayDate?.toIso8601String(),
      };

  static DailyGoal fromJson(Map<String, dynamic> json) => DailyGoal(
        target: json['target'] as int?,
        todayCount: json['todayCount'] as int? ?? 0,
        todayDate: json['todayDate'] == null ? null : DateTime.parse(json['todayDate'] as String),
      );
}

/// デイリーミッション（今日の目標問題数）の端末内保存。
class DailyGoalStore {
  static const _key = 'ukalab_otsu4_daily_goal';

  Future<DailyGoal> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const DailyGoal();
    try {
      return DailyGoal.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const DailyGoal();
    }
  }

  Future<void> write(DailyGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(goal.toJson()));
  }
}

/// デイリーミッションの読み込み・更新。`main()` で `load()` してから
/// `dailyGoalServiceProvider.overrideWithValue(...)` で渡す。
class DailyGoalService {
  DailyGoalService({DailyGoalStore? store, DateTime Function()? clock})
      : _store = store ?? DailyGoalStore(),
        _clock = clock ?? DateTime.now;

  final DailyGoalStore _store;
  final DateTime Function() _clock;
  DailyGoal _goal = const DailyGoal();

  DailyGoal get goal => _goal;

  Future<void> load() async {
    _goal = _resetIfNewDay(await _store.read());
  }

  DailyGoal _resetIfNewDay(DailyGoal goal) {
    final today = _today();
    if (goal.todayDate == today) return goal;
    return goal.copyWith(todayCount: 0, todayDate: today);
  }

  DateTime _today() {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  /// 目標問題数を設定する。null で目標をオフにする。
  Future<DailyGoal> setTarget(int? target) async {
    _goal = _resetIfNewDay(_goal).copyWith(target: target, clearTarget: target == null);
    await _store.write(_goal);
    return _goal;
  }

  /// 一問一答・模擬試験で1問答えたときに呼ぶ。
  Future<DailyGoal> recordAnswer() async {
    final reset = _resetIfNewDay(_goal);
    _goal = reset.copyWith(todayCount: reset.todayCount + 1);
    await _store.write(_goal);
    return _goal;
  }
}

final dailyGoalServiceProvider = Provider<DailyGoalService>(
  (ref) => throw UnimplementedError('dailyGoalServiceProvider を override してください'),
);

class DailyGoalNotifier extends Notifier<DailyGoal> {
  DailyGoalService get _s => ref.read(dailyGoalServiceProvider);

  @override
  DailyGoal build() => _s.goal;

  Future<void> setTarget(int? target) async {
    state = await _s.setTarget(target);
  }

  Future<void> recordAnswer() async {
    state = await _s.recordAnswer();
  }
}

final dailyGoalProvider = NotifierProvider<DailyGoalNotifier, DailyGoal>(DailyGoalNotifier.new);
