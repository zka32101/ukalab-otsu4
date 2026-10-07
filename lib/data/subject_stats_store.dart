import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 分野（subjectId）1つ分の解答数・正解数。
class SubjectStat {
  const SubjectStat({this.answered = 0, this.correct = 0});

  final int answered;
  final int correct;

  double get accuracy => answered == 0 ? 0 : correct / answered;

  SubjectStat withAnswer({required bool correct}) => SubjectStat(
        answered: answered + 1,
        correct: this.correct + (correct ? 1 : 0),
      );

  Map<String, dynamic> toJson() => {'answered': answered, 'correct': correct};

  static SubjectStat fromJson(Map<String, dynamic> json) => SubjectStat(
        answered: json['answered'] as int? ?? 0,
        correct: json['correct'] as int? ?? 0,
      );
}

/// 分野別の解答数・正解数（端末内保存）。一問一答・模擬試験の両方から
/// subjectId 単位で積み上げる。
class SubjectStatsStore {
  static const _key = 'ukalab_otsu4_subject_stats';

  Future<Map<String, SubjectStat>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {for (final e in map.entries) e.key: SubjectStat.fromJson(e.value as Map<String, dynamic>)};
    } catch (_) {
      return {};
    }
  }

  Future<void> write(Map<String, SubjectStat> stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({for (final e in stats.entries) e.key: e.value.toJson()}));
  }
}

/// 分野別統計の読み込み・更新。`main()` で `load()` してから
/// `subjectStatsServiceProvider.overrideWithValue(...)` で渡す。
class SubjectStatsService {
  SubjectStatsService({SubjectStatsStore? store}) : _store = store ?? SubjectStatsStore();

  final SubjectStatsStore _store;
  Map<String, SubjectStat> _stats = {};

  Map<String, SubjectStat> get stats => _stats;

  Future<void> load() async {
    _stats = await _store.read();
  }

  /// 一問一答・模擬試験で1問答えたときに呼ぶ。
  Future<Map<String, SubjectStat>> recordAnswer({
    required String subjectId,
    required bool correct,
  }) async {
    final current = _stats[subjectId] ?? const SubjectStat();
    _stats = {..._stats, subjectId: current.withAnswer(correct: correct)};
    await _store.write(_stats);
    return _stats;
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<Map<String, SubjectStat>> reset() async {
    _stats = {};
    await _store.write(_stats);
    return _stats;
  }

  /// バックアップの読み込み時に呼ぶ。[stats] で上書きする。
  Future<Map<String, SubjectStat>> restore(Map<String, SubjectStat> stats) async {
    _stats = stats;
    await _store.write(_stats);
    return _stats;
  }
}

final subjectStatsServiceProvider = Provider<SubjectStatsService>(
  (ref) => throw UnimplementedError('subjectStatsServiceProvider を override してください'),
);

class SubjectStatsNotifier extends Notifier<Map<String, SubjectStat>> {
  SubjectStatsService get _s => ref.read(subjectStatsServiceProvider);

  @override
  Map<String, SubjectStat> build() => _s.stats;

  Future<void> recordAnswer({required String subjectId, required bool correct}) async {
    state = await _s.recordAnswer(subjectId: subjectId, correct: correct);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(Map<String, SubjectStat> stats) async {
    state = await _s.restore(stats);
  }
}

final subjectStatsProvider =
    NotifierProvider<SubjectStatsNotifier, Map<String, SubjectStat>>(SubjectStatsNotifier.new);

/// 「苦手分野」とみなす最低解答数。これ未満の分野は判定の対象にしない
/// （数問だけ間違えて苦手と判定されるのを避ける）。
const weakSubjectMinAnswered = 5;

/// 「苦手分野」とみなす正答率のしきい値（これ未満）。
const weakSubjectAccuracyThreshold = 0.6;

/// 解答数が十分あり、正答率がしきい値未満の分野のsubjectId。
/// 「集中特訓」（苦手分野の優先出題）で使う。
List<String> weakSubjectIds(Map<String, SubjectStat> stats) => [
      for (final e in stats.entries)
        if (e.value.answered >= weakSubjectMinAnswered &&
            e.value.accuracy < weakSubjectAccuracyThreshold)
          e.key,
    ];
