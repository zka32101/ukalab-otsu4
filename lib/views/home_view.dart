import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/daily_answer_stats_store.dart';
import '../data/daily_goal_store.dart';
import '../data/exam_date_store.dart';
import '../data/exam_repository.dart';
import '../data/mock_history_store.dart';
import '../data/reminder_settings_store.dart';
import '../widgets/oshi_card.dart';

/// デイリーミッションの目標がある夜（[reminderHour]時以降、既定18時）に、
/// まだ達成していなければ学習リマインダーを表示する時刻かどうか。OSの
/// プッシュ通知は新規ネイティブ依存の追加・プラットフォーム設定が必要で
/// このクラウド環境では検証できないため、アプリを開いたときに表示する
/// アプリ内リマインダーとして実装する（ユーザー判断。README参照）。
bool shouldShowStudyReminder({required DailyGoal goal, required DateTime now, int reminderHour = 18}) =>
    goal.target != null && !goal.achieved && now.hour >= reminderHour;

/// ホーム。試験の概要と、学ぶ・模擬への導線。
///
/// 推し（MascotWidget）・コイン残高は `OshiCard` で表示。正式な出題範囲の
/// 網羅率・正答率はまだ無い（問題データ未着手）ため、暫定の進捗指標を使う
/// （`lib/data/progress_store.dart`・README参照）。
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final _repo = const ExamRepository();
  ExamConfig? _exam;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final exam = await _repo.load();
      if (!mounted) return;
      setState(() => _exam = exam);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorState(onRetry: () {
        setState(() => _error = null);
        _load();
      });
    }
    final exam = _exam;
    if (exam == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final level = exam.levels.first;
    final theme = Theme.of(context);
    final dailyGoal = ref.watch(dailyGoalProvider);
    final reminderSettings = ref.watch(reminderSettingsProvider);
    final showReminder = reminderSettings.studyReminderEnabled &&
        shouldShowStudyReminder(
          goal: dailyGoal,
          now: DateTime.now(),
          reminderHour: reminderSettings.studyReminderHour,
        );
    final examDate = ref.watch(examDateProvider);
    final mockHistory = ref.watch(mockHistoryProvider);
    final showMockReminder = reminderSettings.mockReminderEnabled &&
        shouldShowMockIntervalReminder(mockHistory, DateTime.now());
    final nextMockDate =
        reminderSettings.mockReminderEnabled ? nextRecommendedMockDate(mockHistory) : null;
    final dailyAnswerStats = ref.watch(dailyAnswerStatsProvider);
    final weekly = weeklyAnswerSummary(dailyAnswerStats);
    final weeklyAnswered = weekly.fold<int>(0, (sum, e) => sum + e.answered);
    final weeklyCorrect = weekly.fold<int>(0, (sum, e) => sum + e.correct);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (examDate != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      examCountdownText(daysUntilExam(examDate, DateTime.now())),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (showReminder) ...[
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.nightlight_outlined, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '今日はまだ目標（${dailyGoal.target}問）に届いていません。学ぶタブから続けましょう',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (showMockReminder) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.quiz_outlined, color: theme.colorScheme.secondary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('前回の模擬試験から日が経っています。模擬タブで力試しをしてみましょう'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (!showMockReminder && nextMockDate != null) ...[
          Row(
            children: [
              Icon(Icons.event_note_outlined, size: 16, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Text(nextMockDateText(nextMockDate, DateTime.now()), style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
        ],
        const OshiCard(),
        const SizedBox(height: 16),
        if (weeklyAnswered > 0) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('今週の学習サマリー', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '直近7日間: $weeklyAnswered問 ・ 正答率 ${(weeklyCorrect / weeklyAnswered * 100).round()}%',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _WeeklyAnswerChart(entries: weekly),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(exam.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '全${level.questionCount}問・${(level.timeLimitSec ?? 0) ~/ 60}分・科目別${level.passRule.subjectMinPct?.round() ?? level.passRule.totalPct.round()}%以上で合格',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('出題科目', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final s in exam.subjects)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('・${s.name}'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 直近7日間（今日を含む）の解答数のミニ横棒グラフ（日ごとに縦の棒）。
/// [entries] は `weeklyAnswerSummary` が返す、古い順の7件。
class _WeeklyAnswerChart extends StatelessWidget {
  const _WeeklyAnswerChart({required this.entries});

  final List<DailyAnswerStatsEntry> entries;

  static const _weekdayLabels = ['日', '月', '火', '水', '木', '金', '土'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxAnswered = entries.fold<int>(1, (m, e) => e.answered > m ? e.answered : m);
    const maxBarHeight = 48.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final e in entries)
          Expanded(
            child: Column(
              children: [
                Text('${e.answered}', style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Container(
                  height: e.answered == 0 ? 2 : maxBarHeight * e.answered / maxAnswered,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: e.answered == 0
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(_weekdayLabels[e.date.weekday % 7], style: theme.textTheme.labelSmall),
              ],
            ),
          ),
      ],
    );
  }
}
