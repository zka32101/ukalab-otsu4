import 'package:ukalab_core/ukalab_core.dart';

/// 科目ごとの目安配分時間（秒）。[subjectQuestionCounts] の問題数比率で
/// [totalTimeSec] を配分する。
Map<String, int> subjectPaceBudgetSec({
  required Map<String, int> subjectQuestionCounts,
  required int totalTimeSec,
}) {
  final totalQuestions = subjectQuestionCounts.values.fold<int>(0, (a, b) => a + b);
  if (totalQuestions == 0) return {};
  return {
    for (final e in subjectQuestionCounts.entries)
      e.key: (totalTimeSec * e.value / totalQuestions).round(),
  };
}

/// [picked]（科目ごとにまとまった出題順。`pickMockExamQuestions` の出力）の
/// うち、[index] 問目（0始まり）を解き終えるまでに使うべき目安累計時間（秒）。
int cumulativeBudgetSecAt({
  required List<Question> picked,
  required int index,
  required Map<String, int> subjectQuestionCounts,
  required Map<String, int> subjectBudgetSec,
}) {
  double total = 0;
  for (var i = 0; i <= index && i < picked.length; i++) {
    final subjectId = picked[i].subjectId;
    final count = subjectQuestionCounts[subjectId] ?? 0;
    if (count == 0) continue;
    total += (subjectBudgetSec[subjectId] ?? 0) / count;
  }
  return total.round();
}

/// 経過時間が目安の累計時間を超えていれば、ペースが遅れているとみなす。
bool isBehindPace({required int elapsedSec, required int cumulativeBudgetSec}) =>
    elapsedSec > cumulativeBudgetSec;

/// [picked] のうち [subjectId] に属する問題で、[uptoIndex]（0始まり、含む）
/// までに登場した件数。模試画面上部の科目別ペース表示で、今どの科目の
/// 何問目あたりかを示すために使う。
int subjectProgressCount({
  required List<Question> picked,
  required int uptoIndex,
  required String subjectId,
}) {
  var n = 0;
  for (var i = 0; i <= uptoIndex && i < picked.length; i++) {
    if (picked[i].subjectId == subjectId) n++;
  }
  return n;
}
