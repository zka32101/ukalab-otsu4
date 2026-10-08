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

    test('解除済みのバッジはprogressTextがnull', () {
      final achievements = buildAchievements(
        answered: 100,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: const {},
      );
      expect(achievements.firstWhere((a) => a.id == 'answered_100').progressText, isNull);
    });

    test('未解除の解答数バッジは現在の解答数をprogressTextに表示する', () {
      final achievements = buildAchievements(
        answered: 30,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: const {},
      );
      expect(
        achievements.firstWhere((a) => a.id == 'answered_50').progressText,
        '現在の解答数: 30問 / 50問',
      );
    });

    test('未解除の連続学習バッジは現在の連続日数をprogressTextに表示する', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 2,
        mockHistory: const [],
        subjectStats: const {},
      );
      expect(
        achievements.firstWhere((a) => a.id == 'streak_3').progressText,
        '現在の連続学習日数: 2日 / 3日',
      );
    });

    test('模試未受験ならmock_passのprogressTextは受験履歴なしの文言', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: const {},
      );
      expect(achievements.firstWhere((a) => a.id == 'mock_pass').progressText, '模擬試験の受験履歴がまだありません');
    });

    test('不合格の模試履歴があればmock_passのprogressTextは合格未到達の文言', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: [MockHistoryEntry(at: DateTime(2026, 1, 1), score: 10, max: 35, passed: false)],
        subjectStats: const {},
      );
      expect(
        achievements.firstWhere((a) => a.id == 'mock_pass').progressText,
        '直近の模試はまだ合格ラインに届いていません',
      );
    });

    test('対象分野が無ければsubject_masterのprogressTextは解答数不足の文言', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: {'law': const SubjectStat(answered: 3, correct: 3)},
      );
      expect(
        achievements.firstWhere((a) => a.id == 'subject_master').progressText,
        '10問以上解答した分野がまだありません',
      );
    });

    test('解答数十分だが正答率が低ければsubject_masterのprogressTextは最高正答率を表示する', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: {'law': const SubjectStat(answered: 10, correct: 7)},
      );
      expect(
        achievements.firstWhere((a) => a.id == 'subject_master').progressText,
        '現在の最高正答率: 70%（10問以上解答した分野のうち）',
      );
    });

    test('自己最高コンボが節目に達するとその節目が解除される', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: const {},
        bestCombo: 10,
      );
      expect(achievements.firstWhere((a) => a.id == 'combo_5').unlocked, isTrue);
      expect(achievements.firstWhere((a) => a.id == 'combo_10').unlocked, isTrue);
      expect(achievements.firstWhere((a) => a.id == 'combo_20').unlocked, isFalse);
    });

    test('定着問題数が節目に達するとその節目が解除される', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: const {},
        masteredCount: 30,
      );
      expect(achievements.firstWhere((a) => a.id == 'mastered_10').unlocked, isTrue);
      expect(achievements.firstWhere((a) => a.id == 'mastered_30').unlocked, isTrue);
      expect(achievements.firstWhere((a) => a.id == 'mastered_50').unlocked, isFalse);
    });

    test('デイリーミッションの連続達成日数が節目に達するとその節目が解除される', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: const {},
        achievedStreak: 7,
      );
      expect(achievements.firstWhere((a) => a.id == 'achieved_streak_3').unlocked, isTrue);
      expect(achievements.firstWhere((a) => a.id == 'achieved_streak_7').unlocked, isTrue);
      expect(achievements.firstWhere((a) => a.id == 'achieved_streak_14').unlocked, isFalse);
    });

    test('未解除のコンボ・定着・連続達成バッジは現在値をprogressTextに表示する', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: const {},
        bestCombo: 2,
        masteredCount: 4,
        achievedStreak: 1,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'combo_5').progressText,
        '自己最高の連続正解数: 2問 / 5問',
      );
      expect(
        achievements.firstWhere((a) => a.id == 'mastered_10').progressText,
        '現在の定着問題数: 4問 / 10問',
      );
      expect(
        achievements.firstWhere((a) => a.id == 'achieved_streak_3').progressText,
        '現在の連続達成日数: 1日 / 3日',
      );
    });

    test('全科目80%以上の模試履歴があればmock_all_subjects_80が解除される', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: [
          MockHistoryEntry(
            at: DateTime(2026, 1, 1),
            score: 30,
            max: 35,
            passed: true,
            subjectScore: {'law': 13, 'physics_chem': 9, 'property_extinguish': 8},
            subjectMax: {'law': 15, 'physics_chem': 10, 'property_extinguish': 10},
          ),
        ],
        subjectStats: const {},
      );
      expect(achievements.firstWhere((a) => a.id == 'mock_all_subjects_80').unlocked, isTrue);
    });

    test('一部の科目が80%未満ならmock_all_subjects_80は解除されない', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: [
          MockHistoryEntry(
            at: DateTime(2026, 1, 1),
            score: 30,
            max: 35,
            passed: true,
            subjectScore: {'law': 13, 'physics_chem': 5, 'property_extinguish': 8},
            subjectMax: {'law': 15, 'physics_chem': 10, 'property_extinguish': 10},
          ),
        ],
        subjectStats: const {},
      );
      expect(achievements.firstWhere((a) => a.id == 'mock_all_subjects_80').unlocked, isFalse);
    });

    test('科目別データが無い模試履歴ではmock_all_subjects_80のprogressTextは受験履歴なしの文言', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: [MockHistoryEntry(at: DateTime(2026, 1, 1), score: 30, max: 35, passed: true)],
        subjectStats: const {},
      );
      expect(
        achievements.firstWhere((a) => a.id == 'mock_all_subjects_80').progressText,
        '科目別データがある模試の受験履歴がまだありません',
      );
    });

    test('各バッジに正しいカテゴリが割り当てられている', () {
      final achievements = buildAchievements(
        answered: 0,
        streakDays: 0,
        mockHistory: const [],
        subjectStats: const {},
      );
      expect(
        achievements.firstWhere((a) => a.id == 'streak_7').category,
        AchievementCategory.streak,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'achieved_streak_3').category,
        AchievementCategory.streak,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'answered_50').category,
        AchievementCategory.practice,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'combo_5').category,
        AchievementCategory.practice,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'mastered_10').category,
        AchievementCategory.practice,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'mock_pass').category,
        AchievementCategory.mock,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'mock_all_subjects_80').category,
        AchievementCategory.mock,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'subject_master').category,
        AchievementCategory.subject,
      );
    });
  });
}
