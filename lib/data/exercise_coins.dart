import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress_store.dart';

int _coinKeySeq = 0;

/// 一問一答・画期的な機能A〜Eで1問答えたときに呼ぶ。推しの進捗を更新し、
/// 正解なら学習コインを付与する（`CoinEvent.reviewCorrected`。1日20問・2コインまで）。
///
/// これらの演習は毎回ランダム生成で、問題ごとの固定IDが無い。永続的に1回だけの
/// `CoinEvent.newQuestion` は使わず、他アプリの「復習」用の枠を再利用している
/// （製品判断。README参照）。
Future<void> recordExerciseAnswer(WidgetRef ref, {required bool correct}) async {
  await ref.read(progressProvider.notifier).recordAnswer(correct: correct);
  if (correct) {
    await ref.read(coinProvider.notifier).grant(CoinEvent.reviewCorrected('ex-${_coinKeySeq++}'));
  }
}
