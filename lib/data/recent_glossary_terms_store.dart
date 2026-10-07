import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 最近見た用語集の用語名（新しい順）の記憶上限。
const maxRecentGlossaryTerms = 20;

/// 最近見た用語集の用語名（`GlossaryTerm.term`、新しい順）の端末内保存。
class RecentGlossaryTermsStore {
  static const _key = 'ukalab_otsu4_recent_glossary_terms';

  Future<List<String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> write(List<String> terms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(terms));
  }
}

/// 新しく見た用語 [term] を既存の履歴 [current]（新しい順）の先頭に積む。
/// 既に履歴にある場合は新しい記録の方を残し、件数上限で切り詰める。
List<String> recordRecentGlossaryTerm(List<String> current, String term) {
  final merged = [term, ...current.where((t) => t != term)];
  return merged.take(maxRecentGlossaryTerms).toList();
}

/// 最近見た用語集の用語の読み込み・記録。`main()` で `load()` してから
/// `recentGlossaryTermsServiceProvider.overrideWithValue(...)` で渡す。
class RecentGlossaryTermsService {
  RecentGlossaryTermsService({RecentGlossaryTermsStore? store})
      : _store = store ?? RecentGlossaryTermsStore();

  final RecentGlossaryTermsStore _store;
  List<String> _terms = [];

  List<String> get terms => _terms;

  Future<void> load() async {
    _terms = await _store.read();
  }

  /// 用語集カードで定義を見たときに呼ぶ。
  Future<List<String>> record(String term) async {
    _terms = recordRecentGlossaryTerm(_terms, term);
    await _store.write(_terms);
    return _terms;
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<List<String>> reset() async {
    _terms = [];
    await _store.write(_terms);
    return _terms;
  }
}

final recentGlossaryTermsServiceProvider = Provider<RecentGlossaryTermsService>(
  (ref) => throw UnimplementedError('recentGlossaryTermsServiceProvider を override してください'),
);

class RecentGlossaryTermsNotifier extends Notifier<List<String>> {
  RecentGlossaryTermsService get _s => ref.read(recentGlossaryTermsServiceProvider);

  @override
  List<String> build() => _s.terms;

  Future<void> record(String term) async {
    state = await _s.record(term);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }
}

final recentGlossaryTermsProvider =
    NotifierProvider<RecentGlossaryTermsNotifier, List<String>>(RecentGlossaryTermsNotifier.new);
