import 'package:flutter/material.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

import 'focus_training_view.dart';
import 'glossary_card_view.dart';
import 'mock_wrong_review_view.dart';
import 'question_search_view.dart';
import 'weak_review_view.dart';

/// 模試の結果画面から開く学習教材リンク集。間違えた分野（科目の足切り）が
/// あれば、その分野の集中特訓を先頭に出す。既存の学習ツール（苦手問題の
/// 復習・用語集・重要語句検索・前回の模試の間違い）への導線を、模試を終えた
/// 直後にまとめて一箇所から開けるようにする（新しいデータ保存は増やさない）。
class MockStudyLinksView extends StatelessWidget {
  const MockStudyLinksView({super.key, required this.exam, required this.shortfallSubjectIds});

  final ExamConfig exam;
  final List<String> shortfallSubjectIds;

  String _subjectName(String subjectId) => exam.subjects
      .firstWhere(
        (s) => s.subjectId == subjectId,
        orElse: () => SubjectConfig(subjectId: subjectId, name: subjectId, order: 0),
      )
      .name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学習教材リンク集')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (shortfallSubjectIds.isNotEmpty) ...[
            Text(
              '足切りに満たなかった分野を優先的に演習できます',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final subjectId in shortfallSubjectIds)
              _LinkTile(
                icon: Icons.fitness_center_outlined,
                title: '集中特訓（${_subjectName(subjectId)}）',
                description: 'この分野の問題だけをまとめて演習します',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FocusTrainingView(
                      subjectId: subjectId,
                      subjectName: _subjectName(subjectId),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
          _LinkTile(
            icon: Icons.replay_outlined,
            title: '前回の模試の間違い',
            description: '今回の模擬試験で間違えた問題をまとめて復習します',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MockWrongReviewView()),
            ),
          ),
          _LinkTile(
            icon: Icons.history_edu_outlined,
            title: '苦手問題の復習',
            description: '間違えた問題を、間隔をあけて優先的に出題します',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WeakReviewView()),
            ),
          ),
          _LinkTile(
            icon: Icons.menu_book_outlined,
            title: '用語集',
            description: '引火点・指定数量など、頻出用語を暗記カードで確認できます',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlossaryCardView()),
            ),
          ),
          _LinkTile(
            icon: Icons.search_outlined,
            title: '重要語句で探す',
            description: 'キーワードから、関連する用語集・問題をまとめて探せます',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuestionSearchView()),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
