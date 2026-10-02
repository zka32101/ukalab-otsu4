import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';

/// 学習記録。TODO: 演習・模擬試験の結果保存（端末内・共通アカウント同期）は未実装。
class RecordView extends StatelessWidget {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      message: '学習記録はまだありません。',
      icon: Icons.insights_outlined,
    );
  }
}
