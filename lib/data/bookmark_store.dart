import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 気になる問題のブックマーク（qidの集合）の端末内保存。
class BookmarkStore {
  static const _key = 'ukalab_otsu4_bookmarks';

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

/// ブックマークの読み込み・切り替え。`main()` で `load()` してから
/// `bookmarkServiceProvider.overrideWithValue(...)` で渡す。
class BookmarkService {
  BookmarkService({BookmarkStore? store}) : _store = store ?? BookmarkStore();

  final BookmarkStore _store;
  Set<String> _qids = {};

  Set<String> get qids => _qids;

  Future<void> load() async {
    _qids = await _store.read();
  }

  /// 一問一答でブックマークのアイコンをタップしたときに呼ぶ。
  Future<Set<String>> toggle(String qid) async {
    _qids = {..._qids};
    if (!_qids.remove(qid)) _qids.add(qid);
    await _store.write(_qids);
    return _qids;
  }
}

final bookmarkServiceProvider = Provider<BookmarkService>(
  (ref) => throw UnimplementedError('bookmarkServiceProvider を override してください'),
);

class BookmarkNotifier extends Notifier<Set<String>> {
  BookmarkService get _s => ref.read(bookmarkServiceProvider);

  @override
  Set<String> build() => _s.qids;

  Future<void> toggle(String qid) async {
    state = await _s.toggle(qid);
  }
}

final bookmarkProvider = NotifierProvider<BookmarkNotifier, Set<String>>(BookmarkNotifier.new);
