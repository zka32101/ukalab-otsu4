import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/bookmark_tag_store.dart';

void main() {
  group('BookmarkTagService', () {
    test('addTagでタグが追加される', () async {
      final service = BookmarkTagService(store: _FakeBookmarkTagStore());
      await service.addTag('q1', '要復習');
      expect(service.tags['q1'], {'要復習'});
    });

    test('同じタグを重複して追加しても1件のまま', () async {
      final service = BookmarkTagService(store: _FakeBookmarkTagStore());
      await service.addTag('q1', '要復習');
      await service.addTag('q1', '要復習');
      expect(service.tags['q1'], {'要復習'});
    });

    test('空文字のタグは追加されない', () async {
      final service = BookmarkTagService(store: _FakeBookmarkTagStore());
      await service.addTag('q1', '   ');
      expect(service.tags.containsKey('q1'), isFalse);
    });

    test('removeTagでタグを外せる。残りが空ならキー自体が消える', () async {
      final service = BookmarkTagService(store: _FakeBookmarkTagStore());
      await service.addTag('q1', '要復習');
      await service.addTag('q1', '暗記');
      await service.removeTag('q1', '要復習');
      expect(service.tags['q1'], {'暗記'});
      await service.removeTag('q1', '暗記');
      expect(service.tags.containsKey('q1'), isFalse);
    });

    test('clearForQidでその問題のタグがすべて消える', () async {
      final service = BookmarkTagService(store: _FakeBookmarkTagStore());
      await service.addTag('q1', '要復習');
      await service.addTag('q2', '暗記');
      await service.clearForQid('q1');
      expect(service.tags.containsKey('q1'), isFalse);
      expect(service.tags['q2'], {'暗記'});
    });

    test('保存・再読み込みでタグが復元される', () async {
      final store = _FakeBookmarkTagStore();
      final service = BookmarkTagService(store: store);
      await service.addTag('q1', '要復習');

      final reloaded = BookmarkTagService(store: store);
      await reloaded.load();
      expect(reloaded.tags['q1'], {'要復習'});
    });
  });

  group('allBookmarkTags', () {
    test('指定したqid集合の中で使われているタグを名前順で返す', () {
      final tags = {
        'q1': {'暗記'},
        'q2': {'要復習', '計算問題'},
        'q3': {'無関係'},
      };
      expect(allBookmarkTags(tags, ['q1', 'q2']), ['暗記', '要復習', '計算問題']..sort());
    });

    test('対象qidに無いタグは含めない', () {
      final tags = {'q1': {'暗記'}};
      expect(allBookmarkTags(tags, ['q2']), isEmpty);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeBookmarkTagStore implements BookmarkTagStore {
  Map<String, Set<String>> _saved = {};

  @override
  Future<Map<String, Set<String>>> read() async => _saved;

  @override
  Future<void> write(Map<String, Set<String>> tags) async => _saved = tags;
}
