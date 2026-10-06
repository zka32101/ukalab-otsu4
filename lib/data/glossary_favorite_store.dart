import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// お気に入りに登録した用語集の用語名（`GlossaryTerm.term`）の端末内保存。
class GlossaryFavoriteStore {
  static const _key = 'ukalab_otsu4_glossary_favorites';

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

/// 用語集のお気に入りの読み込み・切り替え。`main()` で `load()` してから
/// `glossaryFavoriteServiceProvider.overrideWithValue(...)` で渡す。
class GlossaryFavoriteService {
  GlossaryFavoriteService({GlossaryFavoriteStore? store}) : _store = store ?? GlossaryFavoriteStore();

  final GlossaryFavoriteStore _store;
  Set<String> _terms = {};

  Set<String> get terms => _terms;

  Future<void> load() async {
    _terms = await _store.read();
  }

  /// 用語集カードのお気に入りアイコンをタップしたときに呼ぶ。
  Future<Set<String>> toggle(String term) async {
    _terms = {..._terms};
    if (!_terms.remove(term)) _terms.add(term);
    await _store.write(_terms);
    return _terms;
  }
}

final glossaryFavoriteServiceProvider = Provider<GlossaryFavoriteService>(
  (ref) => throw UnimplementedError('glossaryFavoriteServiceProvider を override してください'),
);

class GlossaryFavoriteNotifier extends Notifier<Set<String>> {
  GlossaryFavoriteService get _s => ref.read(glossaryFavoriteServiceProvider);

  @override
  Set<String> build() => _s.terms;

  Future<void> toggle(String term) async {
    state = await _s.toggle(term);
  }
}

final glossaryFavoriteProvider =
    NotifierProvider<GlossaryFavoriteNotifier, Set<String>>(GlossaryFavoriteNotifier.new);
