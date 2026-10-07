import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/mock_wrong_store.dart';

void main() {
  group('MockWrongService.setWrong', () {
    test('間違えた問題のqidを保存できる', () async {
      final service = MockWrongService(store: _FakeStore());
      await service.setWrong(['q1', 'q2']);
      expect(service.qids, ['q1', 'q2']);
    });

    test('模試を終えるたびに直近1回分で上書きする', () async {
      final service = MockWrongService(store: _FakeStore());
      await service.setWrong(['q1', 'q2']);
      await service.setWrong(['q3']);
      expect(service.qids, ['q3']);
    });

    test('全問正解なら空リストで上書きする', () async {
      final service = MockWrongService(store: _FakeStore());
      await service.setWrong(['q1']);
      await service.setWrong([]);
      expect(service.qids, isEmpty);
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = MockWrongService(store: store);
      await service.setWrong(['q1', 'q2']);

      final reloaded = MockWrongService(store: store);
      await reloaded.load();
      expect(reloaded.qids, ['q1', 'q2']);
    });

    test('resetで空になる', () async {
      final service = MockWrongService(store: _FakeStore());
      await service.setWrong(['q1']);
      await service.reset();
      expect(service.qids, isEmpty);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements MockWrongStore {
  List<String> _saved = [];

  @override
  Future<List<String>> read() async => _saved;

  @override
  Future<void> write(List<String> qids) async => _saved = qids;
}
