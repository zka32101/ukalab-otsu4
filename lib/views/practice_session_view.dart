import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/answered_questions_store.dart';
import '../data/bookmark_store.dart';
import '../data/daily_goal_history_store.dart';
import '../data/daily_goal_store.dart';
import '../data/exercise_coins.dart';
import '../data/glossary.dart';
import '../data/question_memo_store.dart';
import '../data/recent_questions.dart';
import '../data/srs_store.dart';
import '../data/subject_stats_history_store.dart';
import '../data/subject_stats_store.dart';
import 'choice_labels.dart';
import 'glossary_card_view.dart';

/// 一問一答の演習（`Question` のプール）共通部分。[pool] が空なら
/// [emptyMessage] を表示する。[StudyView]（全体プール）と、苦手問題だけの
/// 復習（`WeakReviewView`）の両方で使う。直近出題した問題（アプリ起動中のみ
/// 記憶。`lib/data/recent_questions.dart`）は、プールが十分にあれば避ける。
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
  int _combo = 0;

  @override
  void initState() {
    super.initState();
    _restart(seed: DateTime.now().millisecondsSinceEpoch);
  }

  void _restart({required int seed}) {
    final minSize = widget.pool.length < 10 ? widget.pool.length : 10;
    final recentIds = ref.read(recentQuestionsProvider).toSet();
    final qs = excludeRecent(widget.pool, recentIds, (q) => q.qid, minPoolSize: minSize);
    setState(() {
      _session = qs.isEmpty
          ? null
          : PracticeSession(
              pool: qs,
              size: minSize,
              mode: widget.mode,
              seed: seed,
            );
      _selected = null;
      _answered = false;
      _combo = 0;
    });
    final session = _session;
    if (session != null) {
      ref.read(recentQuestionsProvider.notifier).recordShown(session.questions.map((q) => q.qid));
    }
  }

  void _select(int i) {
    final subjectId = _session!.current!.subjectId;
    final record = _session!.answer(i);
    setState(() {
      _selected = i;
      _answered = true;
      _combo = record.correct ? _combo + 1 : 0;
    });
    recordExerciseAnswer(ref, correct: record.correct);
    ref.read(srsProvider.notifier).review(qid: record.qid, correct: record.correct);
    ref.read(dailyGoalProvider.notifier).recordAnswer().then((_) {
      if (!mounted) return;
      final goal = ref.read(dailyGoalProvider);
      ref.read(dailyGoalHistoryProvider.notifier).recordSnapshot(
            date: goal.todayDate ?? DateTime.now(),
            count: goal.todayCount,
            achieved: goal.achieved,
          );
    });
    ref.read(answeredQuestionsProvider.notifier).record(record.qid);
    ref
        .read(subjectStatsProvider.notifier)
        .recordAnswer(subjectId: subjectId, correct: record.correct)
        .then((_) {
      if (!mounted) return;
      ref.read(subjectStatsHistoryProvider.notifier).recordSnapshot(ref.read(subjectStatsProvider));
    });
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
        if (_combo >= 2) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.local_fire_department_outlined,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                '$_combo問連続正解中',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ],
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
          Builder(builder: (context) {
            final terms = termReferencesIn(q.explanation);
            return ExplanationPanel(
              body: q.explanation,
              sourceRef: q.sourceRef,
              bodyWidget: terms.isEmpty
                  ? null
                  : TappableTermText(
                      text: q.explanation,
                      terms: terms,
                      onTermTap: (termId) => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => GlossaryCardView(initialTerm: termId)),
                      ),
                    ),
            );
          }),
          const SizedBox(height: 12),
          _MemoField(key: ValueKey(q.qid), qid: q.qid),
          const SizedBox(height: 16),
          FilledButton(onPressed: _next, child: const Text('次の問題')),
        ],
      ],
    );
  }
}

/// 問題ごとの自分用メモの入力欄。間違えた理由・覚え方等を書き残せる
/// （`lib/data/question_memo_store.dart`）。問題が変わるたびに
/// `key: ValueKey(qid)` で独立した State を作り、入力欄をリセットする。
class _MemoField extends ConsumerStatefulWidget {
  const _MemoField({super.key, required this.qid});

  final String qid;

  @override
  ConsumerState<_MemoField> createState() => _MemoFieldState();
}

class _MemoFieldState extends ConsumerState<_MemoField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final memo = ref.read(questionMemoProvider)[widget.qid] ?? '';
    _controller = TextEditingController(text: memo);
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _save();
  }

  void _save() {
    ref.read(questionMemoProvider.notifier).setMemo(qid: widget.qid, memo: _controller.text);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: const InputDecoration(
        labelText: '自分用メモ',
        hintText: '間違えた理由や覚え方を書き残せます',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      maxLines: 3,
      minLines: 1,
    );
  }
}
