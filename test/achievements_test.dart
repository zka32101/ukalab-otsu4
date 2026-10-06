import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/achievements.dart';
import 'package:otsu4/data/mock_history_store.dart';
import 'package:otsu4/data/subject_stats_store.dart';

void main() {
  group('buildAchievements', () {
    test('何も達成していなければ全てunlocked:false', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: const {},
      );
      expect(achievements.every((a) => !a.unlocked), isTrue);
    });

    test('連続学習日数が節目に達するとその節目が解除される', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 7,
        mockHistory: const [],
        subjectStats: const {},
      );
      final streak7 = achievements.firstWhere((a) => a.id == 'streak_7');
      final streak14 = achievements.firstWhere((a) => a.id == 'streak_14');
      expect(streak7.unlocked, isTrue);
      expect(streak14.unlocked, isFalse);
    });

    test('解答数が節目に達するとその節目が解除される', () {
      final achievements = buildAchievements(
        answered: 100,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: const {},
      );
      expect(achievements.firstWhere((a) => a.id == 'answered_50').unlocked, isTrue);
      expect(achievements.firstWhere((a) => a.id == 'answered_100').unlocked, isTrue);
      expect(achievements.firstWhere((a) => a.id == 'answered_300').unlocked, isFalse);
    });

    test('合格した模試履歴があれば模擬試験合格が解除される', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: [
          MockHistoryEntry(at: DateTime(2026, 1, 1), score: 10, max: 35, passed: false),
          MockHistoryEntry(at: DateTime(2026, 1, 2), score: 30, max: 35, passed: true),
        ],
        subjectStats: const {},
      );
      expect(achievements.firstWhere((a) => a.id == 'mock_pass').unlocked, isTrue);
    });

    test('十分な解答数で正答率90%以上の分野があれば分野マスターが解除される', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: {'law': const SubjectStat(answered: 10, correct: 9)},
      );
      expect(achievements.firstWhere((a) => a.id == 'subject_master').unlocked, isTrue);
    });

    test('解答数が足りなければ正答率が高くても分野マスターは解除されない', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: {'law': const SubjectStat(answered: 3, correct: 3)},
      );
      expect(achievements.firstWhere((a) => a.id == 'subject_master').unlocked, isFalse);
    });
  });
}
