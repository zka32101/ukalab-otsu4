import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exercise_coins.dart';
import '../data/extinguisher.dart';
import '../data/substance.dart';

/// 消火マッチング（画期的な機能D）。物質（水溶性かどうか）と
/// 消火剤の組み合わせが有効か不適かを、カードをドラッグして
/// 「有効」「不適」の枠に振り分けることで答える。
///
/// 企画書にある「線で結ぶ」操作の代わりに、ドラッグ＆ドロップで
/// 分類する形に改善した（2026-10-03。2択ボタン版からの改善）。
class ExtinguisherMatchView extends ConsumerStatefulWidget {
  const ExtinguisherMatchView({super.key});

  @override
  ConsumerState<ExtinguisherMatchView> createState() => _ExtinguisherMatchViewState();
}

class _ExtinguisherMatchViewState extends ConsumerState<ExtinguisherMatchView> {
  Substance _substance = substances[Random(0).nextInt(substances.length)];
  final Map<Extinguisher, bool> _placed = {};
  bool _checked = false;
  int _correctCount = 0;
  int _totalCount = 0;

  List<Extinguisher> get _remaining =>
      Extinguisher.values.where((e) => !_placed.containsKey(e)).toList();

  void _pick(int seed) {
    final random = Random(seed);
    setState(() {
      _substance = substances[random.nextInt(substances.length)];
      _placed.clear();
      _checked = false;
    });
  }

  void _drop(Extinguisher ext, bool zone) {
    if (_checked) return;
    setState(() => _placed[ext] = zone);
  }

  void _unplace(Extinguisher ext) {
    if (_checked) return;
    setState(() => _placed.remove(ext));
  }

  void _check() {
    if (_placed.length < Extinguisher.values.length) return;
    final allCorrect = Extinguisher.values.every(
      (ext) =>
          _placed[ext] ==
          ext.isEffectiveFor(waterSoluble: _substance.waterSoluble),
    );
    setState(() {
      _checked = true;
      _totalCount++;
      if (allCorrect) _correctCount++;
    });
    recordExerciseAnswer(ref, correct: allCorrect);
  }

  void _next() => _pick(DateTime.now().millisecondsSinceEpoch);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allPlaced = _placed.length == Extinguisher.values.length;

    return Scaffold(
      appBar: AppBar(title: const Text('消火マッチング')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${_substance.name}（${_substance.waterSoluble ? '水溶性' : '非水溶性'}）'
            'の火災に、それぞれの消火剤は有効でしょうか？'
            'カードを「有効」か「不適」の枠にドラッグして振り分けよう。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DropZone(
                  label: '有効',
                  color: theme.colorScheme.primary,
                  zoneValue: true,
                  substance: _substance,
                  placed: _placed,
                  checked: _checked,
                  onAccept: (ext) => _drop(ext, true),
                  onTapItem: _unplace,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropZone(
                  label: '不適',
                  color: theme.colorScheme.error,
                  zoneValue: false,
                  substance: _substance,
                  placed: _placed,
                  checked: _checked,
                  onAccept: (ext) => _drop(ext, false),
                  onTapItem: _unplace,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_remaining.isNotEmpty) ...[
            Text('残りのカード', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ext in _remaining)
                  Draggable<Extinguisher>(
                    data: ext,
                    feedback: _ExtinguisherCard(label: ext.label, dragging: true),
                    childWhenDragging:
                        _ExtinguisherCard(label: ext.label, faded: true),
                    child: _ExtinguisherCard(label: ext.label),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (!_checked)
            FilledButton(
              onPressed: allPlaced ? _check : null,
              child: const Text('採点する'),
            ),
          if (_checked)
            FilledButton(onPressed: _next, child: const Text('次の問題')),
          const SizedBox(height: 16),
          Text('$_correctCount / $_totalCount 問正解', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.label,
    required this.color,
    required this.zoneValue,
    required this.substance,
    required this.placed,
    required this.checked,
    required this.onAccept,
    required this.onTapItem,
  });

  final String label;
  final Color color;
  final bool zoneValue;
  final Substance substance;
  final Map<Extinguisher, bool> placed;
  final bool checked;
  final ValueChanged<Extinguisher> onAccept;
  final ValueChanged<Extinguisher> onTapItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = placed.entries.where((e) => e.value == zoneValue).map((e) => e.key);

    return DragTarget<Extinguisher>(
      onWillAcceptWithDetails: (_) => !checked,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return Container(
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            border: Border.all(
              color: highlighted ? color : theme.colorScheme.outlineVariant,
              width: highlighted ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: highlighted ? color.withValues(alpha: 0.08) : null,
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final ext in items)
                    GestureDetector(
                      onTap: checked ? null : () => onTapItem(ext),
                      child: _PlacedCard(
                        extinguisher: ext,
                        substance: substance,
                        givenAnswer: zoneValue,
                        checked: checked,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExtinguisherCard extends StatelessWidget {
  const _ExtinguisherCard({
    required this.label,
    this.dragging = false,
    this.faded = false,
  });

  final String label;
  final bool dragging;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: faded ? 0.3 : 1,
      child: Material(
        elevation: dragging ? 4 : 1,
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(label, style: theme.textTheme.labelLarge),
        ),
      ),
    );
  }
}

class _PlacedCard extends StatelessWidget {
  const _PlacedCard({
    required this.extinguisher,
    required this.substance,
    required this.givenAnswer,
    required this.checked,
  });

  final Extinguisher extinguisher;
  final Substance substance;

  /// このカードが置かれた枠（有効=true／不適=false）。
  final bool givenAnswer;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correctAnswer =
        extinguisher.isEffectiveFor(waterSoluble: substance.waterSoluble);
    final wrong = checked && givenAnswer != correctAnswer;

    return Tooltip(
      message: checked ? extinguisher.reasonFor(waterSoluble: substance.waterSoluble) : '取り除くにはタップ',
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: wrong
                ? Border.all(color: theme.colorScheme.error, width: 2)
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(extinguisher.label, style: theme.textTheme.labelLarge),
              if (checked) ...[
                const SizedBox(width: 6),
                Icon(
                  wrong ? Icons.cancel : Icons.check_circle,
                  size: 16,
                  color: wrong ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
