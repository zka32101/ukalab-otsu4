import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/exam_date_store.dart';

void main() {
  group('ExamDateService', () {
    test('setDateで保存した日付がdateに反映される', () async {
      final service = ExamDateService(store: _FakeStore());
      final date = DateTime(2026, 11, 1);
      await service.setDate(date);
      expect(service.date, date);
    });

    test('nullを設定すると解除される', () async {
      final store = _FakeStore();
      final service = ExamDateService(store: store);
      await service.setDate(DateTime(2026, 11, 1));
      await service.setDate(null);
      expect(service.date, isNull);
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = ExamDateService(store: store);
      final date = DateTime(2026, 11, 1);
      await service.setDate(date);

      final reloaded = ExamDateService(store: store);
      await reloaded.load();
      expect(reloaded.date, date);
    });
  });

}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements ExamDateStore {
  DateTime? _saved;

  @override
  Future<DateTime?> read() async => _saved;

  @override
  Future<void> write(DateTime? date) async => _saved = date;
}
