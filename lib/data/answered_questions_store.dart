import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ukalab_core.dart';

/// これまでに一度でも解答した問題のqid集合（端末内保存）。学ぶタブの
/// 分野別出題網羅率で使う。
class AnsweredQuestionsStore {
  static const _key = 'ukalab_otsu4_answered_qids';

  Future<Set<String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> write(Set<String> qids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(qids.toList()));
  }
}

/// 解答済み問題の読み込み・更新。`main()` で `load()` してから
/// `answeredQuestionsServiceProvider.overrideWithValue(...)` で渡す。
class AnsweredQuestionsService {
  AnsweredQuestionsService({AnsweredQuestionsStore? store}) : _store = store ?? AnsweredQuestionsStore();

  final AnsweredQuestionsStore _store;
  Set<String> _qids = {};

  Set<String> get qids => _qids;

  Future<void> load() async {
    _qids = await _store.read();
  }

  /// 問題に解答したときに呼ぶ。既に記録済みなら何もしない。
  Future<Set<String>> record(String qid) async {
    if (_qids.contains(qid)) return _qids;
    _qids = {..._qids, qid};
    await _store.write(_qids);
    return _qids;
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<Set<String>> reset() async {
    _qids = {};
    await _store.write(_qids);
    return _qids;
  }

  /// バックアップの読み込み時に呼ぶ。[qids] で上書きする。
  Future<Set<String>> restore(Set<String> qids) async {
    _qids = qids;
    await _store.write(_qids);
    return _qids;
  }
}

final answeredQuestionsServiceProvider = Provider<AnsweredQuestionsService>(
  (ref) => throw UnimplementedError('answeredQuestionsServiceProvider を override してください'),
);

class AnsweredQuestionsNotifier extends Notifier<Set<String>> {
  AnsweredQuestionsService get _s => ref.read(answeredQuestionsServiceProvider);

  @override
  Set<String> build() => _s.qids;

  Future<void> record(String qid) async {
    state = await _s.record(qid);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(Set<String> qids) async {
    state = await _s.restore(qids);
  }
}

final answeredQuestionsProvider =
    NotifierProvider<AnsweredQuestionsNotifier, Set<String>>(AnsweredQuestionsNotifier.new);

/// 分野（subjectId）ごとの出題網羅率（0.0〜1.0）。[pool] のうち
/// [answeredQids] に含まれる問題の割合を計算する。
Map<String, double> subjectCoverage(List<Question> pool, Set<String> answeredQids) {
  final totalBySubject = <String, int>{};
  final answeredBySubject = <String, int>{};
  for (final q in pool) {
    totalBySubject[q.subjectId] = (totalBySubject[q.subjectId] ?? 0) + 1;
    if (answeredQids.contains(q.qid)) {
      answeredBySubject[q.subjectId] = (answeredBySubject[q.subjectId] ?? 0) + 1;
    }
  }
  return {
    for (final e in totalBySubject.entries)
      e.key: e.value == 0 ? 0 : (answeredBySubject[e.key] ?? 0) / e.value,
  };
}
