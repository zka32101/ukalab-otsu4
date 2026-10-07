import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/oshi_lines.dart';
import '../data/progress_store.dart';

MascotStage _stageFor(ProgressSnapshot p) =>
    MasteryModel.standard.stageOf(MasteryInput(coverage: p.coverage, accuracy: p.accuracy));

/// ホームの「推し」カード。共通キットの [UkalabOshiCard] に、乙4の成長段階・連続日数を渡す。
/// 推しの選択・着替え・合格報告・表示切替はキット側。特別な状況が無いときのあいさつだけ、
/// 時間帯に応じたセリフ（`lib/data/oshi_lines.dart`）を使う。
///
/// 正式な出題範囲（`Question`）の網羅率・正答率はまだ無い（問題データ未着手）ため、
/// `ProgressSnapshot`（演習の解答数）を暫定の習得度として使う（README参照）。
/// 試験日の設定機能はまだ無いため、試験日連動の装い（`ExamPhase`）は常に none。
class OshiCard extends ConsumerWidget {
  const OshiCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = progress.lastStudyDate;
    final days = last == null ? null : today.difference(DateTime(last.year, last.month, last.day)).inDays;
    return UkalabOshiCard(
      cert: UkalabCert.hazmat4,
      stage: _stageFor(progress),
      appId: 'otsu4',
      streakDays: progress.streakDays,
      studiedToday: days == 0,
      daysSinceLastStudy: days,
      greeting: (now, seed) => pickTimeOfDayGreeting(now, seed: seed),
    );
  }
}
