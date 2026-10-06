import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/glossary.dart';
import '../data/recent_glossary_terms_store.dart';
import 'glossary_card_view.dart';

/// 最近見た用語集の用語（新しい順）の一覧。用語集カードで定義を見ると
/// 記録され、タップするとその用語の定義に戻れる（`lib/data/recent_glossary_terms_store.dart`）。
class RecentGlossaryTermsView extends ConsumerWidget {
  const RecentGlossaryTermsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTerms = ref.watch(recentGlossaryTermsProvider);
    final byTerm = {for (final t in glossaryTerms) t.term: t};

    return Scaffold(
      appBar: AppBar(title: const Text('最近見た用語')),
      body: recentTerms.isEmpty
          ? const EmptyState(
              message: '用語集で定義を見ると、ここに記録されます。',
              icon: Icons.history_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recentTerms.length,
              itemBuilder: (context, i) {
                final term = recentTerms[i];
                final glossaryTerm = byTerm[term];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(term),
                    subtitle: glossaryTerm == null
                        ? null
                        : Text(
                            glossaryTerm.definition,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => GlossaryCardView(initialTerm: term)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
