import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/question_memo_store.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

Question _q({required String qid, String prompt = '問題文'}) => Question(
      qid: qid,
      examId: 'hazmat4',
      subjectId: 'law',
      topicId: 'topic',
      prompt: prompt,
      explanation: '解説文',
      source: QuestionSource.original,
      sourceRef: 'test',
      contentVer: '2026.10.0',
    );

void main() {
  group('filterMemoedQuestions', () {
    final pool = [
      _q(qid: 'q1', prompt: '引火点とは何か'),
      _q(qid: 'q2', prompt: '指定数量の倍数'),
      _q(qid: 'q3', prompt: 'メモの無い問題'),
    ];

    test('メモが書かれている問題だけを返す（空キーワード）', () {
      final memos = {'q1': '覚え方メモ', 'q2': '商の和メモ'};
      final result = filterMemoedQuestions(pool, memos, '');
      expect(result.map((q) => q.qid), ['q1', 'q2']);
    });

    test('キーワードが問題文に含まれるものだけに絞り込む', () {
      final memos = {'q1': '覚え方メモ', 'q2': '商の和メモ'};
      final result = filterMemoedQuestions(pool, memos, '引火点');
      expect(result.map((q) => q.qid), ['q1']);
    });

    test('キーワードがメモ本文に含まれるものだけに絞り込む', () {
      final memos = {'q1': '覚え方メモ', 'q2': '商の和メモ'};
      final result = filterMemoedQuestions(pool, memos, '商の和');
      expect(result.map((q) => q.qid), ['q2']);
    });

    test('メモが無い問題は含まれない', () {
      final memos = {'q1': '覚え方メモ'};
      final result = filterMemoedQuestions(pool, memos, '');
      expect(result.map((q) => q.qid), ['q1']);
    });

    test('メモが1件も無ければ空を返す', () {
      expect(filterMemoedQuestions(pool, {}, ''), isEmpty);
    });
  });

  group('QuestionMemoService.setMemo', () {
    test('メモを保存できる', () async {
      final service = QuestionMemoService(store: _FakeStore());
      await service.setMemo(qid: 'q1', memo: '覚え方：ゴロ合わせ');
      expect(service.memos['q1'], '覚え方：ゴロ合わせ');
    });

    test('前後の空白はトリムされる', () async {
      final service = QuestionMemoService(store: _FakeStore());
      await service.setMemo(qid: 'q1', memo: '  メモ本文  ');
      expect(service.memos['q1'], 'メモ本文');
    });

    test('空文字（トリム後）を保存するとメモが削除される', () async {
      final service = QuestionMemoService(store: _FakeStore());
      await service.setMemo(qid: 'q1', memo: 'メモ本文');
      await service.setMemo(qid: 'q1', memo: '   ');
      expect(service.memos.containsKey('q1'), isFalse);
    });

    test('複数の問題のメモを独立して保存できる', () async {
      final service = QuestionMemoService(store: _FakeStore());
      await service.setMemo(qid: 'q1', memo: 'メモ1');
      await service.setMemo(qid: 'q2', memo: 'メモ2');
      expect(service.memos['q1'], 'メモ1');
      expect(service.memos['q2'], 'メモ2');
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = QuestionMemoService(store: store);
      await service.setMemo(qid: 'q1', memo: 'メモ本文');

      final reloaded = QuestionMemoService(store: store);
      await reloaded.load();
      expect(reloaded.memos['q1'], 'メモ本文');
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements QuestionMemoStore {
  Map<String, String> _saved = {};

  @override
  Future<Map<String, String>> read() async => _saved;

  @override
  Future<void> write(Map<String, String> memos) async => _saved = memos;
}
