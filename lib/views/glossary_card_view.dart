import 'package:flutter/material.dart';

import '../data/glossary.dart';

/// 乙4の頻出用語の暗記カード。タップで表（用語）・裏（定義）を切り替え、
/// 「次へ」で次の用語に進む。`lib/data/glossary.dart` の既存の確認済み
/// データに基づく定義を使い、新たな一次資料の収集は行っていない。
class GlossaryCardView extends StatefulWidget {
  const GlossaryCardView({super.key});

  @override
  State<GlossaryCardView> createState() => _GlossaryCardViewState();
}

class _GlossaryCardViewState extends State<GlossaryCardView> {
  int _index = 0;
  bool _showDefinition = false;

  void _next() {
    setState(() {
      _index = (_index + 1) % glossaryTerms.length;
      _showDefinition = false;
    });
  }

  void _prev() {
    setState(() {
      _index = (_index - 1 + glossaryTerms.length) % glossaryTerms.length;
      _showDefinition = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final term = glossaryTerms[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('用語集')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${_index + 1} / ${glossaryTerms.length}',
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
