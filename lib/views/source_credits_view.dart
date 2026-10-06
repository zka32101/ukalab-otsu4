import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';

import '../data/question_repository.dart';
import '../data/source_credits.dart';

/// 法令問題で使われている出典条文の一覧。設定タブから開く。
/// 問題・解説自体は独自に作成したものだが、法令分野は条文の内容に基づいて
/// 出題しているため、その根拠となった条文を一覧で確認できるようにする。
class SourceCreditsView extends StatefulWidget {
  const SourceCreditsView({super.key});

  @override
  State<SourceCreditsView> createState() => _SourceCreditsViewState();
}

class _SourceCreditsViewState extends State<SourceCreditsView> {
  final _repo = const QuestionRepository();
  List<String>? _refs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _repo.load();
    if (!mounted) return;
    setState(() => _refs = lawSourceReferences(all));
  }

  @override
  Widget build(BuildContext context) {
    final refs = _refs;
    return Scaffold(
      appBar: AppBar(title: const Text('問題データの出典（法令）')),
      body: refs == null
          ? const Center(child: CircularProgressIndicator())
          : refs.isEmpty
              ? const EmptyState(message: '法令の出典条文はまだありません。', icon: Icons.menu_book_outlined)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: refs.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, i) => ListTile(
                    leading: const Icon(Icons.gavel_outlined),
                    title: Text(refs[i]),
                  ),
                ),
    );
  }
}
