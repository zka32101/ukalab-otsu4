import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/answered_questions_store.dart';
import 'data/bookmark_store.dart';
import 'data/combo_store.dart';
import 'data/daily_goal_history_store.dart';
import 'data/daily_goal_store.dart';
import 'data/exam_date_store.dart';
import 'data/glossary_favorite_store.dart';
import 'data/mock_history_store.dart';
import 'data/mock_wrong_store.dart';
import 'data/progress_store.dart';
import 'data/question_memo_store.dart';
import 'data/recent_glossary_terms_store.dart';
import 'data/reminder_settings_store.dart';
import 'data/srs_store.dart';
import 'data/subject_stats_history_store.dart';
import 'data/subject_stats_store.dart';
import 'data/theme_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 学習コイン・衣装（app_common_kit）。財布はアプリごと。端末内に保存する。
  // コインは学習の成長でのみ獲得する（課金・広告視聴での付与はしない）。
  final coinService = CoinService(
    store: SharedPreferencesCoinStore('otsu4'),
    shop: OutfitCatalog.shopItems([UkalabCert.hazmat4]),
  );
  await coinService.load();
  final outfitService = OutfitService(store: SharedPreferencesOutfitStore('otsu4'));
  await outfitService.load();

  // 推しの成長の暫定の進捗指標（問題データが入るまでの代替。README参照）。
  final progressService = ProgressService();
  await progressService.load();

  // 苦手問題の復習（間隔反復）。端末内に保存する。
  final srsService = SrsService();
  await srsService.load();

  // 模擬試験の結果履歴。端末内に保存する。
  final mockHistoryService = MockHistoryService();
  await mockHistoryService.load();

  // 直近の模擬試験で間違えた問題のqid。端末内に保存する。
  final mockWrongService = MockWrongService();
  await mockWrongService.load();

  // 気になる問題のブックマーク。端末内に保存する。
  final bookmarkService = BookmarkService();
  await bookmarkService.load();

  // デイリーミッション（今日の目標問題数）。端末内に保存する。
  final dailyGoalService = DailyGoalService();
  await dailyGoalService.load();

  // デイリーミッションの達成履歴（日次スナップショット）。端末内に保存する。
  final dailyGoalHistoryService = DailyGoalHistoryService();
  await dailyGoalHistoryService.load();

  // 分野別の解答数・正解数。端末内に保存する。
  final subjectStatsService = SubjectStatsService();
  await subjectStatsService.load();

  // 分野別正答率の推移（日次スナップショット）。端末内に保存する。
  final subjectStatsHistoryService = SubjectStatsHistoryService();
  await subjectStatsHistoryService.load();

  // テーマ設定（ライト／ダーク／端末に合わせる）。端末内に保存する。
  final themeService = ThemeService();
  await themeService.load();

  // 問題ごとの自分用メモ。端末内に保存する。
  final questionMemoService = QuestionMemoService();
  await questionMemoService.load();

  // 試験日（本番の日付）。端末内に保存する。
  final examDateService = ExamDateService();
  await examDateService.load();

  // これまでに解答した問題のqid（分野別の出題網羅率で使う）。端末内に保存する。
  final answeredQuestionsService = AnsweredQuestionsService();
  await answeredQuestionsService.load();

  // お気に入りに登録した用語集の用語。端末内に保存する。
  final glossaryFavoriteService = GlossaryFavoriteService();
  await glossaryFavoriteService.load();

  // アプリ内リマインダー（学習・模試）の個別オン/オフ設定。端末内に保存する。
  final reminderSettingsService = ReminderSettingsService();
  await reminderSettingsService.load();

  // 最近見た用語集の用語（新しい順）。端末内に保存する。
  final recentGlossaryTermsService = RecentGlossaryTermsService();
  await recentGlossaryTermsService.load();

  // 一問一答の連続正解数（コンボ）の自己最高記録。端末内に保存する。
  final comboService = ComboService();
  await comboService.load();

  runApp(
    ProviderScope(
      overrides: [
        coinServiceProvider.overrideWithValue(coinService),
        outfitServiceProvider.overrideWithValue(outfitService),
        progressServiceProvider.overrideWithValue(progressService),
        srsServiceProvider.overrideWithValue(srsService),
        mockHistoryServiceProvider.overrideWithValue(mockHistoryService),
        mockWrongServiceProvider.overrideWithValue(mockWrongService),
        bookmarkServiceProvider.overrideWithValue(bookmarkService),
        dailyGoalServiceProvider.overrideWithValue(dailyGoalService),
        dailyGoalHistoryServiceProvider.overrideWithValue(dailyGoalHistoryService),
        subjectStatsServiceProvider.overrideWithValue(subjectStatsService),
        subjectStatsHistoryServiceProvider.overrideWithValue(subjectStatsHistoryService),
        themeServiceProvider.overrideWithValue(themeService),
        questionMemoServiceProvider.overrideWithValue(questionMemoService),
        examDateServiceProvider.overrideWithValue(examDateService),
        answeredQuestionsServiceProvider.overrideWithValue(answeredQuestionsService),
        glossaryFavoriteServiceProvider.overrideWithValue(glossaryFavoriteService),
        reminderSettingsServiceProvider.overrideWithValue(reminderSettingsService),
        recentGlossaryTermsServiceProvider.overrideWithValue(recentGlossaryTermsService),
        comboServiceProvider.overrideWithValue(comboService),
      ],
      child: const Otsu4App(),
    ),
  );
}
