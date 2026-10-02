import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

/// 問題データ（JSON Lines）の読み込み。
///
/// TODO(問題データ未投入): `assets/questions/` には現時点で科目別の
/// jsonl がまだ無い（一次資料確認の制約。README参照）。ファイルを追加したら
/// [assetPaths] に列挙し、`pubspec.yaml` の `flutter.assets` にも追加する。
class QuestionRepository {
  const QuestionRepository();

  static const assetPaths = <String>[
    // 'assets/questions/law.jsonl',
    // 'assets/questions/physics_chem.jsonl',
    // 'assets/questions/property_extinguish.jsonl',
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
