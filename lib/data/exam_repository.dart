import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

/// 試験定義（ExamConfig）の読み込み。
class ExamRepository {
  const ExamRepository();

  static const assetPath = 'assets/exam/hazmat4_exam.json';

  Future<ExamConfig> load() async {
    final text = await rootBundle.loadString(assetPath);
    return ExamConfig.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }
}

/// 分野名の表示（記録タブの科目別正答率など）に使う。
final examConfigProvider = FutureProvider<ExamConfig>((ref) => const ExamRepository().load());
