import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/bookmark_store.dart';
import '../data/exercise_coins.dart';
import '../data/srs_store.dart';
import 'choice_labels.dart';

/// 一問一答の演習（`Question` のプール）共通部分。[pool] が空なら
/// [emptyMessage] を表示する。[StudyView]（全体プール）と、苦手問題だけの
/// 復習（`WeakReviewView`）の両方で使う。
class PracticeSessionView extends ConsumerStatefulWidget {
  const PracticeSessionView({
    super.key,
    required this.pool,
    required this.emptyMessage,
    this.mode = PracticeMode.practice,
  });

  final List<Question> pool;
  final String emptyMessage;
  final PracticeMode mode;

  @override
  ConsumerState<PracticeSessionView> createState() => _PracticeSessionViewState();
}

class _PracticeSessionViewState extends ConsumerState<PracticeSessionView> {
  PracticeSession? _session;
  int? _selected;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _restart(seed: 0);
  }

  void _restart({required int seed}) {
    final qs = widget.pool;
    setState(() {
      _session = qs.isEmpty
          ? null
          : PracticeSession(
              pool: qs,
              size: qs.length < 10 ? qs.length : 10,
              mode: widget.mode,
              seed: seed,
            );
      _selected = null;
      _answered = false;
    });
  }

  void _select(int i) {
    final record = _session!.answer(i);
    setState(() {
      _selected = i;
      _answered = true;
    });
    recordExerciseAnswer(ref, correct: record.correct);
    ref.read(srsProvider.notifier).review(qid: record.qid, correct: record.correct);
  }

  void _next() => setState(() {
        _selected = null;
        _answered = false;
      });

  void _retry() => _restart(seed: DateTime.now().millisecondsSinceEpoch);

  ChoiceState _choiceState(int i, int answerIndex) {
    if (!_answered) return ChoiceState.idle;
    if (i == answerIndex) return ChoiceState.correct;
    if (i == _selected) return ChoiceState.incorrect;
    return ChoiceState.idle;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pool.isEmpty) {
      return EmptyState(message: widget.emptyMessage, icon: Icons.menu_book_outlined);
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

    final bookmarked = ref.watch(bookmarkProvider).contains(q.qid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: QuestionCard(
                text: q.prompt,
                index: session.index + 1,
                total: session.questions.length,
              ),
            ),
            IconButton(
              icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
              tooltip: bookmarked ? 'ブックマークを外す' : 'ブックマークする',
              onPressed: () => ref.read(bookmarkProvider.notifier).toggle(q.qid),
            ),
          ],
        ),
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
}
