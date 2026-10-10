import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ブックマークした問題（qid）に付けるタグ（qid → タグ名の集合）の端末内保存。
/// ブックマーク自体と同様にユーザー設定・curationとして扱い、学習記録の
/// リセット・バックアップの対象には含めない（`lib/data/data_reset.dart`・
/// `lib/data/data_backup.dart` 参照）。
class BookmarkTagStore {
  static const _key = 'ukalab_otsu4_bookmark_tags';

  Future<Map<String, Set<String>>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in map.entries) e.key: (e.value as List).cast<String>().toSet(),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> write(Map<String, Set<String>> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({for (final e in tags.entries) e.key: e.value.toList()}),
    );
  }
}

/// ブックマークのタグの読み込み・追加・削除。`main()` で `load()` してから
/// `bookmarkTagServiceProvider.overrideWithValue(...)` で渡す。
class BookmarkTagService {
  BookmarkTagService({BookmarkTagStore? store}) : _store = store ?? BookmarkTagStore();

  final BookmarkTagStore _store;
  Map<String, Set<String>> _tags = {};

  Map<String, Set<String>> get tags => _tags;

  Future<void> load() async {
    _tags = await _store.read();
  }

  /// [qid] に [tag] を追加する（空文字・既存のタグは無視）。
  Future<Map<String, Set<String>>> addTag(String qid, String tag) async {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return _tags;
    final current = {...(_tags[qid] ?? const {})};
    if (!current.add(trimmed)) return _tags;
    _tags = {..._tags, qid: current};
    await _store.write(_tags);
    return _tags;
  }

  /// [qid] から [tag] を外す。残りタグが空になればキー自体を削除する。
  Future<Map<String, Set<String>>> removeTag(String qid, String tag) async {
    final current = {...(_tags[qid] ?? const {})};
    if (!current.remove(tag)) return _tags;
    _tags = {..._tags};
    if (current.isEmpty) {
      _tags.remove(qid);
    } else {
      _tags[qid] = current;
    }
    await _store.write(_tags);
    return _tags;
  }

  /// ブックマーク自体を外したとき等に、[qid] のタグをすべて削除する。
  Future<Map<String, Set<String>>> clearForQid(String qid) async {
    if (!_tags.containsKey(qid)) return _tags;
    _tags = {..._tags}..remove(qid);
    await _store.write(_tags);
    return _tags;
  }
}

final bookmarkTagServiceProvider = Provider<BookmarkTagService>(
  (ref) => throw UnimplementedError('bookmarkTagServiceProvider を override してください'),
);

class BookmarkTagNotifier extends Notifier<Map<String, Set<String>>> {
  BookmarkTagService get _s => ref.read(bookmarkTagServiceProvider);

  @override
  Map<String, Set<String>> build() => _s.tags;

  Future<void> addTag(String qid, String tag) async {
    state = await _s.addTag(qid, tag);
  }

  Future<void> removeTag(String qid, String tag) async {
    state = await _s.removeTag(qid, tag);
  }

  Future<void> clearForQid(String qid) async {
    state = await _s.clearForQid(qid);
  }
}

final bookmarkTagProvider =
    NotifierProvider<BookmarkTagNotifier, Map<String, Set<String>>>(BookmarkTagNotifier.new);

/// 指定した qid 集合の中で使われているタグを、名前順ですべて返す
/// （ブックマーク一覧のタグ絞り込みチップ用）。
List<String> allBookmarkTags(Map<String, Set<String>> tags, Iterable<String> qids) {
  final qidSet = qids.toSet();
  final names = <String>{};
  for (final e in tags.entries) {
    if (qidSet.contains(e.key)) names.addAll(e.value);
  }
  final sorted = names.toList()..sort();
  return sorted;
}
