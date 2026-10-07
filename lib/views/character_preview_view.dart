import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_store.dart';

MascotStage _stageFor(ProgressSnapshot p) =>
    MasteryModel.standard.stageOf(MasteryInput(coverage: p.coverage, accuracy: p.accuracy));

/// 推しの衣装プレビュー画面。ホームの推しカード（`app_common_kit` の
/// `UkalabOshiCard`）のメニュー「推しを選ぶ」は同じく `app_common_kit` の
/// `CharacterSelectScreen`（小さな顔アイコンのみ）に固定されており、乙4側
/// からは差し替えられない。学習ツール一覧のこの画面では、いま装備中の衣装を
/// 着た状態で5人のキャラクターを並べて比較でき、タップでそのまま選べる
/// （選択状態は共通の `selectedCharacterPackProvider` を使うため、ホームの
/// 推しカードにも反映される）。
class CharacterPreviewView extends ConsumerWidget {
  const CharacterPreviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedCharacterPackProvider);
    final progress = ref.watch(progressProvider);
    final stage = _stageFor(progress);
    final outfit = ref.watch(equippedOutfitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('推しを選ぶ')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
        children: [
          for (final pack in UkalabCharacters.all)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selected.id == pack.id ? theme.colorScheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => ref.read(selectedCharacterPackProvider.notifier).select(pack),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MascotWidget(
                        pack: pack,
                        stage: stage,
                        outfit: outfit,
                        size: 88,
                        animate: false,
                      ),
                      const SizedBox(height: 8),
                      Text(pack.isBuiltIn ? 'うか' : pack.name, style: theme.textTheme.titleSmall),
                      if (selected.id == pack.id) ...[
                        const SizedBox(height: 4),
                        Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
