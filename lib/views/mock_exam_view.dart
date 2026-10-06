import 'dart:async';

import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/answered_questions_store.dart';
import '../data/daily_goal_store.dart';
import '../data/exam_repository.dart';
import '../data/mock_history_store.dart';
import '../data/mock_wrong_store.dart';
import '../data/question_repository.dart';
import '../data/srs_store.dart';
import '../data/subject_stats_history_store.dart';
import '../data/subject_stats_store.dart';
import 'choice_labels.dart';
import 'mock_review_view.dart';

/// 模擬試験。35問・2時間・科目別60%以上で合否判定（ExamConfig準拠）。
/// 出題は `pickMockExamQuestions` で科目別の配分（法令15／物理化学10／
/// 性質消火10）どおりに選ぶ。制限時間（`LevelConfig.timeLimitSec`）は
/// 残り時間のカウントダウン表示付きで、0になると自動的に採点する。
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
  List<Question> _wrongQuestions = [];
  Object? _error;
  Timer? _timer;
  int? _remainingSec;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
    _timer?.cancel();
    setState(() {
      _picked = pickMockExamQuestions(
        pool: _questions!,
        level: level,
        seed: DateTime.now().millisecondsSinceEpoch,
      );
      _answers.clear();
      _index = 0;
      _result = null;
      _remainingSec = level.timeLimitSec;
    });
    if (level.timeLimitSec != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final remaining = _remainingSec;
    if (remaining == null) return;
    if (remaining <= 1) {
      _timer?.cancel();
      setState(() => _remainingSec = 0);
      _finish();
      return;
    }
    setState(() => _remainingSec = remaining - 1);
  }

  String _formatRemaining(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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
    _timer?.cancel();
    _finish();
  }

  /// 採点して結果を確定する。最後の問題に答えたとき・制限時間が
  /// 0になったときの両方から呼ぶ。
  void _finish() {
    final result = scoreMockExam(
      questions: _picked!,
      answers: _answers,
      rule: _exam!.levels.first.passRule,
    );
    // 間違えた問題は苦手問題の復習リストに入れつつ（間隔反復）、分野別の
    // 正答率・デイリーミッションの解答数にも積み上げ、振り返り画面用に
    // 控えておく。
    final wrong = <Question>[];
    for (final q in _picked!) {
      final answer = _answers[q.qid];
      final correct = answer is int && answer == q.answerIndex;
      ref.read(srsProvider.notifier).review(qid: q.qid, correct: correct);
      ref.read(subjectStatsProvider.notifier).recordAnswer(subjectId: q.subjectId, correct: correct);
      ref.read(dailyGoalProvider.notifier).recordAnswer();
      ref.read(answeredQuestionsProvider.notifier).record(q.qid);
      if (!correct) wrong.add(q);
    }
    ref.read(subjectStatsHistoryProvider.notifier).recordSnapshot(ref.read(subjectStatsProvider));
    ref.read(mockWrongProvider.notifier).setWrong([for (final q in wrong) q.qid]);
    setState(() {
      _result = result;
      _wrongQuestions = wrong;
    });
    ref.read(mockHistoryProvider.notifier).add(MockHistoryEntry(
          at: DateTime.now(),
          score: result.total.score,
          max: result.total.max,
          passed: result.passed,
        ));
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ResultSummary(
              correct: result.total.score,
              total: result.total.max,
              passRatio: exam.levels.first.passRule.totalPct / 100,
              passedText: result.passed ? '合格ライン到達' : '科目の足切りに注意',
              onRetry: _start,
            ),
            if (result.bySubject.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SubjectResultCard(
                exam: exam,
                bySubject: result.bySubject,
                shortfalls: result.subjectShortfalls,
              ),
            ],
            if (_wrongQuestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MockReviewView(questions: _wrongQuestions, answers: _answers),
                  ),
                ),
                child: Text('間違えた問題を振り返る（${_wrongQuestions.length}問）'),
              ),
            ],
          ],
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
    final remaining = _remainingSec;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (remaining != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: remaining <= 60 ? Theme.of(context).colorScheme.error : null,
              ),
              const SizedBox(width: 4),
              Text(
                '残り ${_formatRemaining(remaining)}',
                style: TextStyle(
                  color: remaining <= 60 ? Theme.of(context).colorScheme.error : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
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

/// 模試結果の科目別内訳（得点・得点率・足切り判定）。
class _SubjectResultCard extends StatelessWidget {
  const _SubjectResultCard({
    required this.exam,
    required this.bySubject,
    required this.shortfalls,
  });

  final ExamConfig exam;
  final Map<String, ScoreLine> bySubject;
  final Map<String, int> shortfalls;

  String _subjectName(String subjectId) =>
      exam.subjects.firstWhere((s) => s.subjectId == subjectId, orElse: () => SubjectConfig(
            subjectId: subjectId,
            name: subjectId,
            order: 0,
          )).name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = [...exam.subjects]..sort((a, b) => a.order.compareTo(b.order));
    final ids = [for (final s in subjects) if (bySubject.containsKey(s.subjectId)) s.subjectId];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('科目別の結果', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            for (final id in ids)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_subjectName(id), style: theme.textTheme.bodyMedium),
                    Row(
                      children: [
                        if (shortfalls.containsKey(id)) ...[
                          Icon(Icons.warning_amber_outlined, size: 16, color: theme.colorScheme.error),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '${bySubject[id]!.score}/${bySubject[id]!.max}'
                          '（${bySubject[id]!.pct.round()}%）',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: shortfalls.containsKey(id) ? theme.colorScheme.error : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (shortfalls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '赤字の科目は足切り（最低得点率）に届いていません。',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
