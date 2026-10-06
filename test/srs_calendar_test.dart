import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/srs_calendar.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

SrsItem _item(String qid, DateTime dueAt, {int box = 0}) =>
    SrsItem(qid: qid, box: box, dueAt: dueAt);

void main() {
  group('srsReviewCountsByDate', () {
    final now = DateTime(2026, 10, 6, 10);
    final today = DateTime(2026, 10, 6);

    test('期限切れの項目は今日としてまとめる', () {
      final items = [
        _item('q1', DateTime(2026, 10, 1)),
        _item('q2', DateTime(2026, 10, 5)),
      ];
      final counts = srsReviewCountsByDate(items, now);
      expect(counts[today], 2);
    });

    test('未来の予定日はそのまま日付ごとに集計する', () {
      final items = [
        _item('q1', DateTime(2026, 10, 7)),
        _item('q2', DateTime(2026, 10, 7)),
        _item('q3', DateTime(2026, 10, 8)),
      ];
      final counts = srsReviewCountsByDate(items, now);
      expect(counts[DateTime(2026, 10, 7)], 2);
      expect(counts[DateTime(2026, 10, 8)], 1);
    });

    test('daysで指定した範囲より先の予定は含めない', () {
      final items = [
        _item('q1', DateTime(2026, 10, 6)),
        _item('q2', DateTime(2026, 11, 1)), // 範囲外
      ];
      final counts = srsReviewCountsByDate(items, now, days: 7);
      expect(counts[today], 1);
      expect(counts[DateTime(2026, 11, 1)], isNull);
    });

    test('項目が無ければ空を返す', () {
      expect(srsReviewCountsByDate(const [], now), isEmpty);
    });
  });
}
