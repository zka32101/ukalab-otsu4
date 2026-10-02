# うかラボ 危険物乙4

危険物取扱者乙種第4類の学習アプリ。「うかラボ」シリーズの第1陣4番目（決定66）。

本アプリは免責事項として、消防試験研究センター等の試験実施団体とは無関係の非公式アプリであることをアプリ内に明記する（未実装・TODO）。

## 位置づけ

```
このアプリ（ukalab-otsu4） → yourwish_kentei（検定エンジン、tag固定） → app_common_kit（共通基盤、tag固定）
```

このリポジトリが持つのは、試験定義（ExamConfig）・問題データ・テーマ（資格ID）・ストア設定のみ。共通の仕組みは `app_common_kit` / `yourwish_kentei` 側にあり、ここでは作り直さない。

- `app_common_kit`: `ref: v0.2.0`
- `yourwish_kentei`: `ref: v0.2.0`
- 資格ID: `UkalabCert.hazmat4`（app_common_kit に実装済み。テーマ色 ライト `#C23D16` / ダーク `#F0997F`）

## 現在の状態（2026-10-02）

- [x] pubspec.yaml（依存をタグ固定で追加）
- [x] ExamConfig（`assets/exam/hazmat4_exam.json`）: 法令15問・物理化学10問・性質消火10問の計35問、2時間、科目別60%以上で合格（消防試験研究センター 公式試験案内で確認済み）
- [ ] 問題データ（約600問。法令240／物理化学180／性質消火180、計算問題は自動生成併用）: **未着手**。理由は下記「一次資料アクセスの制約」を参照
- [ ] Flutter プロジェクトの雛形（`flutter create` で生成する android/ios/web 等）: **未生成**。このクラウド実行環境に Flutter/Dart SDK が入っておらず、`flutter create`・`flutter pub get`・`dart analyze` の実行確認ができないため。ローカル（Windows実機。日本語パス回避）で `flutter create .` 相当を行い、本リポジトリの `pubspec.yaml`・`assets/` をマージすることを想定
- [ ] lib/（画面・サービス）: 未着手。`yourwish_kentei` にはまだ UI 側の学習体験の「型」（決定76の9種）が無く、G検定セッションで型①〜④を先行実装中。乙4で使う型⑤〜⑨の実装状況を確認してから着手する
- [ ] 画期的な機能5件（違反探しモード・温度スライダー・貯蔵所パズル・消火マッチング・現場の1日モード）: 企画は確定済み（設計書参照）。実装は型の実装・問題データ整備後

## 一次資料アクセスの制約（重要）

バイク免許プロジェクトの教訓により、法令問題は e-Gov 法令検索などの一次資料で原文確認してから作成する方針だが、**このクラウド実行環境のネットワーク出口ポリシーが `laws.e-gov.go.jp` や `www.shoubo-shiken.or.jp` への直接アクセスを拒否する**（WebFetch が `EGRESS_BLOCKED`）。Web検索のスニペット経由では断片的な情報しか得られず、条文全文の確認はできない。

ユーザー判断（2026-10-02）により、今回は問題データ作成を見送り、基盤整備のみ先に進めた。次回以降、一次資料にアクセスできる別環境で作業するか、必要な条文（危険物の規制に関する政令 別表第三〈指定数量〉、危険物の規制に関する規則の各規定など）をユーザーから共有してもらった上で着手する。

## ExamConfig モデルの制約（共通基盤への申し送り）

`yourwish_kentei` の `LevelConfig` は模擬試験の出題数（`questionCount`）と合格基準（`passRule.totalPct` / `subjectMinPct`）のみを持ち、**科目別の出題数配分**（法令15問・物理化学10問・性質消火10問）を表現するフィールドが無い。乙4は科目ごとの配点が均等なため `totalPct: 60` と `subjectMinPct: 60` は数値上一致するが、模擬試験で科目ごとに決まった問題数を抽出する処理は、現状 `PracticeSession`/採点エンジン側に無い。問題データ整備時に `yourwish_kentei` 側の対応が必要か確認する。

## 手本にするアプリ

`zka32101/kanken`・`zka32101/bike` が app_common_kit 統合済みの手本。`bike` は `yourwish_kentei` も依存に持つ（ただし問題データは bike 独自形式で、`yourwish_kentei` の `Question`/`validate_content` 形式とは異なる点に注意）。

## 関連ドキュメント

設計書は Google Drive（`design/kentei-engine（うかラボ）`）。特に:
- `kentei_engine_現行サマリー_v1_0.md`（索引。矛盾があればこれが優先）
- `ukalab_共通基盤_各資格アプリ向けガイド_v0_2.md`
- `ukalab_危険物乙4_企画設計書_v0_1.md`・`ukalab_危険物乙4_競合調査_v1_0.md`
- `ukalab_共通デザイン仕様_v0_4.md`・`ukalab_マスコット仕様_v0_2.md`・`ukalab_推し_資格連動要素_v0_1.md`・`ukalab_学習コイン仕様_v0_1.md`
