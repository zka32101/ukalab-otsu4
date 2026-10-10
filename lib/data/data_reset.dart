import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievement_unlock_store.dart';
import 'answered_questions_store.dart';
import 'combo_store.dart';
import 'daily_answer_stats_store.dart';
import 'daily_goal_history_store.dart';
import 'daily_goal_store.dart';
import 'glossary_mastered_store.dart';
import 'mock_history_store.dart';
import 'mock_wrong_store.dart';
import 'progress_store.dart';
import 'recent_glossary_terms_store.dart';
import 'srs_store.dart';
import 'subject_stats_history_store.dart';
import 'subject_stats_store.dart';
import 'package:ukalab_core/ui.dart' show questionMemoProvider;

/// 設定タブの「学習記録をリセット」で呼ぶ。進捗・解答履歴・模試結果・
/// デイリーミッション・分野別統計・苦手問題の復習・自分用メモ・最近見た
/// 用語・コンボの自己最高記録・日別の解答数・正解数・用語集の「覚えた」
/// フラグ・実績バッジの解除通知済みIDを初期状態に戻す。
///
/// テーマ・リマインダー設定・試験日・用語集のお気に入り・ブックマークは
/// ユーザー設定・curationとして扱い、対象に含めない。
Future<void> resetAllLearningData(WidgetRef ref) async {
  await Future.wait([
    ref.read(progressProvider.notifier).reset(),
    ref.read(srsProvider.notifier).reset(),
    ref.read(mockHistoryProvider.notifier).reset(),
    ref.read(mockWrongProvider.notifier).reset(),
    ref.read(dailyGoalProvider.notifier).reset(),
    ref.read(dailyGoalHistoryProvider.notifier).reset(),
    ref.read(subjectStatsProvider.notifier).reset(),
    ref.read(subjectStatsHistoryProvider.notifier).reset(),
    ref.read(answeredQuestionsProvider.notifier).reset(),
    ref.read(questionMemoProvider.notifier).reset(),
    ref.read(recentGlossaryTermsProvider.notifier).reset(),
    ref.read(comboProvider.notifier).reset(),
    ref.read(dailyAnswerStatsProvider.notifier).reset(),
    ref.read(glossaryMasteredProvider.notifier).reset(),
    ref.read(achievementUnlockProvider.notifier).reset(),
  ]);
}
