import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

void main() {
  test('law.jsonl は配信前チェック（validateQuestions）を通る', () async {
    final exam = ExamConfig.fromJson(
      jsonDecode(await File('assets/exam/hazmat4_exam.json').readAsString())
          as Map<String, dynamic>,
    );
    final parsed = parseQuestionsJsonl(
      await File('assets/questions/law.jsonl').readAsString(),
    );
    expect(parsed.issues, isEmpty, reason: 'JSON Lines の構文・必須項目エラー');

    final issues = validateQuestions(parsed.questions, exam: exam);
    expect(issues, isEmpty, reason: issues.map((i) => i.toString()).join('\n'));

    expect(parsed.questions, isNotEmpty);
    expect(parsed.questions.every((q) => q.subjectId == 'law'), isTrue);
    expect(parsed.questions.every((q) => q.source == QuestionSource.statute), isTrue);

    final ids = parsed.questions.map((q) => q.qid).toSet();
    expect(ids.length, parsed.questions.length, reason: 'qidが重複している');
  });
}
