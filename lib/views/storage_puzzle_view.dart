import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exercise_coins.dart';
import '../data/storage_puzzle.dart';
import '../data/substance.dart';

/// 貯蔵所パズル（画期的な機能C）。複数の危険物の貯蔵量から
/// 指定数量の倍数の合計（商の和）を計算し、指定数量以上かどうかを判定する。
///
/// 自動生成された物質リストに加え、物質の追加・削除・量の調整ができる。
/// 「もしこの物質を減らしたら／もう1種類加えたら」を試しながら、
/// 商の和の感覚をつかめるようにしている。
class StoragePuzzleView extends ConsumerStatefulWidget {
  const StoragePuzzleView({super.key});

  @override
  ConsumerState<StoragePuzzleView> createState() => _StoragePuzzleViewState();
}

class _StoragePuzzleViewState extends ConsumerState<StoragePuzzleView> {
  List<StorageItem> _items = StoragePuzzle.generate(seed: 0).items;
  bool? _answeredRequiresPermit;
  int _correctCount = 0;
  int _totalCount = 0;

  StoragePuzzle get _puzzle => StoragePuzzle(_items);
  bool get _answered => _answeredRequiresPermit != null;

  void _newRandomPuzzle() {
    setState(() {
      _items = StoragePuzzle.generate(
        seed: DateTime.now().millisecondsSinceEpoch,
      ).items;
      _answeredRequiresPermit = null;
    });
  }

  void _removeItem(int index) {
    if (_answered) return;
    setState(() => _items.removeAt(index));
  }

  void _adjustAmount(int index, int deltaL) {
    if (_answered) return;
    setState(() {
      final item = _items[index];
      final newAmount = (item.amountL + deltaL).clamp(10, 999990).toInt();
      _items[index] = StorageItem(substance: item.substance, amountL: newAmount);
    });
  }

  Future<void> _addItem() async {
    if (_answered) return;
    final used = _items.map((i) => i.substance.id).toSet();
    final candidates = substances.where((s) => !used.contains(s.id)).toList();
    if (candidates.isEmpty) return;
    final picked = await showModalBottomSheet<Substance>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in candidates)
              ListTile(
                title: Text(s.name),
                subtitle: Text('${s.category}・指定数量${s.designatedQuantityL}L'),
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _items.add(
        StorageItem(
          substance: picked,
          amountL: ((picked.designatedQuantityL * 0.5) ~/ 10) * 10,
        ),
      );
    });
  }

  void _answer(bool requiresPermit) {
    final correct = requiresPermit == _puzzle.requiresPermit;
    setState(() {
      _answeredRequiresPermit = requiresPermit;
      _totalCount++;
      if (correct) _correctCount++;
    });
    recordExerciseAnswer(ref, correct: correct);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correct = _answered && _answeredRequiresPermit == _puzzle.requiresPermit;

    return Scaffold(
      appBar: AppBar(title: const Text('貯蔵所パズル')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '同じ場所でこれらの危険物を貯蔵しています。指定数量以上になるでしょうか？'
            '物質の追加・削除・量の調整もできます。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_items[i].substance.name}（${_items[i].substance.category}）',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: '10L減らす',
                        onPressed: _answered ? null : () => _adjustAmount(i, -10),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          '${_items[i].amountL}L',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: '10L増やす',
                        onPressed: _answered ? null : () => _adjustAmount(i, 10),
                      ),
                      if (!_answered)
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: '取り除く',
                          onPressed: () => _removeItem(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_answered)
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('物質を追加する'),
            ),
          const SizedBox(height: 16),
          if (!_answered)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _items.isEmpty ? null : () => _answer(false),
                    child: const Text('指定数量未満'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _items.isEmpty ? null : () => _answer(true),
                    child: const Text('指定数量以上'),
                  ),
                ),
              ],
            ),
          if (_answered) ...[
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
                    for (final item in _items)
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _answeredRequiresPermit = null),
                    child: const Text('編成し直す'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _newRandomPuzzle,
                    child: const Text('次の問題'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text('$_correctCount / $_totalCount 問正解', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
