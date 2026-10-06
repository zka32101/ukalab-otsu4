import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/mock_history_store.dart';

MockHistoryEntry _entry(DateTime at) => MockHistoryEntry(at: at, score: 20, max: 35, passed: true);

void main() {
  group('shouldShowMockIntervalReminder', () {
    test('模試の履歴が無ければ表示しない', () {
      expect(shouldShowMockIntervalReminder(const [], DateTime(2026, 10, 6)), isFalse);
    });

    test('前回の模試から7日未満なら表示しない', () {
      final history = [_entry(DateTime(2026, 10, 1))];
      expect(shouldShowMockIntervalReminder(history, DateTime(2026, 10, 6)), isFalse);
    });

    test('前回の模試からちょうど7日経っていれば表示する', () {
      final history = [_entry(DateTime(2026, 9, 29))];
      expect(shouldShowMockIntervalReminder(history, DateTime(2026, 10, 6)), isTrue);
    });

    test('前回の模試から7日以上経っていれば表示する', () {
      final history = [_entry(DateTime(2026, 9, 1))];
      expect(shouldShowMockIntervalReminder(history, DateTime(2026, 10, 6)), isTrue);
    });

    test('直近の模試（履歴の最後）を基準に判定する', () {
      final history = [_entry(DateTime(2026, 9, 1)), _entry(DateTime(2026, 10, 5))];
      expect(shouldShowMockIntervalReminder(history, DateTime(2026, 10, 6)), isFalse);
    });

    test('daysを指定すれば、その日数で判定する', () {
      final history = [_entry(DateTime(2026, 10, 3))];
      expect(shouldShowMockIntervalReminder(history, DateTime(2026, 10, 6), days: 3), isTrue);
      expect(shouldShowMockIntervalReminder(history, DateTime(2026, 10, 6), days: 4), isFalse);
    });
  });

  group('nextRecommendedMockDate', () {
    test('履歴が無ければnull', () {
      expect(nextRecommendedMockDate(const []), isNull);
    });

    test('前回の模試から指定日数後を返す', () {
      final history = [_entry(DateTime(2026, 10, 1))];
      expect(nextRecommendedMockDate(history), DateTime(2026, 10, 8));
    });

    test('直近の模試（履歴の最後）を基準にする', () {
      final history = [_entry(DateTime(2026, 9, 1)), _entry(DateTime(2026, 10, 1))];
      expect(nextRecommendedMockDate(history, days: 3), DateTime(2026, 10, 4));
    });
  });

  group('nextMockDateText', () {
    test('目安の日が未来なら残り日数を表示する', () {
      final text = nextMockDateText(DateTime(2026, 10, 10), DateTime(2026, 10, 6));
      expect(text, '次回の模試の目安は10/10（あと4日）です');
    });

    test('目安の日が今日なら「今日」と表示する', () {
      final text = nextMockDateText(DateTime(2026, 10, 6), DateTime(2026, 10, 6));
      expect(text, '次回の模試の目安は今日（10/6）です');
    });

    test('目安の日を過ぎていれば、その旨を表示する', () {
      final text = nextMockDateText(DateTime(2026, 10, 1), DateTime(2026, 10, 6));
      expect(text, '次回の模試の目安（10/1）を過ぎています');
    });
  });
}
