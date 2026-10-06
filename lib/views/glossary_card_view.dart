import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/glossary.dart';
import '../data/glossary_favorite_store.dart';
import '../data/recent_glossary_terms_store.dart';
import 'recent_glossary_terms_view.dart';

/// 分野フィルタの選択肢（表示名）。nullは「すべて」。
const _subjectFilterLabels = <String?, String>{
  null: 'すべて',
  'law': '法令',
  'physics_chem': '物理化学',
  'property_extinguish': '性質・消火',
};

/// 乙4の頻出用語の暗記カード。タップで表（用語）・裏（定義）を切り替え、
/// 「次へ」で次の用語に進む。分野（法令・物理化学・性質消火）やお気に入り
/// （`lib/data/glossary_favorite_store.dart`）で絞り込める。
/// `lib/data/glossary.dart` の既存の確認済みデータに基づく定義を使い、
/// 新たな一次資料の収集は行っていない。
class GlossaryCardView extends ConsumerStatefulWidget {
  const GlossaryCardView({super.key, this.initialTerm});

  /// 開いた直後に表示する用語（検索・解説文中のタップから遷移した場合）。
  /// 一致しなければ最初の用語から表示する（フィルタは「すべて」で開く）。
  final String? initialTerm;

  @override
  ConsumerState<GlossaryCardView> createState() => _GlossaryCardViewState();
}

class _GlossaryCardViewState extends ConsumerState<GlossaryCardView> {
  String? _subjectFilter;
  bool _favoritesOnly = false;
  late int _index;
  late bool _showDefinition;

  @override
  void initState() {
    super.initState();
    final found = widget.initialTerm == null
        ? -1
        : glossaryTerms.indexWhere((t) => t.term == widget.initialTerm);
    _index = found >= 0 ? found : 0;
    // 検索・解説文中のタップから来た場合は、用語名ではなく定義を直接見せる。
    _showDefinition = found >= 0;
    if (_showDefinition) {
      ref.read(recentGlossaryTermsProvider.notifier).record(widget.initialTerm!);
    }
  }

  void _setSubjectFilter(String? subjectId) {
    setState(() {
      _subjectFilter = subjectId;
      _index = 0;
      _showDefinition = false;
    });
  }

  void _toggleFavoritesOnly() {
    setState(() {
      _favoritesOnly = !_favoritesOnly;
      _index = 0;
      _showDefinition = false;
    });
  }

  void _next(int length) {
    setState(() {
      _index = (_index + 1) % length;
      _showDefinition = false;
    });
  }

  void _prev(int length) {
    setState(() {
      _index = (_index - 1 + length) % length;
      _showDefinition = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favorites = ref.watch(glossaryFavoriteProvider);
    final terms = filterGlossaryTerms(
      subjectId: _subjectFilter,
      favoritesOnly: _favoritesOnly,
      favoriteTerms: favorites,
    );

    final filterRow = Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final entry in _subjectFilterLabels.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: _subjectFilter == entry.key,
                onSelected: (_) => _setSubjectFilter(entry.key),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            label: const Text('お気に入りのみ'),
            selected: _favoritesOnly,
            onSelected: (_) => _toggleFavoritesOnly(),
          ),
        ),
      ],
    );

    final historyAction = IconButton(
      icon: const Icon(Icons.history_outlined),
      tooltip: '最近見た用語',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RecentGlossaryTermsView()),
      ),
    );

    if (terms.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('用語集'), actions: [historyAction]),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              filterRow,
              const SizedBox(height: 24),
              const Expanded(
                child: Center(child: Text('該当する用語がありません。')),
              ),
            ],
          ),
        ),
      );
    }

    final index = _index.clamp(0, terms.length - 1);
    final term = terms[index];
    final isFavorite = favorites.contains(term.term);

    return Scaffold(
      appBar: AppBar(title: const Text('用語集'), actions: [historyAction]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            filterRow,
            const SizedBox(height: 12),
            Text(
              '${index + 1} / ${terms.length}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      final nextShowDefinition = !_showDefinition;
                      setState(() => _showDefinition = nextShowDefinition);
                      if (nextShowDefinition) {
                        ref.read(recentGlossaryTermsProvider.notifier).record(term.term);
                      }
                    },
                    child: Card(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _showDefinition
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      term.definition,
                                      style: theme.textTheme.titleMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                    if (term.note != null) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        term.note!,
                                        style: theme.textTheme.bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                )
                              : Text(
                                  term.term,
                                  style: theme.textTheme.headlineSmall,
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                      color: isFavorite ? theme.colorScheme.primary : null,
                      tooltip: isFavorite ? 'お気に入りを解除' : 'お気に入りに追加',
                      onPressed: () => ref.read(glossaryFavoriteProvider.notifier).toggle(term.term),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showDefinition ? 'タップで用語に戻る' : 'タップで定義を見る',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _prev(terms.length),
                    child: const Text('前へ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _next(terms.length),
                    child: const Text('次へ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
