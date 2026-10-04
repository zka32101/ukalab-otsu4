# うかラボ 危険物乙4

危険物取扱者乙種第4類の学習アプリ。「うかラボ」シリーズの第1陣4番目（決定66）。

本アプリは免責事項として、消防試験研究センター等の試験実施団体とは無関係の非公式アプリであることをアプリ内に明記している（`lib/views/settings_view.dart` の `appDisclaimer`）。

## 位置づけ

```
このアプリ（ukalab-otsu4） → yourwish_kentei（検定エンジン、tag固定） → app_common_kit（共通基盤、tag固定）
```

このリポジトリが持つのは、試験定義（ExamConfig）・問題データ・テーマ（資格ID）・ストア設定のみ。共通の仕組みは `app_common_kit` / `yourwish_kentei` 側にあり、ここでは作り直さない。

- `app_common_kit`: `ref: v0.4.0`
- `yourwish_kentei`: `ref: v0.4.0`
- 資格ID: `UkalabCert.hazmat4`（app_common_kit に実装済み。テーマ色 ライト `#C23D16` / ダーク `#F0997F`）

## 現在の状態（2026-10-03）

- [x] pubspec.yaml（依存をタグ固定で追加）
- [x] ExamConfig（`assets/exam/hazmat4_exam.json`）: 法令15問・物理化学10問・性質消火10問の計35問、2時間、科目別60%以上で合格（消防試験研究センター 公式試験案内で確認済み）。`subjectQuestionCounts` で科目別の出題数配分を明示（`yourwish_kentei` v0.4.0 で追加）
- [ ] 問題データ（約600問。法令240／物理化学180／性質消火180、計算問題は自動生成併用）: **未着手**。理由は下記「一次資料アクセスの制約」を参照
- [ ] Flutter プロジェクトの雛形（`flutter create` で生成する android/ios/web 等）: **未生成**。このクラウド実行環境に Flutter/Dart SDK が入っておらず、`flutter create`・`flutter pub get`・`dart analyze` の実行確認ができないため。ローカル（Windows実機。日本語パス回避）で `flutter create .` 相当を行い、本リポジトリの `pubspec.yaml`・`lib/`・`assets/` をマージすることを想定
- [x] lib/（基本学習フローのみ）: ホーム（試験概要）・学ぶ（一問一答。`PracticeSession`）・模擬試験（`scoreMockExam`）・記録（`ProgressSnapshot` による暫定の解答数・正答率・連続学習日数の表示。`lib/views/record_view.dart`）・設定（免責文言）を実装。`UkalabShell`・`QuestionCard`・`ChoiceTile`・`ExplanationPanel`・`ResultSummary`・`EmptyState`・`ErrorState`（app_common_kit）を使用。**このクラウド環境に Flutter/Dart SDK が無く `flutter pub get`・`dart analyze`・実機確認を一度も行っていない。** ローカル環境で確認してから取り込むこと
- [x] 画期的な機能B「温度の実験室」（`lib/views/temperature_lab_view.dart`）: 気温スライダーで引火点を超えた物質が強調表示される。代表6物質（ガソリン・灯油・軽油・エタノール・ジエチルエーテル・二硫化炭素）の引火点・比重・水溶性・指定数量（`lib/data/substance.dart`）。学ぶタブの空状態から遷移。この機能は学習体験の「型」を使わず独立実装なので、`yourwish_kentei` 側の型実装を待たずに着手できた
- [x] 画期的な機能C「貯蔵所パズル」（`lib/views/storage_puzzle_view.dart`）: 複数物質の貯蔵量から指定数量の倍数の合計（商の和）を計算し、1以上（指定数量以上＝許可が必要）かを判定するクイズ形式。`lib/data/storage_puzzle.dart` で2〜3種類の物質と量を自動生成。根拠は消防法第10条（商の和が1以上で指定数量以上とみなす）。物質の追加・削除・量の調整（±10L）ができ、「もし減らしたら／もう1種類加えたら」を試しながら回答できる。企画書にある容器のドラッグ&ドロップ操作そのものは未実装（後続の改善に回す）
- [x] 画期的な機能D「消火マッチング」（`lib/views/extinguisher_match_view.dart`）: 物質（水溶性かどうか）と消火剤4種（水・一般泡・耐アルコール泡・粉末）の組み合わせが有効か不適かを答えるクイズ形式。`lib/data/extinguisher.dart` に判定ロジックと理由文を集約。二酸化炭素は第4類への適用を示す確度の高い資料が見つからず対象から除外した。企画書にある「線で結ぶ」操作に近づけ、カードをドラッグ＆ドロップで「有効」「不適」の枠に振り分ける形に改善済み（2026-10-03。配置し直しも可能）
- [x] 画期的な機能A「違反探しモード」（`lib/views/violation_hunt_view.dart`）: 4つの行動のうち、法令・消火の知識に違反しているものを1つ見つけるクイズ形式。新たな未確認データは追加せず、既に確認済みの `extinguisher.dart`（消火剤の適否）・`substance.dart`（指定数量）のロジックのみを組み合わせて `lib/data/violation.dart` で生成
- [x] 画期的な機能E「現場の1日」（`lib/views/field_day_view.dart`）: 1日の勤務を模した4つの場面（08:00/11:00/14:00/17:00）で、温度（引火点）・指定数量・消火剤の判断を順番に答える。新たな未確認データは追加せず、既存の3つのロジック（`substance.dart`・`extinguisher.dart`・指定数量の考え方）を場面として組み合わせた `lib/data/field_day.dart` で生成
- [x] 推し（MascotWidget）・学習コイン（`lib/widgets/oshi_card.dart`・`lib/main.dart`）: app_common_kit v0.4.0 の `MascotWidget`・`CoinService`・`OutfitService`・`WardrobeScreen`・`showPassReportDialog` を導入（`kanken`・`bike` の `oshi_card.dart` を手本にした）。ホーム画面に推しカードを表示し、着替え・ショップ・合格報告ができる。

  **問題データが無い間の暫定措置**: `lib/views/home_view.dart` には元々「推し・コインの実装は問題データ投入後」という方針のTODOがあったが、ユーザー判断（2026-10-03）により、問題データが無い今の段階でも画期的な機能A〜E・一問一答の解答数を暫定の進捗指標として使い、先行して統合した（`lib/data/progress_store.dart` の `ProgressSnapshot`。網羅率は「100問相当で頭打ち」とする暫定の目安、正答率は解答に対する正解率）。問題データが入ったら、`yourwish_kentei` の `Question` の網羅率・正答率に基づく正式な計算に差し替えること。コインは、A〜Eの演習の正解時に `CoinEvent.reviewCorrected`（本来は「間隔を空けた復習」用の枠だが、固定の問題IDが無いA〜Eでは代わりにこの枠を再利用する製品判断。1日20問・2コインまで）、模擬試験の実施・合格時に `CoinEvent.mockDone`/`mockPass` を付与する。課金・広告視聴での付与は実装していない（仕様どおり）。
- [x] テスト（`test/`）: 画期的な機能A〜E・貯蔵所パズルの判定ロジック（`substance`・`extinguisher`・`storage_puzzle`・`violation`・`field_day`）と、推し・コインの暫定進捗（`progress_store` の `ProgressSnapshot`・`ProgressService`）の単体テストを追加。**このクラウド環境に Flutter/Dart SDK が無く `flutter test` を一度も実行していない。** ローカル環境で実行して確認すること
- [ ] `yourwish_kentei` の学習体験の「型」（決定76の9種。乙4で使うのは⑤〜⑨）: まだ無く、G検定セッションでの型①〜④の実装もまだリポジトリ上には見当たらない（2026-10-03時点）。型の実装状況を確認してから着手する

## 一次資料アクセスの制約（重要）

バイク免許プロジェクトの教訓により、法令問題は e-Gov 法令検索などの一次資料で原文確認してから作成する方針だが、**このクラウド実行環境のネットワーク出口ポリシーが `laws.e-gov.go.jp` や `www.shoubo-shiken.or.jp` への直接アクセスを拒否する**（WebFetch が `EGRESS_BLOCKED`）。Web検索のスニペット経由では断片的な情報しか得られず、条文全文の確認はできない。

ユーザー判断（2026-10-02）により、今回は問題データ作成を見送り、基盤整備のみ先に進めた。次回以降、一次資料にアクセスできる別環境で作業するか、必要な条文（危険物の規制に関する政令 別表第三〈指定数量〉、危険物の規制に関する規則の各規定など）をユーザーから共有してもらった上で着手する。

**物性データ（`lib/data/substance.dart`）について**: WebFetch による一次資料への直接アクセスは不可だが、WebSearch の検索結果スニペット経由では断片的な情報が得られる。複数の検索結果で一致した値（引火点・比重・水溶性・指定数量）のみ採用し、出典間でばらつきが大きい発火点（灯油・軽油・エタノール）は `null`（未確認）として画面に出さない設計にした。正式な問題データとして配信する前に、これらの値を一次資料で改めて確認すること。

## ExamConfig モデルの制約（解消済み）

`yourwish_kentei` の `LevelConfig` に科目別の出題数配分を表すフィールドが無いという制約があったが、`yourwish_kentei` v0.4.0（[PR #4](https://github.com/zka32101/yourwish_kentei/pull/4)）で `LevelConfig.subjectQuestionCounts` と `pickMockExamQuestions` が追加され解消した。`hazmat4_exam.json` の `subjectQuestionCounts`（法令15／物理化学10／性質消火10）と `lib/views/mock_exam_view.dart` の `pickMockExamQuestions` 呼び出しで反映済み。

## 手本にするアプリ

`zka32101/kanken`・`zka32101/bike` が app_common_kit 統合済みの手本。`bike` は `yourwish_kentei` も依存に持つ（ただし問題データは bike 独自形式で、`yourwish_kentei` の `Question`/`validate_content` 形式とは異なる点に注意）。

## 関連ドキュメント

設計書は Google Drive（`design/kentei-engine（うかラボ）`）。特に:
- `kentei_engine_現行サマリー_v1_0.md`（索引。矛盾があればこれが優先）
- `ukalab_共通基盤_各資格アプリ向けガイド_v0_2.md`
- `ukalab_危険物乙4_企画設計書_v0_1.md`・`ukalab_危険物乙4_競合調査_v1_0.md`
- `ukalab_共通デザイン仕様_v0_4.md`・`ukalab_マスコット仕様_v0_2.md`・`ukalab_推し_資格連動要素_v0_1.md`・`ukalab_学習コイン仕様_v0_1.md`
