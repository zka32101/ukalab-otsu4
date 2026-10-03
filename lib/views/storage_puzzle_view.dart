import 'package:flutter/material.dart';

import '../data/storage_puzzle.dart';

/// 貯蔵所パズル（画期的な機能C）。複数の危険物の貯蔵量から
/// 指定数量の倍数の合計（商の和）を計算し、指定数量以上かどうかを判定する。
class StoragePuzzleView extends StatefulWidget {
  const StoragePuzzleView({super.key});

  @override
  State<StoragePuzzleView> createState() => _StoragePuzzleViewState();
}

class _StoragePuzzleViewState extends State<StoragePuzzleView> {
  StoragePuzzle _puzzle = StoragePuzzle.generate(seed: 0);
  bool? _answeredRequiresPermit;
  int _correctCount = 0;
  int _totalCount = 0;

  void _next() {
    setState(() {
      _puzzle = StoragePuzzle.generate(
        seed: DateTime.now().millisecondsSinceEpoch,
      );
      _answeredRequiresPermit = null;
    });
  }

  void _answer(bool requiresPermit) {
    setState(() {
      _answeredRequiresPermit = requiresPermit;
      _totalCount++;
      if (requiresPermit == _puzzle.requiresPermit) _correctCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answered = _answeredRequiresPermit != null;
    final correct = answered && _answeredRequiresPermit == _puzzle.requiresPermit;

    return Scaffold(
      appBar: AppBar(title: const Text('貯蔵所パズル')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '同じ場所でこれらの危険物を貯蔵しています。指定数量以上になるでしょうか？',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final item in _puzzle.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.substance.name}（${item.substance.category}）',
                        ),
                      ),
                      Text('${item.amountL}L', style: theme.textTheme.titleSmall),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (!answered)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _answer(false),
                    child: const Text('指定数量未満'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _answer(true),
                    child: const Text('指定数量以上'),
                  ),
                ),
              ],
            ),
          if (answered) ...[
            Row(
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.cancel,
                  color: correct ? theme.colorScheme.primary : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  correct ? '正解' : '不正解',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: correct ? theme.colorScheme.primary : theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('計算の過程', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (final item in _puzzle.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${item.substance.name}: ${item.amountL}L ÷ '
                          '指定数量${item.substance.designatedQuantityL}L '
                          '= ${item.ratio.toStringAsFixed(2)}倍',
                        ),
                      ),
                    const Divider(),
                    Text(
                      '合計 ${_puzzle.totalRatio.toStringAsFixed(2)}倍'
                      '${_puzzle.requiresPermit ? '（1以上 → 指定数量以上）' : '（1未満 → 指定数量未満）'}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _next, child: const Text('次の問題')),
          ],
          const SizedBox(height: 16),
          Text('$_correctCount / $_totalCount 問正解', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
