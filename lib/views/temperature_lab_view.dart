import 'package:flutter/material.dart';

import '../data/substance.dart';

/// 温度の実験室（画期的な機能B・温度スライダー）。
///
/// 気温のスライダーを動かすと、引火点を超えた物質が強調表示される。
/// 色だけに頼らず、枠線・アイコン・「引火の危険あり」の文言を併記する。
class TemperatureLabView extends StatefulWidget {
  const TemperatureLabView({super.key});

  @override
  State<TemperatureLabView> createState() => _TemperatureLabViewState();
}

class _TemperatureLabViewState extends State<TemperatureLabView> {
  double _tempC = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('温度の実験室')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '気温のスライダーを動かして、引火点を超える物質を確かめよう。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.thermostat_outlined),
              Expanded(
                child: Slider(
                  value: _tempC,
                  min: -50,
                  max: 50,
                  divisions: 100,
                  label: '${_tempC.round()}℃',
                  onChanged: (v) => setState(() => _tempC = v),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '${_tempC.round()}℃',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final s in substances)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SubstanceCard(substance: s, tempC: _tempC),
            ),
        ],
      ),
    );
  }
}

class _SubstanceCard extends StatelessWidget {
  const _SubstanceCard({required this.substance, required this.tempC});

  final Substance substance;
  final double tempC;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = substance.isFlammableAt(tempC);
    final error = theme.colorScheme.error;

    return Card(
      color: danger ? error.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: danger ? BorderSide(color: error, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${substance.name}（${substance.category}）',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (danger) ...[
                  Icon(Icons.warning_amber, color: error),
                  const SizedBox(width: 4),
                  Text(
                    '引火の危険あり',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: error, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '引火点 ${substance.flashPointC.round()}℃'
              '${substance.ignitionPointC != null ? ' ／ 発火点 ${substance.ignitionPointC!.round()}℃' : ' ／ 発火点 未確認'}',
            ),
            Text(
              '比重 ${substance.specificGravity}'
              '（水に${substance.specificGravity < 1 ? '浮く' : '沈む'}）'
              ' ／ 水に${substance.waterSoluble ? '溶ける' : '溶けにくい'}',
            ),
            const SizedBox(height: 4),
            Text(
              '指定数量 ${substance.designatedQuantityL}L',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
