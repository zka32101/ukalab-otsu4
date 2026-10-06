import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/bookmark_store.dart';
import '../data/exam_repository.dart';
import '../data/question_repository.dart';
import 'practice_session_view.dart';

/// ブックマークした問題（`lib/data/bookmark_store.dart`）だけをまとめて
/// 演習できる画面。`StudyView` の一問一答でブックマークした問題がここに並ぶ。
/// 複数の分野にまたがる場合は、分野別に絞り込める。
class BookmarkListView extends ConsumerStatefulWidget {
  const BookmarkListView({super.key});

  @override
  ConsumerState<BookmarkListView> createState() => _BookmarkListViewState();
}

class _BookmarkListViewState extends ConsumerState<BookmarkListView> {
  final _repo = const QuestionRepository();
  final _examRepo = const ExamRepository();
  List<Question>? _questions;
  ExamConfig? _exam;
  String? _subjectFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _repo.load();
    final exam = await _examRepo.load();
    if (!mounted) return;
    final qids = ref.read(bookmarkProvider);
    setState(() {
      _questions = [for (final q in all) if (qids.contains(q.qid)) q];
      _exam = exam;
    });
  }

  /// ブックマークした問題がある分野だけ、`ExamConfig` の並び順で返す。
  List<SubjectConfig> _availableSubjects(ExamConfig exam, List<Question> qs) {
    final ids = qs.map((q) => q.subjectId).toSet();
    final subjects = [for (final s in exam.subjects) if (ids.contains(s.subjectId)) s];
    subjects.sort((a, b) => a.order.compareTo(b.order));
    return subjects;
  }

  @override
  Widget build(BuildContext context) {
    final qs = _questions;
    final exam = _exam;
    if (qs == null || exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ブックマーク')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final subjects = _availableSubjects(exam, qs);
    final filter = _subjectFilter;
    final filteredQs = filterBySubject(qs, filter);

    return Scaffold(
      appBar: AppBar(title: const Text('ブックマーク')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: PracticeSessionView(
                key: ValueKey(filter),
                pool: filteredQs,
                emptyMessage: qs.isEmpty
                    ? 'ブックマークはまだありません。一問一答で問題カードのしおりアイコンから登録できます。'
                    : 'この分野のブックマークはまだありません。',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
