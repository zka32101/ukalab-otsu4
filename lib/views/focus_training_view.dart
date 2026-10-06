import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/question_repository.dart';
import '../data/subject_stats_store.dart';
import 'practice_session_view.dart';

/// 集中特訓（苦手分野の優先出題）。解答数が十分あり正答率が低い分野
/// （`weakSubjectIds`。`lib/data/subject_stats_store.dart`）の問題だけを
/// まとめて演習する。
class FocusTrainingView extends ConsumerStatefulWidget {
  const FocusTrainingView({super.key});

  @override
  ConsumerState<FocusTrainingView> createState() => _FocusTrainingViewState();
}

class _FocusTrainingViewState extends ConsumerState<FocusTrainingView> {
  final _repo = const QuestionRepository();
  List<Question>? _questions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _repo.load();
    if (!mounted) return;
    final weakIds = weakSubjectIds(ref.read(subjectStatsProvider)).toSet();
    setState(() => _questions = [for (final q in all) if (weakIds.contains(q.subjectId)) q]);
  }

  @override
  Widget build(BuildContext context) {
    final qs = _questions;
    return Scaffold(
      appBar: AppBar(title: const Text('集中特訓')),
      body: qs == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: PracticeSessionView(
                pool: qs,
                emptyMessage: '苦手な分野はまだ特定できていません。',
              ),
            ),
    );
  }
}
