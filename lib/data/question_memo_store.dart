import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

/// 問題ごとの自分用メモ（qid -> メモ本文）の端末内保存。
class QuestionMemoStore {
  static const _key = 'ukalab_otsu4_question_memos';

  Future<Map<String, String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> write(Map<String, String> memos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(memos));
  }
}

/// 問題メモの読み込み・更新。`main()` で `load()` してから
/// `questionMemoServiceProvider.overrideWithValue(...)` で渡す。
class QuestionMemoService {
  QuestionMemoService({QuestionMemoStore? store}) : _store = store ?? QuestionMemoStore();

  final QuestionMemoStore _store;
  Map<String, String> _memos = {};

  Map<String, String> get memos => _memos;

  Future<void> load() async {
    _memos = await _store.read();
  }

  /// メモを保存する。空文字（トリム後）なら削除する。
  Future<Map<String, String>> setMemo({required String qid, required String memo}) async {
    final trimmed = memo.trim();
    _memos = {..._memos};
    if (trimmed.isEmpty) {
      _memos.remove(qid);
    } else {
      _memos[qid] = trimmed;
    }
    await _store.write(_memos);
    return _memos;
  }
}

final questionMemoServiceProvider = Provider<QuestionMemoService>(
  (ref) => throw UnimplementedError('questionMemoServiceProvider を override してください'),
);

class QuestionMemoNotifier extends Notifier<Map<String, String>> {
  QuestionMemoService get _s => ref.read(questionMemoServiceProvider);

  @override
  Map<String, String> build() => _s.memos;

  Future<void> setMemo({required String qid, required String memo}) async {
    state = await _s.setMemo(qid: qid, memo: memo);
  }
}

final questionMemoProvider =
    NotifierProvider<QuestionMemoNotifier, Map<String, String>>(QuestionMemoNotifier.new);

/// メモが書かれている問題（[memos] にqidがあるもの）のうち、[keyword] が
/// 問題文またはメモ本文に含まれるものを返す。空のキーワードならメモがある
/// 全問題を返す。
List<Question> filterMemoedQuestions(
  List<Question> pool,
  Map<String, String> memos,
  String keyword,
) {
  final memoed = [for (final q in pool) if (memos.containsKey(q.qid)) q];
  final kw = keyword.trim();
  if (kw.isEmpty) return memoed;
  return [
    for (final q in memoed)
      if (q.prompt.contains(kw) || (memos[q.qid] ?? '').contains(kw)) q,
  ];
}
