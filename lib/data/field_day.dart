import 'dart:math';

import 'extinguisher.dart';
import 'substance.dart';

/// 現場の1日モード（画期的な機能E）の1つの場面。
///
/// 温度の実験室（引火点）・貯蔵所パズル（指定数量）・消火マッチング
/// （消火剤の適否）という、既に一次資料確認済みの3つのロジックを
/// 「1日の勤務」の場面として順番に問う。新たな未確認データは追加しない。
class FieldDayStep {
  const FieldDayStep({
    required this.timeLabel,
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
  });

  final String timeLabel;
  final String prompt;

  /// 2択の選択肢。
  final List<String> choices;
  final int correctIndex;
  final String explanation;
}

/// 1日分（4つの場面）の現場シナリオ。
class FieldDayScenario {
  const FieldDayScenario(this.steps);

  final List<FieldDayStep> steps;

  static const _timeLabels = ['08:00', '11:00', '14:00', '17:00'];

  static FieldDayScenario generate({required int seed}) {
    final random = Random(seed);
    final steps = [for (final t in _timeLabels) _buildStep(random, t)];
    return FieldDayScenario(steps);
  }

  static FieldDayStep _buildStep(Random random, String timeLabel) {
    switch (random.nextInt(3)) {
      case 0:
        return _temperatureStep(random, timeLabel);
      case 1:
        return _storageStep(random, timeLabel);
      default:
        return _extinguisherStep(random, timeLabel);
    }
  }

  /// 引火点に基づく危険性の判断（根拠: `Substance.isFlammableAt`）。
  static FieldDayStep _temperatureStep(Random random, String timeLabel) {
    final s = substances[random.nextInt(substances.length)];
    final hot = random.nextBool();
    final offset = 5 + random.nextInt(10);
    final tempC = s.flashPointC + (hot ? offset : -offset);
    final flammable = s.isFlammableAt(tempC);
    return FieldDayStep(
      timeLabel: timeLabel,
      prompt: '気温${tempC.toStringAsFixed(0)}℃。${s.name}（引火点${s.flashPointC.toStringAsFixed(0)}℃）'
          'を取り扱う。引火の危険はある？',
      choices: const ['危険性あり', '危険性なし'],
      correctIndex: flammable ? 0 : 1,
      explanation: '引火点は${s.flashPointC.toStringAsFixed(0)}℃。気温が引火点以上だと蒸気が引火しうる。',
    );
  }

  /// 指定数量と許可の要否（根拠: 消防法第10条、商の和）。
  static FieldDayStep _storageStep(Random random, String timeLabel) {
    final s = substances[random.nextInt(substances.length)];
    final needsPermit = random.nextBool();
    final factor = needsPermit ? 1.5 : 0.5;
    final amountL = ((s.designatedQuantityL * factor) ~/ 10) * 10;
    final ratio = amountL / s.designatedQuantityL;
    return FieldDayStep(
      timeLabel: timeLabel,
      prompt: '${s.name}を${amountL}L貯蔵する。許可は必要？',
      choices: const ['必要', '不要'],
      correctIndex: needsPermit ? 0 : 1,
      explanation: '指定数量（${s.designatedQuantityL}L）の${ratio.toStringAsFixed(2)}倍'
          '${needsPermit ? '。1以上のため許可が必要。' : '。1未満のため許可は不要。'}',
    );
  }

  /// 消火剤の適否（根拠: `Extinguisher.isEffectiveFor`）。
  static FieldDayStep _extinguisherStep(Random random, String timeLabel) {
    final s = substances[random.nextInt(substances.length)];
    final e = Extinguisher.values[random.nextInt(Extinguisher.values.length)];
    final effective = e.isEffectiveFor(waterSoluble: s.waterSoluble);
    return FieldDayStep(
      timeLabel: timeLabel,
      prompt: '${s.name}の火災に${e.label}を使う。これは正しい判断？',
      choices: const ['正しい（有効）', '誤り（不適）'],
      correctIndex: effective ? 0 : 1,
      explanation: e.reasonFor(waterSoluble: s.waterSoluble),
    );
  }
}
