import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/achievements.dart';
import 'package:otsu4/data/daily_answer_stats_store.dart';
import 'package:otsu4/data/today_highlight.dart';

void main() {
  group('buildTodayHighlight', () {
    final achievements = buildAchievements(
      answered: 100,
      streakDays: 0,
      mockHistory: const [],
      subjectStats: const {},
    );

    test('何もなければisEmptyがtrue', () {
      final highlight = buildTodayHighlight(
        dailyAnswerStats: const [],
        achievements: achievements,
        unlockedAt: const {},
        now: DateTime(2026, 1, 1),
      );
      expect(highlight.isEmpty, isTrue);
      expect(highlight.answered, 0);
      expect(highlight.unlockedTitles, isEmpty);
    });

    test('今日の解答数・正答率を返す', () {
      final highlight = buildTodayHighlight(
        dailyAnswerStats: [
          DailyAnswerStatsEntry(date: DateTime(2026, 1, 1), answered: 10, correct: 8),
          DailyAnswerStatsEntry(date: DateTime(2026, 1, 2), answered: 5, correct: 5),
        ],
        achievements: achievements,
        unlockedAt: const {},
        now: DateTime(2026, 1, 1, 20),
      );
      expect(highlight.isEmpty, isFalse);
      expect(highlight.answered, 10);
      expect(highlight.correct, 8);
      expect(highlight.accuracy, 0.8);
    });

    test('今日解除したバッジのタイトルを返す', () {
      final answered50 = achievements.firstWhere((a) => a.id == 'answered_50');
      final highlight = buildTodayHighlight(
        dailyAnswerStats: const [],
        achievements: achievements,
        unlockedAt: {'answered_50': DateTime(2026, 1, 1, 9)},
        now: DateTime(2026, 1, 1, 20),
      );
      expect(highlight.isEmpty, isFalse);
      expect(highlight.unlockedTitles, [answered50.title]);
    });

    test('別の日に解除されたバッジは含めない', () {
      final highlight = buildTodayHighlight(
        dailyAnswerStats: const [],
        achievements: achievements,
        unlockedAt: {'answered_50': DateTime(2025, 12, 31)},
        now: DateTime(2026, 1, 1),
      );
      expect(highlight.isEmpty, isTrue);
      expect(highlight.unlockedTitles, isEmpty);
    });
  });
}
