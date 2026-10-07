import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/oshi_lines.dart';

/// `app_common_kit` の `kForbiddenExpressions` と同じ考え方の簡易チェック
/// （責める・消える・恋愛依存を煽る表現を含まないこと）。
const _forbiddenWords = [
  'なんで',
  'どうして',
  'サボ',
  '怠',
  'だめ',
  'ダメ',
  'いなくなる',
  '消える',
  'さよなら',
  '悲しい',
  '泣いて',
  'ずっと一緒',
  '大好き',
  '寂しい',
  'さみしい',
];

void main() {
  group('timeOfDayGreetingFor', () {
    test('5時〜10時台は朝', () {
      expect(timeOfDayGreetingFor(DateTime(2026, 10, 7, 5)), TimeOfDayGreeting.morning);
      expect(timeOfDayGreetingFor(DateTime(2026, 10, 7, 10, 59)), TimeOfDayGreeting.morning);
    });

    test('11時〜16時台は昼', () {
      expect(timeOfDayGreetingFor(DateTime(2026, 10, 7, 11)), TimeOfDayGreeting.afternoon);
      expect(timeOfDayGreetingFor(DateTime(2026, 10, 7, 16, 59)), TimeOfDayGreeting.afternoon);
    });

    test('17時〜20時台は夕方', () {
      expect(timeOfDayGreetingFor(DateTime(2026, 10, 7, 17)), TimeOfDayGreeting.evening);
      expect(timeOfDayGreetingFor(DateTime(2026, 10, 7, 20, 59)), TimeOfDayGreeting.evening);
    });

    test('21時〜翌4時台は夜', () {
      expect(timeOfDayGreetingFor(DateTime(2026, 10, 7, 21)), TimeOfDayGreeting.night);
      expect(timeOfDayGreetingFor(DateTime(2026, 10, 7, 4, 59)), TimeOfDayGreeting.night);
      expect(timeOfDayGreetingFor(DateTime(2026, 10, 7, 0)), TimeOfDayGreeting.night);
    });
  });

  group('pickTimeOfDayGreeting', () {
    test('同じ時刻・seedなら同じ文言を返す', () {
      final now = DateTime(2026, 10, 7, 9);
      expect(pickTimeOfDayGreeting(now, seed: 0), pickTimeOfDayGreeting(now, seed: 0));
    });

    test('seedを変えると朝のセリフの中で別のバリエーションになりうる', () {
      final now = DateTime(2026, 10, 7, 9);
      final a = pickTimeOfDayGreeting(now, seed: 0);
      final b = pickTimeOfDayGreeting(now, seed: 1);
      expect(a == b, isFalse);
    });

    test('時間帯が変わればセリフも変わる', () {
      final morning = pickTimeOfDayGreeting(DateTime(2026, 10, 7, 7), seed: 0);
      final night = pickTimeOfDayGreeting(DateTime(2026, 10, 7, 23), seed: 0);
      expect(morning == night, isFalse);
    });

    test('禁止表現を含まない', () {
      for (final greeting in TimeOfDayGreeting.values) {
        for (var seed = 0; seed < 4; seed++) {
          final hour = switch (greeting) {
            TimeOfDayGreeting.morning => 7,
            TimeOfDayGreeting.afternoon => 13,
            TimeOfDayGreeting.evening => 18,
            TimeOfDayGreeting.night => 22,
          };
          final line = pickTimeOfDayGreeting(DateTime(2026, 10, 7, hour), seed: seed);
          for (final word in _forbiddenWords) {
            expect(line.contains(word), isFalse, reason: '"$line" contains forbidden word "$word"');
          }
        }
      }
    });
  });
}
