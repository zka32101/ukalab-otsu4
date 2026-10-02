import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import '../data/exam_repository.dart';

/// ホーム。試験の概要と、学ぶ・模擬への導線。
///
/// TODO: 推し（MascotWidget）・コイン残高・「今日の1問ずつ」の具体的な
/// 進捗表示は、問題データ投入後に追加する（共通デザイン仕様 §4b・推し仕様 v0.2）。
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
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
