import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/recent_glossary_terms_store.dart';

void main() {
  group('recordRecentGlossaryTerm', () {
    test('新しい用語を先頭に積む', () {
      final result = recordRecentGlossaryTerm(['引火点', '発火点'], '比重');
      expect(result, ['比重', '引火点', '発火点']);
    });

    test('既存の用語を見ると、先頭に移動する（重複しない）', () {
      final result = recordRecentGlossaryTerm(['引火点', '発火点', '比重'], '発火点');
      expect(result, ['発火点', '引火点', '比重']);
    });

    test('上限件数を超えると古いものから切り詰める', () {
      final current = [for (var i = 0; i < maxRecentGlossaryTerms; i++) '用語$i'];
      final result = recordRecentGlossaryTerm(current, '新しい用語');
      expect(result.length, maxRecentGlossaryTerms);
      expect(result.first, '新しい用語');
      expect(result.contains('用語${maxRecentGlossaryTerms - 1}'), isFalse);
    });
  });

  group('RecentGlossaryTermsService', () {
    test('初期状態は空', () async {
      final service = RecentGlossaryTermsService(store: _FakeStore());
      expect(service.terms, isEmpty);
    });

    test('記録した用語が先頭に入る', () async {
      final service = RecentGlossaryTermsService(store: _FakeStore());
      await service.record('引火点');
      await service.record('比重');
      expect(service.terms, ['比重', '引火点']);
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = RecentGlossaryTermsService(store: store);
      await service.record('引火点');

      final reloaded = RecentGlossaryTermsService(store: store);
      await reloaded.load();
      expect(reloaded.terms, ['引火点']);
    });

    test('resetで記録が空になる', () async {
      final service = RecentGlossaryTermsService(store: _FakeStore());
      await service.record('引火点');
      await service.reset();
      expect(service.terms, isEmpty);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements RecentGlossaryTermsStore {
  List<String> _saved = [];

  @override
  Future<List<String>> read() async => _saved;

  @override
  Future<void> write(List<String> terms) async => _saved = terms;
}
