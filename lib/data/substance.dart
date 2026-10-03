/// 第4類危険物の代表物質の性質データ（温度の実験室 §B で使用）。
///
/// 出典確認（2026-10-03、WebSearch経由。e-Gov法令検索・SDS類の内容を
/// 検索結果の要約から確認。原文PDFへの直接アクセスはこの環境のネット
/// ワーク制約で不可のため、各項目は複数の検索結果で一致した値のみ採用）。
/// 発火点は出典間でばらつきが大きい物質があるため、確度の低いものは
/// null にして画面側で「未確認」扱いにする。
class Substance {
  const Substance({
    required this.id,
    required this.name,
    required this.category,
    required this.flashPointC,
    required this.specificGravity,
    required this.waterSoluble,
    required this.designatedQuantityL,
    required this.sourceRef,
    this.ignitionPointC,
  });

  final String id;
  final String name;

  /// 品名（特殊引火物／第一石油類／第二石油類／アルコール類 等）。
  final String category;

  /// 引火点（℃）。
  final double flashPointC;

  /// 発火点（℃）。出典間でばらつきがあり確度が低い場合は null。
  final double? ignitionPointC;

  /// 比重（水=1）。1未満は水に浮く。
  final double specificGravity;

  final bool waterSoluble;

  /// 指定数量（L）。
  final int designatedQuantityL;

  final String sourceRef;

  /// 現在の気温（℃）で引火の危険があるか（気温が引火点以上）。
  bool isFlammableAt(double tempC) => tempC >= flashPointC;
}

const substances = <Substance>[
  Substance(
    id: 'carbon_disulfide',
    name: '二硫化炭素',
    category: '特殊引火物',
    flashPointC: -30,
    ignitionPointC: 100,
    specificGravity: 1.26,
    waterSoluble: false,
    designatedQuantityL: 50,
    sourceRef: '引火点・発火点・比重・水溶性・指定数量をSDS類及び危険物の規制に関する'
        '政令別表第三の要約で確認（2026-10-03、WebSearch経由）。比重1.26は'
        '第4類で唯一水より重い代表例',
  ),
  Substance(
    id: 'diethyl_ether',
    name: 'ジエチルエーテル',
    category: '特殊引火物',
    flashPointC: -45,
    ignitionPointC: 160,
    specificGravity: 0.706,
    waterSoluble: false,
    designatedQuantityL: 50,
    sourceRef: '引火点・比重をSDS類で確認、発火点は複数資料で160℃付近に一致'
        '（2026-10-03、WebSearch経由）',
  ),
  Substance(
    id: 'gasoline',
    name: 'ガソリン',
    category: '第一石油類（非水溶性）',
    flashPointC: -40,
    ignitionPointC: 300,
    specificGravity: 0.70,
    waterSoluble: false,
    designatedQuantityL: 200,
    sourceRef: '引火点-40℃以下・発火点約300℃・比重0.65〜0.75（代表値0.70）を'
        '消防庁・自治体の予防資料で確認（2026-10-03、WebSearch経由）',
  ),
  Substance(
    id: 'ethanol',
    name: 'エタノール',
    category: 'アルコール類',
    flashPointC: 13,
    ignitionPointC: null,
    specificGravity: 0.789,
    waterSoluble: true,
    designatedQuantityL: 400,
    sourceRef: '引火点13℃・比重0.789をSDS類で確認。発火点は出典により'
        '363〜425℃とばらつきが大きいため未確認扱い（2026-10-03、WebSearch経由）',
  ),
  Substance(
    id: 'kerosene',
    name: '灯油',
    category: '第二石油類（非水溶性）',
    flashPointC: 40,
    ignitionPointC: null,
    specificGravity: 0.80,
    waterSoluble: false,
    designatedQuantityL: 1000,
    sourceRef: '引火点40℃以上・比重0.79〜0.80を品質規格資料で確認。発火点は'
        '確度の高い出典が見つからず未確認扱い（2026-10-03、WebSearch経由）',
  ),
  Substance(
    id: 'diesel',
    name: '軽油',
    category: '第二石油類（非水溶性）',
    flashPointC: 45,
    ignitionPointC: null,
    specificGravity: 0.84,
    waterSoluble: false,
    designatedQuantityL: 1000,
    sourceRef: '引火点45℃以上・比重0.86以下（代表値0.84）を品質規格資料で確認。'
        '発火点は220〜250℃と出典にばらつきがあり未確認扱い'
        '（2026-10-03、WebSearch経由）',
  ),
];
