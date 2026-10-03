import 'dart:math';

import 'package:flutter/material.dart';

import '../data/extinguisher.dart';
import '../data/substance.dart';

/// 消火マッチング（画期的な機能D）。物質（水溶性かどうか）と
/// 消火剤の組み合わせが有効か不適かを答える。
class ExtinguisherMatchView extends StatefulWidget {
  const ExtinguisherMatchView({super.key});

  @override
  State<ExtinguisherMatchView> createState() => _ExtinguisherMatchViewState();
}

class _ExtinguisherMatchViewState extends State<ExtinguisherMatchView> {
  Substance _substance = substances[Random(0).nextInt(substances.length)];
  final Map<Extinguisher, bool> _answers = {};
  bool _checked = false;
  int _correctCount = 0;
  int _totalCount = 0;

  void _pick(int seed) {
    final random = Random(seed);
    setState(() {
      _substance = substances[random.nextInt(substances.length)];
      _answers.clear();
      _checked = false;
    });
  }

  void _toggle(Extinguisher ext, bool value) {
    if (_checked) return;
    setState(() => _answers[ext] = value);
  }

  void _check() {
    if (_answers.length < Extinguisher.values.length) return;
    final allCorrect = Extinguisher.values.every(
      (ext) =>
          _answers[ext] ==
          ext.isEffectiveFor(waterSoluble: _substance.waterSoluble),
    );
    setState(() {
      _checked = true;
      _totalCount++;
      if (allCorrect) _correctCount++;
    });
  }

  void _next() => _pick(DateTime.now().millisecondsSinceEpoch);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allAnswered = _answers.length == Extinguisher.values.length;

    return Scaffold(
      appBar: AppBar(title: const Text('消火マッチング')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${_substance.name}（${_substance.waterSoluble ? '水溶性' : '非水溶性'}）'
            'の火災に、それぞれの消火剤は有効でしょうか？',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final ext in Extinguisher.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ExtinguisherTile(
                extinguisher: ext,
                substance: _substance,
                answer: _answers[ext],
                checked: _checked,
                onAnswer: (v) => _toggle(ext, v),
              ),
            ),
          const SizedBox(height: 16),
          if (!_checked)
            FilledButton(
              onPressed: allAnswered ? _check : null,
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

class _ExtinguisherTile extends StatelessWidget {
  const _ExtinguisherTile({
    required this.extinguisher,
    required this.substance,
    required this.answer,
    required this.checked,
    required this.onAnswer,
  });

  final Extinguisher extinguisher;
  final Substance substance;
  final bool? answer;
  final bool checked;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correctAnswer =
        extinguisher.isEffectiveFor(waterSoluble: substance.waterSoluble);
    final wrong = checked && answer != correctAnswer;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: wrong
            ? BorderSide(color: theme.colorScheme.error, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(extinguisher.label, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: checked ? null : () => onAnswer(true),
                    style: answer == true
                        ? OutlinedButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.primary.withValues(alpha: 0.12),
                          )
                        : null,
                    child: const Text('有効'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: checked ? null : () => onAnswer(false),
                    style: answer == false
                        ? OutlinedButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.primary.withValues(alpha: 0.12),
                          )
                        : null,
                    child: const Text('不適'),
                  ),
                ),
              ],
            ),
            if (checked) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    correctAnswer ? Icons.check_circle : Icons.cancel,
                    color: correctAnswer
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    correctAnswer ? '正解は「有効」' : '正解は「不適」',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                extinguisher.reasonFor(waterSoluble: substance.waterSoluble),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
