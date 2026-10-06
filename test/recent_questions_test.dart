import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/recent_questions.dart';

void main() {
  group('excludeRecent', () {
    test('除外後もminPoolSize以上あれば、直近出題分を除いたリストを返す', () {
      final pool = ['a', 'b', 'c', 'd', 'e'];
      final result = excludeRecent(pool, {'a', 'b'}, (s) => s, minPoolSize: 2);
      expect(result, ['c', 'd', 'e']);
    });

    test('除外するとminPoolSize未満になる場合は、元のプールをそのまま返す', () {
      final pool = ['a', 'b', 'c'];
      final result = excludeRecent(pool, {'a', 'b'}, (s) => s, minPoolSize: 2);
      expect(result, pool);
    });

    test('直近出題IDが空なら元のプールと同じ', () {
      final pool = ['a', 'b', 'c'];
      final result = excludeRecent(pool, {}, (s) => s, minPoolSize: 2);
      expect(result, pool);
    });
  });

  group('mergeRecentQuestions', () {
    test('出題を記録すると新しい順に積まれる', () {
      final after1 = mergeRecentQuestions([], ['q1', 'q2']);
      expect(after1, ['q1', 'q2']);
      final after2 = mergeRecentQuestions(after1, ['q3']);
      expect(after2, ['q3', 'q1', 'q2']);
    });

    test('重複するqidは新しい記録の方を優先し、古い方の重複は除く', () {
      final after1 = mergeRecentQuestions([], ['q1', 'q2']);
      final after2 = mergeRecentQuestions(after1, ['q2', 'q3']);
      expect(after2, ['q2', 'q3', 'q1']);
    });

    test('上限件数を超えると古いものから捨てる', () {
      var current = <String>[];
      for (var i = 0; i < maxRememberedQuestions + 5; i++) {
        current = mergeRecentQuestions(current, ['q$i']);
      }
      expect(current, hasLength(maxRememberedQuestions));
      expect(current.first, 'q${maxRememberedQuestions + 4}');
    });
  });
}
