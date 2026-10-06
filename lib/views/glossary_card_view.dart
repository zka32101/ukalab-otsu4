import 'package:flutter/material.dart';

import '../data/glossary.dart';

/// 分野フィルタの選択肢（表示名）。nullは「すべて」。
const _subjectFilterLabels = <String?, String>{
  null: 'すべて',
  'law': '法令',
  'physics_chem': '物理化学',
  'property_extinguish': '性質・消火',
};

/// 乙4の頻出用語の暗記カード。タップで表（用語）・裏（定義）を切り替え、
/// 「次へ」で次の用語に進む。分野（法令・物理化学・性質消火）で絞り込める。
/// `lib/data/glossary.dart` の既存の確認済みデータに基づく定義を使い、
/// 新たな一次資料の収集は行っていない。
class GlossaryCardView extends StatefulWidget {
  const GlossaryCardView({super.key, this.initialTerm});

  /// 開いた直後に表示する用語（検索・解説文中のタップから遷移した場合）。
  /// 一致しなければ最初の用語から表示する（フィルタは「すべて」で開く）。
  final String? initialTerm;

  @override
  State<GlossaryCardView> createState() => _GlossaryCardViewState();
}

class _GlossaryCardViewState extends State<GlossaryCardView> {
  String? _subjectFilter;
  late List<GlossaryTerm> _terms;
  late int _index;
  late bool _showDefinition;

  @override
  void initState() {
    super.initState();
    _terms = glossaryTerms;
    final found = widget.initialTerm == null
        ? -1
        : _terms.indexWhere((t) => t.term == widget.initialTerm);
    _index = found >= 0 ? found : 0;
    // 検索・解説文中のタップから来た場合は、用語名ではなく定義を直接見せる。
    _showDefinition = found >= 0;
  }

  void _setFilter(String? subjectId) {
    setState(() {
      _subjectFilter = subjectId;
      _terms = subjectId == null ? glossaryTerms : glossaryTermsBySubject(subjectId);
      _index = 0;
      _showDefinition = false;
    });
  }

  void _next() {
    setState(() {
      _index = (_index + 1) % _terms.length;
      _showDefinition = false;
    });
  }

  void _prev() {
    setState(() {
      _index = (_index - 1 + _terms.length) % _terms.length;
      _showDefinition = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final term = _terms[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('用語集')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final entry in _subjectFilterLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _subjectFilter == entry.key,
                    onSelected: (_) => _setFilter(entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${_index + 1} / ${_terms.length}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showDefinition = !_showDefinition),
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
                  child: OutlinedButton(onPressed: _prev, child: const Text('前へ')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: _next, child: const Text('次へ')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
