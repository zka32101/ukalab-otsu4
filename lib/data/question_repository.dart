import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:ukalab_core/ukalab_core.dart';

/// 問題データ（JSON Lines）の読み込み。README参照。
class QuestionRepository {
  const QuestionRepository();

  static const assetPaths = <String>[
    'assets/questions/law.jsonl',
    'assets/questions/property_extinguish.jsonl',
    'assets/questions/property_extinguish_1.jsonl',
    'assets/questions/physics_chem.jsonl',
  ];

  Future<List<Question>> load() async {
    final questions = <Question>[];
    for (final path in assetPaths) {
      final text = await rootBundle.loadString(path);
      for (final line in text.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('//')) continue;
        questions.add(Question.fromJson(jsonDecode(trimmed) as Map<String, dynamic>));
      }
    }
    return questions;
  }
}

/// [subjectId] が null ならそのまま返し、指定があればその分野だけに絞り込む。
List<Question> filterBySubject(List<Question> pool, String? subjectId) =>
    subjectId == null ? pool : [for (final q in pool) if (q.subjectId == subjectId) q];
