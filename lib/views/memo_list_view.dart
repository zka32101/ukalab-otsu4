import 'package:flutter/material.dart';
import 'package:ukalab_core/ui.dart' show MemoListScreen;

import '../data/question_repository.dart';
import 'question_search_view.dart';

/// 解説に書き残した自分用メモの一覧。画面本体は ukalab_core の [MemoListScreen]。
/// 問題をタップすると、解説の用語をタップできる詳細（[QuestionDetailView]）を開く。
class MemoListView extends StatelessWidget {
  const MemoListView({super.key});

  @override
  Widget build(BuildContext context) {
    return MemoListScreen(
      loadQuestions: () => const QuestionRepository().load(),
      detailBuilder: (context, q) => QuestionDetailView(question: q),
    );
  }
}
