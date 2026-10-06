import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/daily_goal_store.dart';
import '../data/exam_date_store.dart';
import '../data/exam_repository.dart';
import '../widgets/oshi_card.dart';

/// デイリーミッションの目標がある夜（18時以降）に、まだ達成していなければ
/// 学習リマインダーを表示する時刻かどうか。OSのプッシュ通知は新規ネイティブ
/// 依存の追加・プラットフォーム設定が必要でこのクラウド環境では検証できない
/// ため、アプリを開いたときに表示するアプリ内リマインダーとして実装する
/// （ユーザー判断。README参照）。
bool shouldShowStudyReminder({required DailyGoal goal, required DateTime now}) =>
    goal.target != null && !goal.achieved && now.hour >= 18;

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
    final showReminder = shouldShowStudyReminder(goal: dailyGoal, now: DateTime.now());
    final examDate = ref.watch(examDateProvider);
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
        const OshiCard(),
        const SizedBox(height: 16),
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
