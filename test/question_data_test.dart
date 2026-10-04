import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/question_repository.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

void main() {
  test('投入済みの問題データ（assets/questions/）は配信前チェックを通る', () async {
    final exam = ExamConfig.fromJson(
      jsonDecode(await File('assets/exam/hazmat4_exam.json').readAsString())
          as Map<String, dynamic>,
    );

    final questions = <Question>[];
    for (final path in QuestionRepository.assetPaths) {
      final parsed = parseQuestionsJsonl(await File(path).readAsString());
      expect(parsed.issues, isEmpty, reason: '$path: JSON Lines の構文・必須項目エラー');
      questions.addAll(parsed.questions);
    }
    expect(questions, isNotEmpty);

    final issues = validateQuestions(questions, exam: exam);
    expect(issues, isEmpty, reason: issues.map((i) => i.toString()).join('\n'));

    final ids = questions.map((q) => q.qid).toSet();
    expect(ids.length, questions.length, reason: 'qidが複数ファイルをまたいで重複している');
  });
}
