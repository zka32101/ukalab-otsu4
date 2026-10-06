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

## 現在の状態（2026-10-04）

- [x] pubspec.yaml（依存をタグ固定で追加）
- [x] ExamConfig（`assets/exam/hazmat4_exam.json`）: 法令15問・物理化学10問・性質消火10問の計35問、2時間、科目別60%以上で合格（消防試験研究センター 公式試験案内で確認済み）。`subjectQuestionCounts` で科目別の出題数配分を明示（`yourwish_kentei` v0.4.0 で追加）
- [x] 問題データ・法令（第一〜五弾。`assets/questions/law.jsonl`、62問）: ユーザーが e-Gov法令検索APIで取得した消防法・危険物の規制に関する政令・同規則の条文原文（Google Drive `乙4_一次資料_2026-10-04` フォルダ）に基づき作成。指定数量・商の和（貯蔵: 消防法第10条、運搬: 政令第30条）・別表第一の品名・別表第三の指定数量・免状（交付・書換え・記載事項）・保安講習（受講対象・期限）・混載禁止・貯蔵の通則・消火設備の適応性と区分（別表第五・第20条）・保安距離・保有空地（製造所・屋外貯蔵所）・給油取扱所の給油空地と取扱基準・移動タンク貯蔵所の容量と移送・簡易タンク貯蔵所の基準・屋内タンク貯蔵所の容量・一般取扱所の基準（製造所基準の準用）・引火点試験方法（政令第1条の6）・指定数量の定義（政令第1条の11）・運搬容器の材質と構造・積み重ね高さと表示・遮光性被覆・販売取扱所の区分・製造工程の基準・廃棄基準等をカバー。収集済みの条文原文のうち、結合セルで列がずれる可能性がある別表（規則別表第3〜第3の4）は目視照合ができないため問題化を避けた。これで収集済みの条文原文（01_shobo_ho.txt・02_seirei.txt・03_kisoku.txt。別表を除く）をほぼ使い切った
- [x] 問題データ・性質並びに火災予防及び消火の方法（第一〜二弾。`assets/questions/property_extinguish.jsonl`、20問）: 政令第11条・第25条・別表第五の条文原文と、一次資料で確認済みの `substance.dart`・`extinguisher.dart`（引火点・発火点・比重・水溶性・消火剤の適否）に基づき作成。二硫化炭素の水没貯蔵・消火設備の適応性・比重の傾向・特殊引火物の性質・代表6物質の引火点・発火点・気温による引火の危険性の判断等をカバー
- [x] 問題データ・基礎的な物理学及び基礎的な化学（第一弾。`assets/questions/physics_chem.jsonl`、10問）: 法令・性質消火と異なり対応する条文が無い分野のため、中学・高校理科の標準的な知識（燃焼の三要素・引火点と発火点の違い・自然発火のしくみ・静電気・状態変化・ヘスの法則による熱量計算・単体/化合物/混合物・酸化還元・pH/中和・気体の法則）に基づき独自に作成（`source: original`）。ユーザーがGoogle Driveに追加した乙4の過去問・学習教材（2026-10-06）は、出題傾向の参考のみに使い、問題文・選択肢・数値は独自に作成した（過去問の著作権・学習教材の私的利用限定の制約を踏まえたユーザー判断）。摩擦帯電が電子の移動によることや自然発火の発熱の種類等はWebSearchで裏付けを確認。`test/question_data_test.dart` で3ファイル合計92問が `yourwish_kentei` の `validateQuestions`（配信前チェック）を通ることを確認
- [ ] 問題データ（約600問）の残り（法令の残り約170問・物理化学170問・性質消火の残り約160問）: **未着手**。法令は収集済みの条文原文をほぼ使い切ったため、残りには追加の一次資料収集が必要。性質消火も同様。物理化学は条文のような一次資料が無い分野のため、中学・高校理科の標準知識に基づき独自に作成する方針（第一弾で着手済み）。詳細は下記「一次資料アクセスの制約」を参照
- [ ] Flutter プロジェクトの雛形（`flutter create` で生成する android/ios/web 等）: **未生成**。このクラウド実行環境に Flutter/Dart SDK が入っておらず、`flutter create`・`flutter pub get`・`dart analyze` の実行確認ができないため。ローカル（Windows実機。日本語パス回避）で `flutter create .` 相当を行い、本リポジトリの `pubspec.yaml`・`lib/`・`assets/` をマージすることを想定
- [x] lib/（基本学習フローのみ）: ホーム（試験概要）・学ぶ（一問一答。`PracticeSession`）・模擬試験（`scoreMockExam`）・記録（`ProgressSnapshot` による暫定の解答数・正答率・連続学習日数の表示。`lib/views/record_view.dart`）・設定（免責文言）を実装。`UkalabShell`・`QuestionCard`・`ChoiceTile`・`ExplanationPanel`・`ResultSummary`・`EmptyState`・`ErrorState`（app_common_kit）を使用。**このクラウド環境に Flutter/Dart SDK が無く `flutter pub get`・`dart analyze`・実機確認を一度も行っていない。** ローカル環境で確認してから取り込むこと
- [x] 画期的な機能B「温度の実験室」（`lib/views/temperature_lab_view.dart`）: 気温スライダーで引火点を超えた物質が強調表示される。代表6物質（ガソリン・灯油・軽油・エタノール・ジエチルエーテル・二硫化炭素）の引火点・比重・水溶性・指定数量（`lib/data/substance.dart`）。学ぶタブの空状態から遷移。この機能は学習体験の「型」を使わず独立実装なので、`yourwish_kentei` 側の型実装を待たずに着手できた
- [x] 画期的な機能C「貯蔵所パズル」（`lib/views/storage_puzzle_view.dart`）: 複数物質の貯蔵量から指定数量の倍数の合計（商の和）を計算し、1以上（指定数量以上＝許可が必要）かを判定するクイズ形式。`lib/data/storage_puzzle.dart` で2〜3種類の物質と量を自動生成。根拠は消防法第10条（商の和が1以上で指定数量以上とみなす）。物質の追加・削除・量の調整（±10L）ができ、「もし減らしたら／もう1種類加えたら」を試しながら回答できる。企画書にある容器のドラッグ&ドロップ操作そのものは未実装（後続の改善に回す）
- [x] 画期的な機能D「消火マッチング」（`lib/views/extinguisher_match_view.dart`）: 物質（水溶性かどうか）と消火剤5種（水・一般泡・耐アルコール泡・粉末・二酸化炭素）の組み合わせが有効か不適かを答えるクイズ形式。`lib/data/extinguisher.dart` に判定ロジックと理由文を集約。二酸化炭素は、政令別表第五（第20条関係）の原文で第四類への適応が確認できたため追加（2026-10-04）。企画書にある「線で結ぶ」操作に近づけ、カードをドラッグ＆ドロップで「有効」「不適」の枠に振り分ける形に改善済み（配置し直しも可能）
- [x] 画期的な機能A「違反探しモード」（`lib/views/violation_hunt_view.dart`）: 4つの行動のうち、法令・消火の知識に違反しているものを1つ見つけるクイズ形式。新たな未確認データは追加せず、既に確認済みの `extinguisher.dart`（消火剤の適否）・`substance.dart`（指定数量）のロジックのみを組み合わせて `lib/data/violation.dart` で生成
- [x] 画期的な機能E「現場の1日」（`lib/views/field_day_view.dart`）: 1日の勤務を模した4つの場面（08:00/11:00/14:00/17:00）で、温度（引火点）・指定数量・消火剤の判断を順番に答える。新たな未確認データは追加せず、既存の3つのロジック（`substance.dart`・`extinguisher.dart`・指定数量の考え方）を場面として組み合わせた `lib/data/field_day.dart` で生成
- [x] 推し（MascotWidget）・学習コイン（`lib/widgets/oshi_card.dart`・`lib/main.dart`）: app_common_kit v0.4.0 の `MascotWidget`・`CoinService`・`OutfitService`・`WardrobeScreen`・`showPassReportDialog` を導入（`kanken`・`bike` の `oshi_card.dart` を手本にした）。ホーム画面に推しカードを表示し、着替え・ショップ・合格報告ができる。表示設定（通常／小さく／非表示）は `SharedPreferences` で端末内に永続化する。

  **問題データが無い間の暫定措置**: `lib/views/home_view.dart` には元々「推し・コインの実装は問題データ投入後」という方針のTODOがあったが、ユーザー判断（2026-10-03）により、問題データが無い今の段階でも画期的な機能A〜E・一問一答の解答数を暫定の進捗指標として使い、先行して統合した（`lib/data/progress_store.dart` の `ProgressSnapshot`。網羅率は「100問相当で頭打ち」とする暫定の目安、正答率は解答に対する正解率）。問題データが入ったら、`yourwish_kentei` の `Question` の網羅率・正答率に基づく正式な計算に差し替えること。コインは、A〜Eの演習の正解時に `CoinEvent.reviewCorrected`（本来は「間隔を空けた復習」用の枠だが、固定の問題IDが無いA〜Eでは代わりにこの枠を再利用する製品判断。1日20問・2コインまで）、模擬試験の実施・合格時に `CoinEvent.mockDone`/`mockPass` を付与する。課金・広告視聴での付与は実装していない（仕様どおり）。
- [x] 苦手問題の復習リスト（`lib/data/srs_store.dart`・`lib/views/weak_review_view.dart`）: 一問一答・模擬試験で間違えた問題を `yourwish_kentei` の間隔反復エンジン（`Srs`・`SrsItem`。Leitner方式、正解で箱が上がり復習間隔が延び、不正解で箱0に戻る）で管理し、復習時期が来た問題だけを学ぶタブの入り口（「苦手問題の復習（N問）」カード）から `PracticeSession`（`mode: PracticeMode.weak`）で優先出題する。問題データに依存するだけで新たな一次資料は不要なため、このクラウド環境でも着手できた。一問一答・模擬試験の演習UI（選択肢・解説の表示）は `lib/views/practice_session_view.dart` に共通化し、両方の画面で再利用している。記録タブ（`lib/views/record_view.dart`）にも「苦手問題の復習」カードを追加し、記録中・復習待ち・定着済みの問題数と、復習待ちがあれば「復習する」ボタンを表示する。学ぶタブの一問一答には分野別フィルタ（`ExamConfig.subjects` の並び順で、問題データがある分野だけ表示）を追加し、「法令」「性質消火」などで絞り込める。
- [x] 模擬試験の結果履歴（`lib/data/mock_history_store.dart`）: 模擬試験を終えるたびに日時・得点・満点・合否を端末内（`SharedPreferences`）に保存する（直近50件まで。超えたら古いものから捨てる）。記録タブに「模擬試験の結果」カードを追加し、直近5件を新しい順に、合否アイコン・得点率バー・点数で表示する。模試のみを受けた（一問一答等の演習をまだしていない）場合でも記録タブが空状態にならないよう、記録タブの空表示の判定に履歴の有無も含めた。
- [x] ブックマーク（`lib/data/bookmark_store.dart`・`lib/views/bookmark_list_view.dart`）: 一問一答の問題カードにしおりアイコンを追加し、気になる問題を端末内（`SharedPreferences`）にqid単位で記録できる。学ぶタブの入り口に「ブックマーク（N問）」カードを追加し、ブックマークした問題だけをまとめて `PracticeSession`（通常モード）で見返せる。苦手問題の復習（間違えた問題の間隔反復）とは独立した仕組みで、正誤に関係なく任意に印をつけられる。
- [x] 分野別の正答率（`lib/data/subject_stats_store.dart`）: 一問一答・模擬試験で1問答えるたびに、その問題の `subjectId` 単位で解答数・正解数を端末内（`SharedPreferences`）に積み上げる。記録タブに「分野別の正答率」カードを追加し、`ExamConfig.subjects` の並び順で、データがある分野だけ正答率バーを表示する（`ExamRepository` を `examConfigProvider`（`FutureProvider`）として公開し記録タブから参照）。
- [x] 模試の振り返り（`lib/views/mock_review_view.dart`）: 模擬試験の結果画面に、間違えた問題があれば「間違えた問題を振り返る（N問）」ボタンを表示し、その問題だけを一覧で選択肢（正解・選んだ回答）と解説つきで見返せる `MockReviewView` に遷移する。採点時に `_wrongQuestions`（間違えた問題）と選んだ回答（`_answers`）を保持しておき、画面に渡すだけの実装で、新たなデータ保存は増やしていない。
- [x] デイリーミッション（`lib/data/daily_goal_store.dart`）: 設定タブで1日の目標問題数（10／20／30問・オフ）を選べる。一問一答・模擬試験で1問答えるたびに今日の解答数を端末内（`SharedPreferences`）に積み上げ、日付が変わると自動でリセットする。学ぶタブの先頭に目標がある場合だけ「今日のデイリーミッション」カードを表示し、進捗バーと、達成したら祝福表示に切り替える。
- [x] 模試の残り時間タイマー（`lib/views/mock_exam_view.dart`）: `LevelConfig.timeLimitSec`（2時間）をもとに、開始時から1秒ごとにカウントダウンする残り時間を問題画面の右上に表示する（残り60秒以下は警告色）。0になると自動的に採点を確定する（最後の問題に答えて採点するときと同じ `_finish()` を共有）。
- [x] 模試結果の科目別内訳表示（`lib/views/mock_exam_view.dart`）: 結果画面に、`scoreMockExam` が返す `bySubject`（科目ごとの得点・満点）・`subjectShortfalls`（足切り未達の科目）をもとに「科目別の結果」カードを追加し、`ExamConfig.subjects` の並び順で科目名・得点・得点率を表示する。足切りに届いていない科目は警告アイコンと赤字で強調する。
- [x] 連続学習日数のマイルストーン（`lib/views/record_view.dart` の `latestStreakMilestone`）: 連続学習日数が3／7／14／30／60／100／200／365日の節目に達すると、記録タブの「これまでの演習」カードに「N日連続達成！」の祝福表示を追加する。
- [x] 用語集・暗記カード（`lib/data/glossary.dart`・`lib/views/glossary_card_view.dart`）: 引火点・指定数量・商の和等、既存の確認済みデータ（`substance.dart`・`extinguisher.dart`・問題データの解説文）に基づく頻出用語13語の定義をカード形式で表示する。タップで用語⇔定義を切り替え、「前へ」「次へ」で移動する。新たな一次資料の収集は行っていない。問題データの有無にかかわらず常に学ぶタブの入り口から利用できる。
- [x] ダークモード設定（`lib/data/theme_store.dart`）: 設定タブで「端末に合わせる」「ライト」「ダーク」を選べる。選択は端末内（`SharedPreferences`）に保存し、`Otsu4App`（`lib/app.dart`）の `MaterialApp.themeMode` に反映する。
- [x] 集中特訓・苦手分野の優先出題（`lib/data/subject_stats_store.dart` の `weakSubjectIds`・`lib/views/focus_training_view.dart`）: 分野別の正答率（解答数5問以上・正答率60%未満）から「苦手分野」を判定し、その分野の問題だけをまとめて演習できる `FocusTrainingView` を追加。学ぶタブの入り口に「集中特訓（N問）」カードを表示する。
- [x] 実績バッジ一覧（`lib/data/achievements.dart`・`lib/views/achievements_view.dart`）: 連続学習日数（3〜365日の節目）・解答数（50〜500問の節目）・模試合格・分野マスター（いずれかの分野で10問以上解答・正答率90%以上）の達成状況をバッジ一覧で確認できる。記録タブの先頭に「実績（達成数/全体数）」の入り口カードを追加。
- [x] 弱点マップ（`lib/views/record_view.dart` の `sortedByWeakness`）: 分野別の正答率を、正答率が低い分野から順に横棒グラフで並べて表示する（2分野以上データがあるときのみ表示）。既存の「分野別の正答率」カード（試験の並び順）とは別に、学習の全体像を一目で把握できるようにする。
- [x] テスト（`test/`）: 画期的な機能A〜E・貯蔵所パズルの判定ロジック（`substance`・`extinguisher`・`storage_puzzle`・`violation`・`field_day`）、推し・コインの暫定進捗（`progress_store` の `ProgressSnapshot`・`ProgressService`）、苦手問題の復習（`srs_store_test.dart`。`yourwish_kentei` の `Srs` の間隔反復を通じて `dueQids` が正しく変化することを確認）、模擬試験の結果履歴（`mock_history_store_test.dart`。追加・上限件数での切り捨て・保存と再読み込みでの復元を確認）、ブックマーク（`bookmark_store_test.dart`。追加・解除・複数問題の独立性・保存と再読み込みでの復元を確認）、分野別の正答率（`subject_stats_store_test.dart`。分野ごとの積み上げ・独立性・保存と再読み込みでの復元を確認）、デイリーミッション（`daily_goal_store_test.dart`。目標設定・解答の積み上げ・日付変更でのリセット・保存と再読み込みでの復元を確認）、連続学習日数のマイルストーン（`streak_milestone_test.dart`。節目未達・ちょうど到達・節目の間・最大の節目超えを確認）、テーマ設定（`theme_store_test.dart`。初期状態・設定・保存と再読み込みでの復元を確認）、集中特訓の苦手分野判定（`weak_subject_test.dart`。解答数不足・正答率による判定を確認）、問題データ（`question_data_test.dart`。`yourwish_kentei` の `validateQuestions` を通ることを確認）の単体テストを追加。**このクラウド環境に Flutter/Dart SDK が無く `flutter test` を一度も実行していない。** ローカル環境で実行して確認すること
- [ ] `yourwish_kentei` の学習体験の「型」（決定76の9種。乙4で使うのは⑤〜⑨）: まだ無く、G検定セッションでの型①〜④の実装もまだリポジトリ上には見当たらない（2026-10-03時点）。型の実装状況を確認してから着手する

## 一次資料アクセスの制約（2026-10-04 解消）

**このクラウド実行環境のネットワーク出口ポリシーは、今も `laws.e-gov.go.jp` や `www.shoubo-shiken.or.jp` への直接アクセスを拒否する**（WebFetch が `EGRESS_BLOCKED`）。これ自体は変わっていない。

ただし、ユーザーが別環境（ローカル・別セッション）で以下を収集し、Google Drive（`乙4_一次資料_2026-10-04` フォルダ）経由でこのセッションに渡してくれたことで、一次資料ベースの問題データ作成が可能になった（`mcp__Google_Drive__*` でフォルダを直接読み込み）。

- **条文原文**: e-Gov法令検索 API v1 から取得した消防法・危険物の規制に関する政令・危険物の規制に関する規則のXML（必要条文のみテキスト化）。乙4試験範囲に関わる条文（指定数量・商の和・別表第一・別表第三・別表第五・免状・保安講習・貯蔵取扱いの基準・運搬基準 等）を収録
- **消防試験研究センターの試験情報**: 試験時間（乙種2時間。`subject.html` の「1時間30分」は火薬類免状保持者の一部免除時間であり通常の乙種ではないことを確認）・合格基準（科目ごと60%以上）。**過去問PDFは著作権により複製・転用不可のため取得・利用していない**（学校配布・個人学習目的のプリントアウトのみ許可）
- **物性データ**: ENEOS灯油・軽油SDS（改定2024-02-01）、厚生労働省「職場のあんぜんサイト」モデルSDS等から発火点を確認

これにより `assets/questions/law.jsonl`（法令20問）を一次資料ベースで作成した。物理化学・性質消火の問題データと、法令の残り分は今後の課題。

**物性データ（`lib/data/substance.dart`）について**: 灯油・軽油の発火点（約240℃）はENEOS製品SDS、エタノールの発火点（363℃）は厚生労働省モデルSDS（出典ICSC）を原文で確認し採用した。エタノールは出典により363〜423℃の差があるため、値を1つ（厚労省）に固定している。製品銘柄により値が異なる可能性があり、他社製品は未検証。

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
