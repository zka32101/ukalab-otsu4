import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 「覚えた」と自己申告した用語集の用語名（`GlossaryTerm.term`）の端末内保存。
/// お気に入り（`glossary_favorite_store.dart`）とは独立した仕組みで、暗記の
/// 進み具合を自己管理するために使う。
class GlossaryMasteredStore {
  static const _key = 'ukalab_otsu4_glossary_mastered';

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

  Future<void> write(Set<String> terms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(terms.toList()));
  }
}

/// 用語集の「覚えた」フラグの読み込み・切り替え。`main()` で `load()` してから
/// `glossaryMasteredServiceProvider.overrideWithValue(...)` で渡す。
class GlossaryMasteredService {
  GlossaryMasteredService({GlossaryMasteredStore? store}) : _store = store ?? GlossaryMasteredStore();

  final GlossaryMasteredStore _store;
  Set<String> _terms = {};

  Set<String> get terms => _terms;

  Future<void> load() async {
    _terms = await _store.read();
  }

  /// 用語集カードの「覚えた」アイコンをタップしたときに呼ぶ。
  Future<Set<String>> toggle(String term) async {
    _terms = {..._terms};
    if (!_terms.remove(term)) _terms.add(term);
    await _store.write(_terms);
    return _terms;
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<Set<String>> reset() async {
    _terms = {};
    await _store.write(_terms);
    return _terms;
  }

  /// バックアップの読み込み時に呼ぶ。[terms] で上書きする。
  Future<Set<String>> restore(Set<String> terms) async {
    _terms = terms;
    await _store.write(_terms);
    return _terms;
  }
}

final glossaryMasteredServiceProvider = Provider<GlossaryMasteredService>(
  (ref) => throw UnimplementedError('glossaryMasteredServiceProvider を override してください'),
);

class GlossaryMasteredNotifier extends Notifier<Set<String>> {
  GlossaryMasteredService get _s => ref.read(glossaryMasteredServiceProvider);

  @override
  Set<String> build() => _s.terms;

  Future<void> toggle(String term) async {
    state = await _s.toggle(term);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(Set<String> terms) async {
    state = await _s.restore(terms);
  }
}

final glossaryMasteredProvider =
    NotifierProvider<GlossaryMasteredNotifier, Set<String>>(GlossaryMasteredNotifier.new);
