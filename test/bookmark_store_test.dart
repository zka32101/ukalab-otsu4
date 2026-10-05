import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/bookmark_store.dart';

void main() {
  group('BookmarkService.toggle', () {
    test('ブックマークしていない問題をトグルすると追加される', () async {
      final service = BookmarkService(store: _FakeBookmarkStore());
      await service.toggle('q1');
      expect(service.qids, {'q1'});
    });

    test('ブックマーク済みの問題をトグルすると外れる', () async {
      final service = BookmarkService(store: _FakeBookmarkStore());
      await service.toggle('q1');
      await service.toggle('q1');
      expect(service.qids, isEmpty);
    });

    test('複数の問題を独立にブックマークできる', () async {
      final service = BookmarkService(store: _FakeBookmarkStore());
      await service.toggle('q1');
      await service.toggle('q2');
      expect(service.qids, {'q1', 'q2'});
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeBookmarkStore();
      final service = BookmarkService(store: store);
      await service.toggle('q1');

      final reloaded = BookmarkService(store: store);
      await reloaded.load();
      expect(reloaded.qids, {'q1'});
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeBookmarkStore implements BookmarkStore {
  Set<String> _saved = {};

  @override
  Future<Set<String>> read() async => _saved;

  @override
  Future<void> write(Set<String> qids) async => _saved = qids;
}
