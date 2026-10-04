import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

/// 問題データ（JSON Lines）の読み込み。
///
/// TODO(問題データ第一弾): `law.jsonl`（20問）・`property_extinguish.jsonl`
/// （12問）のみ一次資料（e-Gov法令検索API・SDS等）に基づき投入済み。
/// `physics_chem.jsonl` はまだ無い。README参照。
class QuestionRepository {
  const QuestionRepository();

  static const assetPaths = <String>[
    'assets/questions/law.jsonl',
    'assets/questions/property_extinguish.jsonl',
    // 'assets/questions/physics_chem.jsonl',
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
