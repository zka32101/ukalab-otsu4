import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

/// 試験定義（ExamConfig）の読み込み。
class ExamRepository {
  const ExamRepository();

  static const assetPath = 'assets/exam/hazmat4_exam.json';

  Future<ExamConfig> load() async {
    final text = await rootBundle.loadString(assetPath);
    return ExamConfig.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }
}
