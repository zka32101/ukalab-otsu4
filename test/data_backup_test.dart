import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/data_backup.dart';
import 'package:otsu4/data/daily_answer_stats_store.dart';
import 'package:otsu4/data/daily_goal_history_store.dart';
import 'package:otsu4/data/daily_goal_store.dart';
import 'package:otsu4/data/mock_history_store.dart';
import 'package:otsu4/data/progress_store.dart';
import 'package:otsu4/data/subject_stats_history_store.dart';
import 'package:otsu4/data/subject_stats_store.dart';
import 'package:ukalab_core/ukalab_core.dart';

LearningDataBackup _sampleBackup() => LearningDataBackup(
      progress: ProgressSnapshot(
        answered: 10,
        correct: 7,
        streakDays: 3,
        lastStudyDate: DateTime(2026, 10, 6),
      ),
      srs: {
        'q1': SrsItem(qid: 'q1', box: 2, dueAt: DateTime(2026, 10, 10)),
        'q2': SrsItem(qid: 'q2', box: 0, dueAt: DateTime(2026, 10, 7)),
      },
      mockHistory: [
        MockHistoryEntry(at: DateTime(2026, 10, 1), score: 20, max: 35, passed: false),
        MockHistoryEntry(at: DateTime(2026, 10, 5), score: 28, max: 35, passed: true),
      ],
      mockWrong: ['q3', 'q4'],
      dailyGoal: DailyGoal(
        target: 20,
        todayCount: 5,
        todayDate: DateTime(2026, 10, 6),
        achievedStreak: 2,
        lastAchievedDate: DateTime(2026, 10, 5),
      ),
      dailyGoalHistory: [
        DailyGoalHistoryEntry(date: DateTime(2026, 10, 5), count: 20, achieved: true),
      ],
      subjectStats: {
        'law': const SubjectStat(answered: 10, correct: 7),
        'physics_chem': const SubjectStat(answered: 5, correct: 3),
      },
      subjectStatsHistory: [
        SubjectStatsHistoryEntry(date: DateTime(2026, 10, 5), accuracyBySubject: {'law': 0.7}),
      ],
      answeredQuestions: {'q1', 'q2', 'q3'},
      questionMemo: {'q1': '覚え方メモ'},
      recentGlossaryTerms: ['引火点', '指定数量'],
      bestCombo: 8,
      dailyAnswerStats: [
        DailyAnswerStatsEntry(date: DateTime(2026, 10, 5), answered: 20, correct: 15),
      ],
      glossaryMastered: {'引火点', '比重'},
    );

void main() {
  group('LearningDataBackup', () {
    test('toJson/fromJsonの往復で元の値が復元される', () {
      final original = _sampleBackup();
      final restored = LearningDataBackup.fromJson(original.toJson());

      expect(restored.progress.answered, original.progress.answered);
      expect(restored.progress.correct, original.progress.correct);
      expect(restored.srs.keys, original.srs.keys);
      expect(restored.srs['q1']!.box, 2);
      expect(restored.mockHistory.length, 2);
      expect(restored.mockHistory.last.passed, isTrue);
      expect(restored.mockWrong, ['q3', 'q4']);
      expect(restored.dailyGoal.target, 20);
      expect(restored.dailyGoalHistory.single.count, 20);
      expect(restored.subjectStats['law']!.answered, 10);
      expect(restored.subjectStatsHistory.single.accuracyBySubject['law'], 0.7);
      expect(restored.answeredQuestions, {'q1', 'q2', 'q3'});
      expect(restored.questionMemo['q1'], '覚え方メモ');
      expect(restored.recentGlossaryTerms, ['引火点', '指定数量']);
      expect(restored.bestCombo, 8);
      expect(restored.dailyAnswerStats.single.answered, 20);
      expect(restored.glossaryMastered, {'引火点', '比重'});
    });

    test('JSON文字列にエンコード・デコードしても往復する', () {
      final original = _sampleBackup();
      final jsonText = jsonEncode(original.toJson());
      final restored = LearningDataBackup.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);
      expect(restored.bestCombo, 8);
      expect(restored.answeredQuestions, {'q1', 'q2', 'q3'});
    });

    test('versionが一致しなければ例外を投げる', () {
      final json = _sampleBackup().toJson();
      json['version'] = 999;
      expect(() => LearningDataBackup.fromJson(json), throwsFormatException);
    });

    test('toJsonにversionとexportedAtが含まれる', () {
      final json = _sampleBackup().toJson();
      expect(json['version'], learningDataBackupVersion);
      expect(json['exportedAt'], isA<String>());
    });

    test('dailyAnswerStatsが無い旧いJSONも空リストとして読み込める', () {
      final json = _sampleBackup().toJson();
      json.remove('dailyAnswerStats');
      final restored = LearningDataBackup.fromJson(json);
      expect(restored.dailyAnswerStats, isEmpty);
    });

    test('glossaryMasteredが無い旧いJSONも空の集合として読み込める', () {
      final json = _sampleBackup().toJson();
      json.remove('glossaryMastered');
      final restored = LearningDataBackup.fromJson(json);
      expect(restored.glossaryMastered, isEmpty);
    });
  });
}
