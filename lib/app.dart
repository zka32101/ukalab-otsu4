import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/achievement_unlock_store.dart';
import 'data/achievements.dart';
import 'data/achievements_provider.dart';
import 'data/theme_store.dart';
import 'views/home_view.dart';
import 'views/mock_exam_view.dart';
import 'views/record_view.dart';
import 'views/settings_view.dart';
import 'views/study_view.dart';

/// 実績バッジの解除通知のスナックバーを、どの画面にいても表示するためのキー。
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class Otsu4App extends ConsumerWidget {
  const Otsu4App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    ref.listen<List<Achievement>>(achievementsProvider, (previous, next) {
      final unlockedIds = {for (final a in next) if (a.unlocked) a.id};
      final newlyUnlockedIds = ref
          .read(achievementUnlockProvider.notifier)
          .checkNewlyUnlocked(unlockedIds, DateTime.now());
      if (newlyUnlockedIds.isEmpty) return;
      for (final a in next) {
        if (!newlyUnlockedIds.contains(a.id)) continue;
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(a.icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('実績解除: ${a.title}')),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
    return MaterialApp(
      title: 'うかラボ 危険物乙4',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: UkalabTheme.light(field: UkalabField.tech, cert: UkalabCert.hazmat4),
      darkTheme: UkalabTheme.dark(field: UkalabField.tech, cert: UkalabCert.hazmat4),
      themeMode: themeMode,
      home: UkalabShell(
        pages: [
          HomeView(),
          StudyView(),
          MockExamView(),
          RecordView(),
          SettingsView(),
        ],
      ),
    );
  }
}
