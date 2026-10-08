import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/exam_date_store.dart';

void main() {
  group('daysUntilExam', () {
    test('未来の日付なら正の日数', () {
      final now = DateTime(2026, 10, 6);
      final exam = DateTime(2026, 10, 20);
      expect(daysUntilExam(exam, now), 14);
    });

    test('当日なら0', () {
      final now = DateTime(2026, 10, 6, 15);
      final exam = DateTime(2026, 10, 6);
      expect(daysUntilExam(exam, now), 0);
    });

    test('過去の日付なら負の日数', () {
      final now = DateTime(2026, 10, 10);
      final exam = DateTime(2026, 10, 6);
      expect(daysUntilExam(exam, now), -4);
    });

    test('時刻は無視して日付のみで計算する', () {
      final now = DateTime(2026, 10, 6, 23, 59);
      final exam = DateTime(2026, 10, 7, 0, 1);
      expect(daysUntilExam(exam, now), 1);
    });
  });

  group('examCountdownText', () {
    test('残り日数が正なら「あとN日」', () {
      expect(examCountdownText(14), '本番まであと14日');
    });

    test('0なら「今日です」', () {
      expect(examCountdownText(0), '本番は今日です');
    });

    test('負なら経過日数を表示', () {
      expect(examCountdownText(-4), '本番から4日経過しました');
    });
  });

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

  group('studyPlanQuestionsPerDay', () {
    test('残り日数が0以下ならnull（過去・当日）', () {
      expect(studyPlanQuestionsPerDay(daysLeft: 0, remainingQuestions: 100), isNull);
      expect(studyPlanQuestionsPerDay(daysLeft: -3, remainingQuestions: 100), isNull);
    });

    test('未解答が無ければ0', () {
      expect(studyPlanQuestionsPerDay(daysLeft: 10, remainingQuestions: 0), 0);
    });

    test('割り切れる場合はそのまま', () {
      expect(studyPlanQuestionsPerDay(daysLeft: 10, remainingQuestions: 100), 10);
    });

    test('割り切れない場合は切り上げ', () {
      expect(studyPlanQuestionsPerDay(daysLeft: 3, remainingQuestions: 10), 4);
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
