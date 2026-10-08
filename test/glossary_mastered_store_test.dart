import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/glossary_mastered_store.dart';

void main() {
  group('GlossaryMasteredService.toggle', () {
    test('「覚えた」に登録できる', () async {
      final service = GlossaryMasteredService(store: _FakeStore());
      await service.toggle('引火点');
      expect(service.terms, {'引火点'});
    });

    test('再度toggleすると解除される', () async {
      final service = GlossaryMasteredService(store: _FakeStore());
      await service.toggle('引火点');
      await service.toggle('引火点');
      expect(service.terms, isEmpty);
    });

    test('複数の用語を独立して登録できる', () async {
      final service = GlossaryMasteredService(store: _FakeStore());
      await service.toggle('引火点');
      await service.toggle('指定数量');
      expect(service.terms, {'引火点', '指定数量'});
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = GlossaryMasteredService(store: store);
      await service.toggle('引火点');

      final reloaded = GlossaryMasteredService(store: store);
      await reloaded.load();
      expect(reloaded.terms, {'引火点'});
    });

    test('resetで記録が空になる', () async {
      final service = GlossaryMasteredService(store: _FakeStore());
      await service.toggle('引火点');
      await service.reset();
      expect(service.terms, isEmpty);
    });

    test('restoreで渡した集合に上書きされる', () async {
      final service = GlossaryMasteredService(store: _FakeStore());
      await service.toggle('引火点');
      await service.restore({'指定数量', '比重'});
      expect(service.terms, {'指定数量', '比重'});
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements GlossaryMasteredStore {
  Set<String> _saved = {};

  @override
  Future<Set<String>> read() async => _saved;

  @override
  Future<void> write(Set<String> terms) async => _saved = terms;
}
