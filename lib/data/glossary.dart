/// 乙4の頻出用語（暗記カードで使用）。
///
/// 既存の確認済みデータ（`substance.dart`・`extinguisher.dart`・問題データの
/// 解説文）に基づく基礎用語の定義。新たな一次資料の収集は行っていない。
class GlossaryTerm {
  const GlossaryTerm({required this.term, required this.definition, this.note});

  final String term;
  final String definition;

  /// 補足（他の用語との対比・覚え方のヒントなど）。
  final String? note;
}

const glossaryTerms = <GlossaryTerm>[
  GlossaryTerm(
    term: '引火点',
    definition: '可燃性蒸気を発生し、点火源があれば燃焼を始める最低の液温。',
    note: '温度の実験室の代表6物質では二硫化炭素（-30℃）が最も低い。',
  ),
  GlossaryTerm(
    term: '発火点',
    definition: '点火源が無くても、空気中で自然に燃え始める最低の温度。',
    note: '引火点より高い温度になることが多い（例: ガソリンは引火点-40℃・発火点約300℃）。',
  ),
  GlossaryTerm(
    term: '比重',
    definition: '水（＝1）を基準にした物質の重さの比。1未満なら水に浮く。',
    note: '第四類危険物のほとんどは比重1未満（水に浮く）。二硫化炭素（1.26）は水より重い代表例。',
  ),
  GlossaryTerm(
    term: '水溶性・非水溶性',
    definition: '水に溶けるかどうか。消火剤の選び方に直結する重要な性質。',
    note: '一般の泡消火薬剤は水溶性液体に溶けてしまい効果が無いため、耐アルコール泡を使う。',
  ),
  GlossaryTerm(
    term: '指定数量',
    definition: '危険物の規制の基準となる数量。品名・性質ごとに政令別表第三で定める。',
    note: '指定数量以上の貯蔵・取扱いには許可、未満には届出等の規制がかかる。',
  ),
  GlossaryTerm(
    term: '商の和',
    definition: '2種類以上の危険物を同時に貯蔵・取扱う場合、各物質の貯蔵量を指定数量で割った'
        '値（倍数）の合計。1以上になると指定数量以上とみなす。',
    note: '根拠は消防法第10条（貯蔵）・政令第30条（運搬）。貯蔵所パズルの判定ロジック。',
  ),
  GlossaryTerm(
    term: '特殊引火物',
    definition: '発火点100℃以下、または引火点-20℃以下かつ沸点40℃以下の、第四類の中でも'
        '特に危険性が高い品名。',
    note: '代表例は二硫化炭素・ジエチルエーテル。指定数量は50Lと少ない。',
  ),
  GlossaryTerm(
    term: '保安距離',
    definition: '製造所等が、学校・病院・住宅等の保護対象物から確保しなければならない距離。',
    note: '火災・爆発時の被害が周囲に及ばないようにするための規制。',
  ),
  GlossaryTerm(
    term: '保有空地',
    definition: '製造所等の周囲に確保しなければならない、何も置かない空地。',
    note: '延焼の防止・消火活動のための通路確保が目的。',
  ),
  GlossaryTerm(
    term: '免状の書換え',
    definition: '氏名・本籍地等の記載事項に変更があったときに行う手続き。',
    note: '紛失・汚損・破損による「再交付」とは別の手続き（規則第52条）。',
  ),
  GlossaryTerm(
    term: '保安講習',
    definition: '危険物取扱作業に従事する危険物取扱者が、一定期間ごとに受講する講習。',
    note: '取扱作業に従事していない危険物取扱者は受講対象外（消防法第13条の23）。',
  ),
  GlossaryTerm(
    term: '消火の3要素',
    definition: '燃焼を止める3つの方法。除去（可燃物を取り除く）・窒息（酸素を断つ）・'
        '冷却（温度を下げる）。',
    note: '二酸化炭素消火剤は窒息効果、水は主に冷却効果。',
  ),
  GlossaryTerm(
    term: '第四類危険物の共通性質',
    definition: '引火性の液体で、蒸気は空気より重く低所に溜まりやすい。多くは水より軽く'
        '（比重1未満）、電気の不良導体で静電気を帯びやすい。',
    note: '蒸気が低所に溜まる性質は、換気・排気設備の必要性につながる。',
  ),
];
