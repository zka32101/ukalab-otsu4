import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/progress_store.dart';

const _kDisplayKey = 'ukalab_otsu4_oshi_display';

/// 今の状況に合うセリフの場面。責める表現は使わない（セリフ集側で検査済み）。
MascotSituation _situationFor(MascotDayState day, DateTime now) {
  switch (day.examPhase(now)) {
    case ExamPhase.today:
      return MascotSituation.examToday;
    case ExamPhase.eve:
      return MascotSituation.examEve;
    case ExamPhase.close:
      return MascotSituation.examClose;
    case ExamPhase.approaching:
      return MascotSituation.examApproaching;
    case ExamPhase.none:
      break;
  }
  if (day.isWelcomeBack) return MascotSituation.welcomeBack;
  if (day.streakDays >= 3) return MascotSituation.streak;
  if (day.studiedToday) return MascotSituation.studied;
  return MascotSituation.greeting;
}

MascotStage _stageFor(ProgressSnapshot p) =>
    MasteryModel.standard.stageOf(MasteryInput(coverage: p.coverage, accuracy: p.accuracy));

enum _OshiAction { wardrobe, passReport }

/// ホームの「推し」カード。画期的な機能A〜E・一問一答で学習が進むと成長し、
/// 状況に合ったひとことを話す。タップでひとことが変わる。
///
/// 正式な出題範囲（`Question`）の網羅率・正答率はまだ無い（問題データ未着手）ため、
/// `ProgressSnapshot`（演習の解答数）を暫定の習得度として使う（README参照）。
/// 試験日の設定機能はまだ無いため、試験日連動の装い（`ExamPhase`）は常に none。
class OshiCard extends ConsumerStatefulWidget {
  const OshiCard({super.key});

  @override
  ConsumerState<OshiCard> createState() => _OshiCardState();
}

class _OshiCardState extends ConsumerState<OshiCard> {
  int _seed = 0;
  MascotDisplay _display = MascotDisplay.normal;

  @override
  void initState() {
    super.initState();
    _loadDisplay();
  }

  Future<void> _loadDisplay() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kDisplayKey);
    final value = MascotDisplay.values.firstWhere(
      (d) => d.name == name,
      orElse: () => MascotDisplay.normal,
    );
    if (!mounted) return;
    setState(() => _display = value);
  }

  Future<void> _setDisplay(MascotDisplay value) async {
    setState(() => _display = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDisplayKey, value.name);
  }

  void _onMenu(Object value) {
    if (value is MascotDisplay) {
      _setDisplay(value);
      return;
    }
    final stage = _stageFor(ref.read(progressProvider));
    switch (value as _OshiAction) {
      case _OshiAction.wardrobe:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => WardrobeScreen(cert: UkalabCert.hazmat4, stage: stage),
        ));
      case _OshiAction.passReport:
        showPassReportDialog(context, ref, cert: UkalabCert.hazmat4, stage: stage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = ref.watch(progressProvider);
    final coin = ref.watch(coinProvider);
    final menu = PopupMenuButton<Object>(
      tooltip: '推しのメニュー',
      icon: const Icon(Icons.more_vert),
      onSelected: _onMenu,
      itemBuilder: (_) => const [
        PopupMenuItem(value: _OshiAction.wardrobe, child: Text('着替え・ショップ')),
        PopupMenuItem(value: _OshiAction.passReport, child: Text('試験の結果を報告')),
        PopupMenuDivider(),
        PopupMenuItem(value: MascotDisplay.normal, child: Text('通常')),
        PopupMenuItem(value: MascotDisplay.small, child: Text('小さく表示')),
        PopupMenuItem(value: MascotDisplay.hidden, child: Text('表示しない')),
      ],
    );

    if (_display == MascotDisplay.hidden) {
      return Card(
        child: ListTile(
          title: Text('学習コイン ${coin.balance}', style: theme.textTheme.labelLarge),
          subtitle: const Text('推しは非表示です'),
          trailing: menu,
        ),
      );
    }

    final now = DateTime.now();
    final studiedToday = progress.lastStudyDate != null &&
        DateTime(now.year, now.month, now.day).difference(progress.lastStudyDate!).inDays == 0;
    final day = MascotDayState(studiedToday: studiedToday, streakDays: progress.streakDays);
    final stage = _stageFor(progress);
    final line = MascotLines.gentle.pick(_situationFor(day, now), seed: _seed);
    final small = _display == MascotDisplay.small;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          children: [
            MascotWidget(
              stage: stage,
              outfit: ref.watch(equippedOutfitProvider),
              expression: day.expression,
              display: _display,
              size: small ? 56 : 88,
              line: small ? null : line,
              onTap: () => setState(() => _seed++),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('あなたの推し  Lv${stage.index + 1}', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    small ? line : '推しをタップすると、ひとこと話します',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text('学習コイン ${coin.balance}', style: theme.textTheme.labelMedium),
                ],
              ),
            ),
            menu,
          ],
        ),
      ),
    );
  }
}
