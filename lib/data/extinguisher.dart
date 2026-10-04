/// 消火剤の種類（画期的な機能D・消火マッチングで使用）。
///
/// 根拠（2026-10-04、e-Gov法令検索APIで取得した危険物の規制に関する
/// 政令別表第五〈第20条関係〉の原文で確認。README参照）:
/// - 水は、水に溶けない危険物（ガソリン等）にかけると水面に浮いて
///   火災が広がるため不適
/// - 一般泡（たん白泡・水成膜泡）は水に溶けない危険物に有効だが、
///   水溶性液体（アルコール等）には泡が溶けてしまい効果が無い
/// - 耐アルコール泡（水溶性液体用泡消火薬剤）は水溶性・非水溶性の
///   どちらにも有効
/// - 粉末はガソリン・灯油等の油火災に有効
/// - 二酸化炭素（を放射する消火器・不活性ガス消火設備）は、別表第五で
///   電気設備・引火性固体・第四類の危険物に適応（○）と定められており、
///   窒息効果のため水溶性・非水溶性のどちらにも有効
enum Extinguisher {
  water('水（棒状・霧状）'),
  foam('一般泡（たん白泡・水成膜泡）'),
  alcoholFoam('耐アルコール泡（水溶性液体用泡消火薬剤）'),
  powder('粉末'),
  co2('二酸化炭素');

  const Extinguisher(this.label);

  final String label;

  /// その危険物（水溶性かどうか）に効果があるか。
  bool isEffectiveFor({required bool waterSoluble}) {
    switch (this) {
      case Extinguisher.water:
        return false;
      case Extinguisher.foam:
        return !waterSoluble;
      case Extinguisher.alcoholFoam:
        return true;
      case Extinguisher.powder:
        return true;
      case Extinguisher.co2:
        return true;
    }
  }

  /// 正誤の理由（短い説明）。
  String reasonFor({required bool waterSoluble}) {
    switch (this) {
      case Extinguisher.water:
        return '水をかけると危険物が水面に浮いて火災が広がる。';
      case Extinguisher.foam:
        return waterSoluble
            ? '一般の泡は水溶性の液体に溶けてしまい、消火の効果がなくなる。'
            : '泡の層で覆い、空気を絶って消火する。';
      case Extinguisher.alcoholFoam:
        return '泡が溶けにくく作られているため、水溶性・非水溶性のどちらにも使える。';
      case Extinguisher.powder:
        return '粉末が燃焼を抑え、油火災に広く使われる。';
      case Extinguisher.co2:
        return '二酸化炭素が酸素を遮断して窒息消火するため、水溶性・非水溶性のどちらにも使える'
            '（政令別表第五で第四類に適応）。';
    }
  }
}
