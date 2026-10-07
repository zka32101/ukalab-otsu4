import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import 'answered_questions_store.dart';
import 'combo_store.dart';
import 'daily_answer_stats_store.dart';
import 'daily_goal_history_store.dart';
import 'daily_goal_store.dart';
import 'mock_history_store.dart';
import 'mock_wrong_store.dart';
import 'progress_store.dart';
import 'question_memo_store.dart';
import 'recent_glossary_terms_store.dart';
import 'srs_store.dart';
import 'subject_stats_history_store.dart';
import 'subject_stats_store.dart';

/// バックアップのJSON形式のバージョン。読み込み側で形式が変わったときの
/// 目印に使う（現状は1のみ対応）。
const learningDataBackupVersion = 1;

/// 学習記録のバックアップ1件分。`lib/data/data_reset.dart` の
/// `resetAllLearningData` がリセットする対象と同じ範囲（進捗・解答履歴・
/// 模試結果・デイリーミッション・分野別統計・苦手問題の復習・自分用メモ・
/// 最近見た用語・コンボの自己最高記録・日別の解答数・正解数）を書き出し・
/// 読み込みできる。
class LearningDataBackup {
  const LearningDataBackup({
    required this.progress,
    required this.srs,
    required this.mockHistory,
    required this.mockWrong,
    required this.dailyGoal,
    required this.dailyGoalHistory,
    required this.subjectStats,
    required this.subjectStatsHistory,
    required this.answeredQuestions,
    required this.questionMemo,
    required this.recentGlossaryTerms,
    required this.bestCombo,
    required this.dailyAnswerStats,
  });

  final ProgressSnapshot progress;
  final Map<String, SrsItem> srs;
  final List<MockHistoryEntry> mockHistory;
  final List<String> mockWrong;
  final DailyGoal dailyGoal;
  final List<DailyGoalHistoryEntry> dailyGoalHistory;
  final Map<String, SubjectStat> subjectStats;
  final List<SubjectStatsHistoryEntry> subjectStatsHistory;
  final Set<String> answeredQuestions;
  final Map<String, String> questionMemo;
  final List<String> recentGlossaryTerms;
  final int bestCombo;
  final List<DailyAnswerStatsEntry> dailyAnswerStats;

  Map<String, dynamic> toJson() => {
        'version': learningDataBackupVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'progress': progress.toJson(),
        'srs': [for (final i in srs.values) i.toJson()],
        'mockHistory': [for (final e in mockHistory) e.toJson()],
        'mockWrong': mockWrong,
        'dailyGoal': dailyGoal.toJson(),
        'dailyGoalHistory': [for (final e in dailyGoalHistory) e.toJson()],
        'subjectStats': {for (final e in subjectStats.entries) e.key: e.value.toJson()},
        'subjectStatsHistory': [for (final e in subjectStatsHistory) e.toJson()],
        'answeredQuestions': answeredQuestions.toList(),
        'questionMemo': questionMemo,
        'recentGlossaryTerms': recentGlossaryTerms,
        'bestCombo': bestCombo,
        'dailyAnswerStats': [for (final e in dailyAnswerStats) e.toJson()],
      };

  /// [json] から復元する。想定外のバージョン・形式の場合は例外を投げる。
  static LearningDataBackup fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int?;
    if (version != learningDataBackupVersion) {
      throw FormatException('未対応のバックアップ形式です（version: $version）');
    }
    final srsList = (json['srs'] as List).cast<Map<String, dynamic>>();
    return LearningDataBackup(
      progress: ProgressSnapshot.fromJson(json['progress'] as Map<String, dynamic>),
      srs: {for (final j in srsList) (SrsItem.fromJson(j)).qid: SrsItem.fromJson(j)},
      mockHistory: [
        for (final j in (json['mockHistory'] as List).cast<Map<String, dynamic>>())
          MockHistoryEntry.fromJson(j),
      ],
      mockWrong: (json['mockWrong'] as List).cast<String>(),
      dailyGoal: DailyGoal.fromJson(json['dailyGoal'] as Map<String, dynamic>),
      dailyGoalHistory: [
        for (final j in (json['dailyGoalHistory'] as List).cast<Map<String, dynamic>>())
          DailyGoalHistoryEntry.fromJson(j),
      ],
      subjectStats: {
        for (final e in (json['subjectStats'] as Map<String, dynamic>).entries)
          e.key: SubjectStat.fromJson(e.value as Map<String, dynamic>),
      },
      subjectStatsHistory: [
        for (final j in (json['subjectStatsHistory'] as List).cast<Map<String, dynamic>>())
          SubjectStatsHistoryEntry.fromJson(j),
      ],
      answeredQuestions: (json['answeredQuestions'] as List).cast<String>().toSet(),
      questionMemo: (json['questionMemo'] as Map<String, dynamic>).cast<String, String>(),
      recentGlossaryTerms: (json['recentGlossaryTerms'] as List).cast<String>(),
      bestCombo: json['bestCombo'] as int,
      // この項目を追加する前にバックアップした旧いJSONにも対応するため、
      // 無ければ空のリストとして扱う（versionは変えていない）。
      dailyAnswerStats: [
        for (final j in ((json['dailyAnswerStats'] as List?) ?? const []).cast<Map<String, dynamic>>())
          DailyAnswerStatsEntry.fromJson(j),
      ],
    );
  }
}

/// 現在の学習記録から、クリップボードに書き出すJSON文字列を作る。
String exportLearningDataJson(WidgetRef ref) {
  final backup = LearningDataBackup(
    progress: ref.read(progressProvider),
    srs: ref.read(srsProvider),
    mockHistory: ref.read(mockHistoryProvider),
    mockWrong: ref.read(mockWrongProvider),
    dailyGoal: ref.read(dailyGoalProvider),
    dailyGoalHistory: ref.read(dailyGoalHistoryProvider),
    subjectStats: ref.read(subjectStatsProvider),
    subjectStatsHistory: ref.read(subjectStatsHistoryProvider),
    answeredQuestions: ref.read(answeredQuestionsProvider),
    questionMemo: ref.read(questionMemoProvider),
    recentGlossaryTerms: ref.read(recentGlossaryTermsProvider),
    bestCombo: ref.read(comboProvider),
    dailyAnswerStats: ref.read(dailyAnswerStatsProvider),
  );
  return const JsonEncoder.withIndent('  ').convert(backup.toJson());
}

/// [jsonText] を解析し、学習記録をすべて上書きする。形式が不正なら例外を
/// 投げる（呼び出し側でダイアログ等にエラー表示する想定）。
Future<void> importLearningDataJson(WidgetRef ref, String jsonText) async {
  final json = jsonDecode(jsonText) as Map<String, dynamic>;
  final backup = LearningDataBackup.fromJson(json);
  await ref.read(progressProvider.notifier).restore(backup.progress);
  await ref.read(srsProvider.notifier).restore(backup.srs);
  await ref.read(mockHistoryProvider.notifier).restore(backup.mockHistory);
  await ref.read(mockWrongProvider.notifier).setWrong(backup.mockWrong);
  await ref.read(dailyGoalProvider.notifier).restore(backup.dailyGoal);
  await ref.read(dailyGoalHistoryProvider.notifier).restore(backup.dailyGoalHistory);
  await ref.read(subjectStatsProvider.notifier).restore(backup.subjectStats);
  await ref.read(subjectStatsHistoryProvider.notifier).restore(backup.subjectStatsHistory);
  await ref.read(answeredQuestionsProvider.notifier).restore(backup.answeredQuestions);
  await ref.read(questionMemoProvider.notifier).restore(backup.questionMemo);
  await ref.read(recentGlossaryTermsProvider.notifier).restore(backup.recentGlossaryTerms);
  await ref.read(comboProvider.notifier).restore(backup.bestCombo);
  await ref.read(dailyAnswerStatsProvider.notifier).restore(backup.dailyAnswerStats);
}
