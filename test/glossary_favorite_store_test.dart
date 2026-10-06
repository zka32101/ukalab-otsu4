import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/glossary_favorite_store.dart';

void main() {
  group('GlossaryFavoriteService.toggle', () {
    test('お気に入りに登録できる', () async {
      final service = GlossaryFavoriteService(store: _FakeStore());
      await service.toggle('引火点');
      expect(service.terms, {'引火点'});
    });

    test('再度toggleすると解除される', () async {
      final service = GlossaryFavoriteService(store: _FakeStore());
      await service.toggle('引火点');
      await service.toggle('引火点');
      expect(service.terms, isEmpty);
    });

    test('複数の用語を独立して登録できる', () async {
      final service = GlossaryFavoriteService(store: _FakeStore());
      await service.toggle('引火点');
      await service.toggle('指定数量');
      expect(service.terms, {'引火点', '指定数量'});
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = GlossaryFavoriteService(store: store);
      await service.toggle('引火点');

      final reloaded = GlossaryFavoriteService(store: store);
      await reloaded.load();
      expect(reloaded.terms, {'引火点'});
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements GlossaryFavoriteStore {
  Set<String> _saved = {};

  @override
  Future<Set<String>> read() async => _saved;

  @override
  Future<void> write(Set<String> terms) async => _saved = terms;
}
