import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otsu4/data/data_parts.dart';
import 'package:otsu4/data/progress_store.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  group('upgradeLegacyBackupText', () {
    test('旧形式（項目がトップレベル）を共通形式の parts の下に移す', () {
      final legacy = jsonEncode({
        'version': 1,
        'exportedAt': '2026-10-06T00:00:00.000',
        'bestCombo': 8,
        'mockWrong': ['q3'],
      });
      final upgraded = jsonDecode(upgradeLegacyBackupText(legacy)) as Map<String, dynamic>;
      expect(upgraded['version'], 1);
      expect(upgraded['parts'], {
        'bestCombo': 8,
        'mockWrong': ['q3'],
      });
      expect(upgraded.containsKey('bestCombo'), isFalse);
    });

    test('すでに共通形式ならそのまま返す', () {
      const text = '{"version":1,"parts":{"bestCombo":3}}';
      expect(upgradeLegacyBackupText(text), text);
    });
  });

  test('otsu4DataParts のidは重複せず、旧バックアップのキーと同じ', () {
    final ids = [for (final p in otsu4DataParts) p.id];
    expect(ids.toSet().length, ids.length);
    expect(
      ids,
      containsAll([
        'progress',
        'srs',
        'mockHistory',
        'mockWrong',
        'dailyGoal',
        'dailyGoalHistory',
        'subjectStats',
        'subjectStatsHistory',
        'answeredQuestions',
        'questionMemo',
        'recentGlossaryTerms',
        'bestCombo',
        'dailyAnswerStats',
        'glossaryMastered',
      ]),
    );
  });

  testWidgets('書き出して、リセット後に読み込むと、進捗が元に戻る', (tester) async {
    late WidgetRef ref;
    SharedPreferences.setMockInitialValues({});
    final progressService = ProgressService();
    await tester.runAsync(progressService.load);
    await tester.pumpWidget(ProviderScope(
      overrides: [progressServiceProvider.overrideWithValue(progressService)],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(builder: (context, r, _) {
            ref = r;
            return const SizedBox();
          }),
        ),
      ),
    ));
    await tester.runAsync(() async {
      await ref.read(progressProvider.notifier).restore(
            ProgressSnapshot(answered: 10, correct: 7, streakDays: 3, lastStudyDate: DateTime(2026, 10, 6)),
          );
      final text = exportLearningDataJson(ref);
      await ref.read(progressProvider.notifier).reset();
      expect(ref.read(progressProvider).answered, 0);

      await importLearningDataJson(ref, text);
      expect(ref.read(progressProvider).answered, 10);
      expect(ref.read(progressProvider).correct, 7);
    });
  });
}
