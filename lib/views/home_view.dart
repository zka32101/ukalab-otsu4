import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/exam_repository.dart';
import '../widgets/oshi_card.dart';

/// ホーム。試験の概要と、学ぶ・模擬への導線。
///
/// 推し（MascotWidget）・コイン残高は `OshiCard` で表示。正式な出題範囲の
/// 網羅率・正答率はまだ無い（問題データ未着手）ため、暫定の進捗指標を使う
/// （`lib/data/progress_store.dart`・README参照）。
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final _repo = const ExamRepository();
  ExamConfig? _exam;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final exam = await _repo.load();
      if (!mounted) return;
      setState(() => _exam = exam);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorState(onRetry: () {
        setState(() => _error = null);
        _load();
      });
    }
    final exam = _exam;
    if (exam == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final level = exam.levels.first;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const OshiCard(),
        const SizedBox(height: 16),
        Text(exam.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '全${level.questionCount}問・${(level.timeLimitSec ?? 0) ~/ 60}分・科目別${level.passRule.subjectMinPct?.round() ?? level.passRule.totalPct.round()}%以上で合格',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('出題科目', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final s in exam.subjects)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('・${s.name}'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
