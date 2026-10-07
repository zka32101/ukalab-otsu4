import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 推しの成長・コインに使う、このアプリの暫定の学習進捗。
///
/// 正式な出題範囲（`yourwish_kentei` の `Question`）はまだ無い（問題データ未着手。
/// README参照）ため、画期的な機能A〜E・一問一答での解答数を暫定の進捗として使う。
/// 問題データが入ったら、`yourwish_kentei` の網羅率・正答率に基づく計算に
/// 差し替える（`MasteryModel` 自体が差し替え可能な暫定値であることに合わせている）。
class ProgressSnapshot {
  const ProgressSnapshot({
    this.answered = 0,
    this.correct = 0,
    this.streakDays = 0,
    this.lastStudyDate,
  });

  final int answered;
  final int correct;
  final int streakDays;
  final DateTime? lastStudyDate;

  /// 網羅率の代わりの暫定指標。100問相当で頭打ちにする。
  double get coverage => answered <= 0 ? 0 : (answered / 100).clamp(0, 1).toDouble();

  double get accuracy => answered <= 0 ? 0 : correct / answered;

  ProgressSnapshot copyWith({
    int? answered,
    int? correct,
    int? streakDays,
    DateTime? lastStudyDate,
  }) =>
      ProgressSnapshot(
        answered: answered ?? this.answered,
        correct: correct ?? this.correct,
        streakDays: streakDays ?? this.streakDays,
        lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      );

  Map<String, dynamic> toJson() => {
        'answered': answered,
        'correct': correct,
        'streakDays': streakDays,
        'lastStudyDate': lastStudyDate?.toIso8601String(),
      };

  static ProgressSnapshot fromJson(Map<String, dynamic> json) => ProgressSnapshot(
        answered: json['answered'] as int? ?? 0,
        correct: json['correct'] as int? ?? 0,
        streakDays: json['streakDays'] as int? ?? 0,
        lastStudyDate: json['lastStudyDate'] == null
            ? null
            : DateTime.parse(json['lastStudyDate'] as String),
      );
}

/// 端末内の保存。
class ProgressStore {
  static const _key = 'ukalab_otsu4_progress';

  Future<ProgressSnapshot> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const ProgressSnapshot();
    try {
      return ProgressSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ProgressSnapshot();
    }
  }

  Future<void> write(ProgressSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snapshot.toJson()));
  }
}

/// 進捗の読み込み・更新。`main()` で `load()` してから
/// `progressServiceProvider.overrideWithValue(...)` で渡す。
class ProgressService {
  ProgressService({ProgressStore? store, DateTime Function()? clock})
      : _store = store ?? ProgressStore(),
        _clock = clock ?? DateTime.now;

  final ProgressStore _store;
  final DateTime Function() _clock;
  ProgressSnapshot _snapshot = const ProgressSnapshot();

  ProgressSnapshot get snapshot => _snapshot;

  Future<void> load() async {
    _snapshot = await _store.read();
  }

  /// 演習（一問一答・画期的な機能A〜E）で1問答えたときに呼ぶ。
  Future<ProgressSnapshot> recordAnswer({required bool correct}) async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final last = _snapshot.lastStudyDate;
    final gap = last == null ? null : today.difference(last).inDays;
    final streak = gap == 0 ? _snapshot.streakDays : (gap == 1 ? _snapshot.streakDays + 1 : 1);
    _snapshot = _snapshot.copyWith(
      answered: _snapshot.answered + 1,
      correct: _snapshot.correct + (correct ? 1 : 0),
      streakDays: streak,
      lastStudyDate: today,
    );
    await _store.write(_snapshot);
    return _snapshot;
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<ProgressSnapshot> reset() async {
    _snapshot = const ProgressSnapshot();
    await _store.write(_snapshot);
    return _snapshot;
  }

  /// バックアップの読み込み時に呼ぶ。[snapshot] で上書きする。
  Future<ProgressSnapshot> restore(ProgressSnapshot snapshot) async {
    _snapshot = snapshot;
    await _store.write(_snapshot);
    return _snapshot;
  }
}

/// アプリ側で `main()` で読み込んだインスタンスに上書きして使う。
final progressServiceProvider = Provider<ProgressService>(
  (ref) => throw UnimplementedError('progressServiceProvider を override してください'),
);

class ProgressNotifier extends Notifier<ProgressSnapshot> {
  ProgressService get _s => ref.read(progressServiceProvider);

  @override
  ProgressSnapshot build() => _s.snapshot;

  Future<void> recordAnswer({required bool correct}) async {
    state = await _s.recordAnswer(correct: correct);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(ProgressSnapshot snapshot) async {
    state = await _s.restore(snapshot);
  }
}

final progressProvider = NotifierProvider<ProgressNotifier, ProgressSnapshot>(ProgressNotifier.new);
