import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/bookmark_store.dart';
import '../data/glossary.dart';
import '../data/question_repository.dart';
import '../data/question_search.dart';
import 'choice_labels.dart';
import 'glossary_card_view.dart';

/// 重要語句で、用語集・問題を横断的に検索できる画面。学ぶタブの入り口から
/// いつでも開ける（問題データの有無にかかわらず用語集の検索はできる）。
/// 「ブックマークのみ」をオンにすると、問題の検索対象をブックマーク済みの
/// 問題だけに絞り込める。
class QuestionSearchView extends ConsumerStatefulWidget {
  const QuestionSearchView({super.key});

  @override
  ConsumerState<QuestionSearchView> createState() => _QuestionSearchViewState();
}

class _QuestionSearchViewState extends ConsumerState<QuestionSearchView> {
  final _repo = const QuestionRepository();
  final _controller = TextEditingController();
  List<Question>? _all;
  String _keyword = '';
  bool _bookmarkOnly = false;

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
    final bookmarked = ref.watch(bookmarkProvider);
    final matchedTerms = searchGlossaryTerms(_keyword);
    final searchPool = all == null ? const <Question>[] : filterByBookmark(
          all,
          bookmarked,
          onlyBookmarked: _bookmarkOnly,
        );
    final matchedQuestions = searchQuestions(searchPool, _keyword);
    final keywordIsEmpty = _keyword.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('重要語句で探す')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '引火点・指定数量 など',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _keyword = v),
            ),
            const SizedBox(height: 8),
            FilterChip(
              label: const Text('ブックマークのみ'),
              selected: _bookmarkOnly,
              onSelected: (v) => setState(() => _bookmarkOnly = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: all == null
                  ? const Center(child: CircularProgressIndicator())
                  : keywordIsEmpty
                      ? const EmptyState(
                          message: 'キーワードを入力すると、関連する用語・問題が見つかります。',
                          icon: Icons.search,
                        )
                      : matchedTerms.isEmpty && matchedQuestions.isEmpty
                          ? const EmptyState(
                              message: '一致する用語・問題は見つかりませんでした。',
                              icon: Icons.search_off,
                            )
                          : ListView(
                              children: [
                                if (matchedTerms.isNotEmpty) ...[
                                  Text('用語集（${matchedTerms.length}件）', style: theme.textTheme.titleSmall),
                                  for (final t in matchedTerms)
                                    ListTile(
                                      leading: const Icon(Icons.menu_book_outlined),
                                      title: Text(t.term),
                                      subtitle: Text(
                                        t.definition,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => GlossaryCardView(initialTerm: t.term),
                                        ),
                                      ),
                                    ),
                                  const Divider(),
                                ],
                                if (matchedQuestions.isNotEmpty) ...[
                                  Text('問題（${matchedQuestions.length}件）', style: theme.textTheme.titleSmall),
                                  for (final q in matchedQuestions)
                                    ListTile(
                                      leading: const Icon(Icons.quiz_outlined),
                                      title: Text(q.prompt, maxLines: 2, overflow: TextOverflow.ellipsis),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => _QuestionDetailView(question: q)),
                                      ),
                                    ),
                                ],
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 検索結果から開く、1問だけの読み取り専用の詳細表示。正解を直接表示する
/// （一問一答のように選んで答える演習ではない）。
class _QuestionDetailView extends StatelessWidget {
  const _QuestionDetailView({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final q = question;
    final terms = termReferencesIn(q.explanation);
    return Scaffold(
      appBar: AppBar(title: const Text('問題の詳細')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          QuestionCard(text: q.prompt, index: 1, total: 1),
          const SizedBox(height: 12),
          for (var i = 0; i < q.choices.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceTile(
                label: choiceLabels[i],
                text: q.choices[i],
                state: i == q.answerIndex ? ChoiceState.correct : ChoiceState.idle,
                onTap: null,
              ),
            ),
          const SizedBox(height: 8),
          ExplanationPanel(
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
          ),
        ],
      ),
    );
  }
}
