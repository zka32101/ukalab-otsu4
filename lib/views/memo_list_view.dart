import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/question_repository.dart';
import 'question_search_view.dart';
import 'package:ukalab_core/ui.dart' show questionMemoProvider;

/// 解説に書き残した自分用メモ（`lib/data/question_memo_store.dart`）を
/// まとめて見返せる一覧。メモ本文・問題文でキーワード絞り込みができる。
/// 問題をタップすると、問題文・解説を読み取り専用で確認できる
/// （`QuestionDetailView`。`question_search_view.dart`）。
class MemoListView extends ConsumerStatefulWidget {
  const MemoListView({super.key});

  @override
  ConsumerState<MemoListView> createState() => _MemoListViewState();
}

class _MemoListViewState extends ConsumerState<MemoListView> {
  final _repo = const QuestionRepository();
  final _controller = TextEditingController();
  List<Question>? _all;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _repo.load();
    if (!mounted) return;
    setState(() => _all = all);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = _all;
    final memos = ref.watch(questionMemoProvider);
    final memoed = all == null ? const <Question>[] : filterMemoedQuestions(all, memos, '');
    final filtered = all == null ? const <Question>[] : filterMemoedQuestions(all, memos, _keyword);

    return Scaffold(
      appBar: AppBar(title: const Text('自分用メモの一覧')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'メモ・問題文で絞り込む',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _keyword = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: all == null
                  ? const Center(child: CircularProgressIndicator())
                  : memoed.isEmpty
                      ? const EmptyState(
                          message: 'まだメモはありません。一問一答の解説の下から書き残せます。',
                          icon: Icons.sticky_note_2_outlined,
                        )
                      : filtered.isEmpty
                          ? const EmptyState(
                              message: '一致するメモは見つかりませんでした。',
                              icon: Icons.search_off,
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final q = filtered[i];
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      q.prompt,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      memos[q.qid] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => QuestionDetailView(question: q),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
