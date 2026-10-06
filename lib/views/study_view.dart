import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/bookmark_store.dart';
import '../data/daily_goal_store.dart';
import '../data/exam_repository.dart';
import '../data/question_repository.dart';
import '../data/srs_store.dart';
import '../data/subject_stats_store.dart';
import 'bookmark_list_view.dart';
import 'extinguisher_match_view.dart';
import 'field_day_view.dart';
import 'focus_training_view.dart';
import 'glossary_card_view.dart';
import 'practice_session_view.dart';
import 'storage_puzzle_view.dart';
import 'temperature_lab_view.dart';
import 'violation_hunt_view.dart';
import 'weak_review_view.dart';

/// 一問一答の演習（問題データが無ければ空状態）と、体験型の演習（画期的な
/// 機能A〜E）への入り口。体験型の演習は一問一答の問題データの有無に
/// かかわらず常に表示する。
class StudyView extends ConsumerStatefulWidget {
  const StudyView({super.key});

  @override
  ConsumerState<StudyView> createState() => _StudyViewState();
}

class _StudyViewState extends ConsumerState<StudyView> {
  final _examRepo = const ExamRepository();
  final _repo = const QuestionRepository();
  ExamConfig? _exam;
  List<Question>? _questions;
  String? _subjectFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exam = await _examRepo.load();
    final qs = await _repo.load();
    if (!mounted) return;
    setState(() {
      _exam = exam;
      _questions = qs;
    });
  }

  /// 問題データがある分野だけ、`ExamConfig` の並び順で返す。
  List<SubjectConfig> _availableSubjects(ExamConfig exam, List<Question> qs) {
    final ids = qs.map((q) => q.subjectId).toSet();
    final subjects = [for (final s in exam.subjects) if (ids.contains(s.subjectId)) s];
    subjects.sort((a, b) => a.order.compareTo(b.order));
    return subjects;
  }

  @override
  Widget build(BuildContext context) {
    final exam = _exam;
    final qs = _questions;
    if (exam == null || qs == null) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);
    final dueQids = ref.watch(dueWeakQidsProvider).toSet();
    final dueCount = qs.where((q) => dueQids.contains(q.qid)).length;
    final bookmarkCount = ref.watch(bookmarkProvider).length;
    final dailyGoal = ref.watch(dailyGoalProvider);
    final weakIds = weakSubjectIds(ref.watch(subjectStatsProvider)).toSet();
    final weakQuestionCount = qs.where((q) => weakIds.contains(q.subjectId)).length;
    final subjects = _availableSubjects(exam, qs);
    final filter = _subjectFilter;
    final filteredQs = filter == null ? qs : qs.where((q) => q.subjectId == filter).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (dailyGoal.target != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    dailyGoal.achieved ? Icons.celebration_outlined : Icons.flag_outlined,
                    color: dailyGoal.achieved ? theme.colorScheme.primary : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dailyGoal.achieved ? '今日の目標を達成しました！' : '今日のデイリーミッション',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (dailyGoal.todayCount / dailyGoal.target!).clamp(0, 1),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dailyGoal.todayCount} / ${dailyGoal.target}問',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (dueCount > 0) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.history_edu_outlined),
              title: Text('苦手問題の復習（$dueCount問）'),
              subtitle: const Text('間違えた問題を、間隔をあけて優先的に出題します'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeakReviewView()),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (weakQuestionCount > 0) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.fitness_center_outlined),
              title: Text('集中特訓（$weakQuestionCount問）'),
              subtitle: const Text('正答率が低い分野だけを優先的に演習します'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FocusTrainingView()),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (bookmarkCount > 0) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.bookmark_outlined),
              title: Text('ブックマーク（$bookmarkCount問）'),
              subtitle: const Text('気になる問題だけをまとめて見返せます'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookmarkListView()),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('用語集'),
            subtitle: const Text('引火点・指定数量など、頻出用語を暗記カードで確認できます'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlossaryCardView()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (subjects.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('すべて'),
                selected: filter == null,
                onSelected: (_) => setState(() => _subjectFilter = null),
              ),
              for (final s in subjects)
                ChoiceChip(
                  label: Text(s.name),
                  selected: filter == s.subjectId,
                  onSelected: (_) => setState(() => _subjectFilter = s.subjectId),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        PracticeSessionView(
          key: ValueKey(filter),
          pool: filteredQs,
          emptyMessage: filter == null
              ? '一問一答の問題データはまだ多くありません。'
              : 'この分野の問題データはまだありません。',
        ),
        const SizedBox(height: 24),
        Text('体験型の演習', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _ExperienceCard(
          icon: Icons.thermostat_outlined,
          title: '温度の実験室',
          description: '気温を変えて、引火点を超える物質を確かめよう',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TemperatureLabView()),
          ),
        ),
        const SizedBox(height: 12),
        _ExperienceCard(
          icon: Icons.inventory_2_outlined,
          title: '貯蔵所パズル',
          description: '指定数量の倍数を計算して、許可が必要か判定しよう',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StoragePuzzleView()),
          ),
        ),
        const SizedBox(height: 12),
        _ExperienceCard(
          icon: Icons.local_fire_department_outlined,
          title: '消火マッチング',
          description: '物質と消火剤の組み合わせが有効か不適かを答えよう',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExtinguisherMatchView()),
          ),
        ),
        const SizedBox(height: 12),
        _ExperienceCard(
          icon: Icons.search_outlined,
          title: '違反探しモード',
          description: '4つの行動から、法令・消火の知識に違反しているものを見つけよう',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ViolationHuntView()),
          ),
        ),
        const SizedBox(height: 12),
        _ExperienceCard(
          icon: Icons.work_outline,
          title: '現場の1日',
          description: '1日の勤務を模した4つの場面で、温度・指定数量・消火剤の判断をしよう',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FieldDayView()),
          ),
        ),
      ],
    );
  }
}

/// 体験型機能（温度の実験室など）への入り口カード。
class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.secondary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(description, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
