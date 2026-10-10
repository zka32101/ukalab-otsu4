import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/selected_level_store.dart';
import 'package:ukalab_core/ukalab_core.dart';

ExamConfig _exam() => ExamConfig(
      examId: 'hazmat4',
      name: '危険物取扱者乙種',
      audience: Audience.adult,
      subjects: const [],
      levels: const [
        LevelConfig(
          levelId: 'otsu4',
          name: '乙種第4類',
          questionCount: 35,
          passRule: PassRule(totalPct: 60),
        ),
        LevelConfig(
          levelId: 'otsu1',
          name: '乙種第1類',
          questionCount: 35,
          passRule: PassRule(totalPct: 60),
        ),
      ],
    );

void main() {
  group('SelectedLevelService', () {
    test('selectで選択中の類が切り替わる', () async {
      final service = SelectedLevelService(store: _FakeSelectedLevelStore());
      await service.select('otsu1');
      expect(service.levelId, 'otsu1');
    });

    test('保存・再読み込みで選択が復元される', () async {
      final store = _FakeSelectedLevelStore();
      final service = SelectedLevelService(store: store);
      await service.select('otsu1');

      final reloaded = SelectedLevelService(store: store);
      await reloaded.load();
      expect(reloaded.levelId, 'otsu1');
    });
  });

  group('currentLevel', () {
    test('選択中のlevelIdに一致するLevelConfigを返す', () {
      final exam = _exam();
      expect(currentLevel(exam, 'otsu1').levelId, 'otsu1');
    });

    test('未選択（null）なら先頭のLevelConfigを返す', () {
      final exam = _exam();
      expect(currentLevel(exam, null).levelId, 'otsu4');
    });

    test('選択中のlevelIdが現在のExamConfigに存在しなければ先頭にフォールバックする', () {
      final exam = _exam();
      expect(currentLevel(exam, 'otsu6').levelId, 'otsu4');
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeSelectedLevelStore implements SelectedLevelStore {
  String? _saved;

  @override
  Future<String?> read() async => _saved;

  @override
  Future<void> write(String? levelId) async => _saved = levelId;
}
