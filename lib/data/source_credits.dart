import 'package:ukalab_core/ukalab_core.dart';

/// 法令問題（`source: statute`）で使われている出典条文の一覧。同じ条文が
/// 複数の問題で使われていれば重複を除き、出現順を保つ。設定タブの
/// 「問題データの出典」で表示する。
List<String> lawSourceReferences(List<Question> pool) {
  final seen = <String>{};
  final refs = <String>[];
  for (final q in pool) {
    if (q.subjectId != 'law' || q.source != QuestionSource.statute) continue;
    if (seen.add(q.sourceRef)) refs.add(q.sourceRef);
  }
  return refs;
}
