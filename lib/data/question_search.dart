import 'package:yourwish_kentei/yourwish_kentei.dart';

/// [keyword] が問題文・解説・選択肢のいずれかに含まれる問題を返す
/// （大文字小文字は区別しない）。空のキーワードでは何も返さない。
List<Question> searchQuestions(List<Question> pool, String keyword) {
  final kw = keyword.trim().toLowerCase();
  if (kw.isEmpty) return [];
  return [
    for (final q in pool)
      if (q.prompt.toLowerCase().contains(kw) ||
          q.explanation.toLowerCase().contains(kw) ||
          q.choices.any((c) => c.toLowerCase().contains(kw)))
        q,
  ];
}
