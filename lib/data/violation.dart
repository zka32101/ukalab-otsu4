import 'dart:math';

import 'extinguisher.dart';
import 'substance.dart';

/// 違反探しモード（画期的な機能A）で使う1つの行動の記述。
///
/// `lib/data/extinguisher.dart`（消火剤の適否）と `lib/data/substance.dart`
/// （指定数量）という、既に一次資料確認済みのロジックのみを組み合わせて
/// 生成する。新たに未確認のルール（換気・保管場所の条件等）は含めない。
class ViolationStatement {
  const ViolationStatement({
    required this.text,
    required this.isViolation,
    required this.explanation,
  });

  final String text;
  final bool isViolation;
  final String explanation;
}

/// 4つの行動のうち1つだけが違反になっているシナリオ。
class ViolationScenario {
  const ViolationScenario(this.statements);

  final List<ViolationStatement> statements;

  int get violationIndex => statements.indexWhere((s) => s.isViolation);

  static ViolationScenario generate({required int seed}) {
    final random = Random(seed);
    final violationSlot = random.nextInt(4);
    final statements = <ViolationStatement>[
      for (var i = 0; i < 4; i++) _buildStatement(random, violation: i == violationSlot),
    ];
    return ViolationScenario(statements);
  }

  static ViolationStatement _buildStatement(Random random, {required bool violation}) {
    return random.nextBool()
        ? _extinguisherStatement(random, violation: violation)
        : _storageStatement(random, violation: violation);
  }

  /// 消火剤の適否に関する行動（根拠: `Extinguisher.isEffectiveFor`）。
  static ViolationStatement _extinguisherStatement(Random random, {required bool violation}) {
    final s = substances[random.nextInt(substances.length)];
    final candidates = Extinguisher.values
        .where((e) => e.isEffectiveFor(waterSoluble: s.waterSoluble) == !violation)
        .toList();
    final e = candidates[random.nextInt(candidates.length)];
    return ViolationStatement(
      text: '${s.name}の火災に${e.label}を使って消火した。',
      isViolation: violation,
      explanation: e.reasonFor(waterSoluble: s.waterSoluble),
    );
  }

  /// 指定数量と許可の要否に関する行動（根拠: 消防法第10条、商の和）。
  static ViolationStatement _storageStatement(Random random, {required bool violation}) {
    final s = substances[random.nextInt(substances.length)];
    final factor = violation ? 1.5 : 0.5;
    final amountL = ((s.designatedQuantityL * factor) ~/ 10) * 10;
    final ratio = amountL / s.designatedQuantityL;
    return ViolationStatement(
      text: '${s.name}を${amountL}L、許可を取らずに貯蔵した。',
      isViolation: violation,
      explanation: '指定数量（${s.designatedQuantityL}L）の${ratio.toStringAsFixed(2)}倍'
          '${violation ? '。1以上のため、本来は許可が必要。' : '。1未満のため、許可は不要。'}',
    );
  }
}
