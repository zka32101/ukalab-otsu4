import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/bookmark_store.dart';
import '../data/question_repository.dart';
import 'practice_session_view.dart';

/// ブックマークした問題（`lib/data/bookmark_store.dart`）だけをまとめて
/// 演習できる画面。`StudyView` の一問一答でブックマークした問題がここに並ぶ。
class BookmarkListView extends ConsumerStatefulWidget {
  const BookmarkListView({super.key});

  @override
  ConsumerState<BookmarkListView> createState() => _BookmarkListViewState();
}

class _BookmarkListViewState extends ConsumerState<BookmarkListView> {
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
    final qids = ref.read(bookmarkProvider);
    setState(() => _questions = [for (final q in all) if (qids.contains(q.qid)) q]);
  }

  @override
  Widget build(BuildContext context) {
    final qs = _questions;
    return Scaffold(
      appBar: AppBar(title: const Text('ブックマーク')),
      body: qs == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: PracticeSessionView(
                pool: qs,
                emptyMessage: 'ブックマークはまだありません。一問一答で問題カードのしおりアイコンから登録できます。',
              ),
            ),
    );
  }
}
