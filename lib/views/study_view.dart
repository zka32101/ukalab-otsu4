import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/exercise_coins.dart';
import '../data/question_repository.dart';
import 'choice_labels.dart';
import 'extinguisher_match_view.dart';
import 'field_day_view.dart';
import 'storage_puzzle_view.dart';
import 'temperature_lab_view.dart';
import 'violation_hunt_view.dart';

/// 一問一答の演習（問題データが無ければ空状態）と、体験型の演習（画期的な
/// 機能A〜E）への入り口。体験型の演習は一問一答の問題データの有無に
/// かかわらず常に表示する。
class StudyView extends ConsumerStatefulWidget {
  const StudyView({super.key});

  @override
  ConsumerState<StudyView> createState() => _StudyViewState();
}

class _StudyViewState extends ConsumerState<StudyView> {
  final _repo = const QuestionRepository();
  List<Question>? _questions;
  PracticeSession? _session;
  int? _selected;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final qs = await _repo.load();
    if (!mounted) return;
    setState(() {
      _questions = qs;
      if (qs.isNotEmpty) _session = _newSession(qs, seed: 0);
    });
  }

  PracticeSession _newSession(List<Question> qs, {required int seed}) =>
      PracticeSession(pool: qs, size: qs.length < 10 ? qs.length : 10, seed: seed);

  void _select(int i) {
    if (_answered) return;
    final record = _session!.answer(i);
    setState(() {
      _selected = i;
      _answered = true;
    });
    recordExerciseAnswer(ref, correct: record.correct);
  }

  void _next() => setState(() {
        _selected = null;
        _answered = false;
      });

  void _retry() {
    final qs = _questions!;
    setState(() {
      _session = _newSession(qs, seed: DateTime.now().millisecondsSinceEpoch);
      _selected = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final qs = _questions;
    if (qs == null) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPractice(qs),
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

  /// 一問一答の演習部分（問題データが無ければ空状態）。
  Widget _buildPractice(List<Question> qs) {
    if (qs.isEmpty) {
      return const EmptyState(
        message: '一問一答の問題データはまだ多くありません。',
        icon: Icons.menu_book_outlined,
      );
    }

    final session = _session!;
    final q = session.current;
    if (q == null) {
      return ResultSummary(
        correct: session.correctCount,
        total: session.questions.length,
        onRetry: _retry,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionCard(text: q.prompt, index: session.index + 1, total: session.questions.length),
        const SizedBox(height: 12),
        for (var i = 0; i < q.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ChoiceTile(
              label: choiceLabels[i],
              text: q.choices[i],
              state: _choiceState(i, q.answerIndex),
              onTap: _answered ? null : () => _select(i),
            ),
          ),
        if (_answered) ...[
          const SizedBox(height: 8),
          ExplanationPanel(body: q.explanation, sourceRef: q.sourceRef),
          const SizedBox(height: 16),
          FilledButton(onPressed: _next, child: const Text('次の問題')),
        ],
      ],
    );
  }

  ChoiceState _choiceState(int i, int answerIndex) {
    if (!_answered) return ChoiceState.idle;
    if (i == answerIndex) return ChoiceState.correct;
    if (i == _selected) return ChoiceState.incorrect;
    return ChoiceState.idle;
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
