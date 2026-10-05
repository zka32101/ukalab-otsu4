import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/exam_repository.dart';
import '../data/question_repository.dart';
import '../data/srs_store.dart';
import 'choice_labels.dart';

/// 模擬試験。35問・2時間・科目別60%以上で合否判定（ExamConfig準拠）。
/// 出題は `pickMockExamQuestions` で科目別の配分（法令15／物理化学10／
/// 性質消火10）どおりに選ぶ。制限時間のタイマー表示は未実装。
class MockExamView extends ConsumerStatefulWidget {
  const MockExamView({super.key});

  @override
  ConsumerState<MockExamView> createState() => _MockExamViewState();
}

class _MockExamViewState extends ConsumerState<MockExamView> {
  final _examRepo = const ExamRepository();
  final _questionRepo = const QuestionRepository();
  ExamConfig? _exam;
  List<Question>? _questions;
  List<Question>? _picked;
  final Map<String, Object?> _answers = {};
  int _index = 0;
  MockExamResult? _result;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final exam = await _examRepo.load();
      final qs = await _questionRepo.load();
      if (!mounted) return;
      setState(() {
        _exam = exam;
        _questions = qs;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _start() {
    final level = _exam!.levels.first;
    setState(() {
      _picked = pickMockExamQuestions(
        pool: _questions!,
        level: level,
        seed: DateTime.now().millisecondsSinceEpoch,
      );
      _answers.clear();
      _index = 0;
      _result = null;
    });
  }

  /// 科目別の配分（あれば）を満たす問題数が揃っているか。
  bool _hasEnoughQuestions(List<Question> qs, LevelConfig level) {
    final counts = level.subjectQuestionCounts;
    if (counts == null) return qs.length >= level.questionCount;
    final bySubject = <String, int>{};
    for (final q in qs) {
      bySubject[q.subjectId] = (bySubject[q.subjectId] ?? 0) + 1;
    }
    return counts.entries.every((e) => (bySubject[e.key] ?? 0) >= e.value);
  }

  void _select(int i) {
    final q = _picked![_index];
    setState(() => _answers[q.qid] = i);
  }

  void _nextOrFinish() {
    if (_index + 1 < _picked!.length) {
      setState(() => _index++);
      return;
    }
    final result = scoreMockExam(
      questions: _picked!,
      answers: _answers,
      rule: _exam!.levels.first.passRule,
    );
    // 間違えた問題は苦手問題の復習リストに入る（間隔反復）。
    for (final q in _picked!) {
      final answer = _answers[q.qid];
      ref
          .read(srsProvider.notifier)
          .review(qid: q.qid, correct: answer is int && answer == q.answerIndex);
    }
    setState(() => _result = result);
    ref.read(coinProvider.notifier).grant(CoinEvent.mockDone());
    if (result.passed) {
      ref.read(coinProvider.notifier).grant(CoinEvent.mockPass(_exam!.examId));
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
    final qs = _questions;
    if (exam == null || qs == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (qs.isEmpty) {
      return const EmptyState(
        message: '問題データがまだなく模擬試験を開始できません。',
        icon: Icons.timer_outlined,
      );
    }

    final result = _result;
    if (result != null) {
      return Center(
        child: ResultSummary(
          correct: result.total.score,
          total: result.total.max,
          passRatio: exam.levels.first.passRule.totalPct / 100,
          passedText: result.passed ? '合格ライン到達' : '科目の足切りに注意',
          onRetry: _start,
        ),
      );
    }

    final picked = _picked;
    if (picked == null) {
      final level = exam.levels.first;
      final enough = _hasEnoughQuestions(qs, level);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '模擬試験　全${level.questionCount}問・${(level.timeLimitSec ?? 0) ~/ 60}分',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: enough ? _start : null, child: const Text('開始する')),
              if (!enough) ...[
                const SizedBox(height: 8),
                Text('問題数が足りないため開始できません（${qs.length}/${level.questionCount}問）'),
              ],
            ],
          ),
        ),
      );
    }

    final q = picked[_index];
    final selected = _answers[q.qid];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        QuestionCard(text: q.prompt, index: _index + 1, total: picked.length),
        const SizedBox(height: 12),
        for (var i = 0; i < q.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ChoiceTile(
              label: choiceLabels[i],
              text: q.choices[i],
              state: i == selected ? ChoiceState.selected : ChoiceState.idle,
              onTap: () => _select(i),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: selected == null ? null : _nextOrFinish,
          child: Text(_index + 1 < picked.length ? '次の問題' : '採点する'),
        ),
      ],
    );
  }
}
