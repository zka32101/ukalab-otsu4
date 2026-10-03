import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/question_repository.dart';
import 'choice_labels.dart';
import 'temperature_lab_view.dart';

/// 一問一答の演習。問題データが入るまでは空状態を表示する。
class StudyView extends StatefulWidget {
  const StudyView({super.key});

  @override
  State<StudyView> createState() => _StudyViewState();
}

class _StudyViewState extends State<StudyView> {
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
    _session!.answer(i);
    setState(() {
      _selected = i;
      _answered = true;
    });
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
    if (qs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const EmptyState(
            message: '問題データはまだありません。準備中です。',
            icon: Icons.menu_book_outlined,
          ),
          const SizedBox(height: 24),
          _ExperienceCard(
            icon: Icons.thermostat_outlined,
            title: '温度の実験室',
            description: '気温を変えて、引火点を超える物質を確かめよう',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TemperatureLabView()),
            ),
          ),
        ],
      );
    }

    final session = _session!;
    final q = session.current;
    if (q == null) {
      return Center(
        child: ResultSummary(
          correct: session.correctCount,
          total: session.questions.length,
          onRetry: _retry,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
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
