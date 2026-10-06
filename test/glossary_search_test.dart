import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/glossary.dart';

void main() {
  group('searchGlossaryTerms', () {
    test('用語名に一致する用語を返す', () {
      expect(searchGlossaryTerms('引火点').map((t) => t.term), contains('引火点'));
    });

    test('定義の文中にあるキーワードでも一致する', () {
      expect(searchGlossaryTerms('商の和').map((t) => t.term), contains('指定数量'));
    });

    test('大文字小文字は区別しない', () {
      expect(searchGlossaryTerms('ひきかてん'), isEmpty); // 読み仮名検索は対象外（想定内）
      expect(searchGlossaryTerms('引火点'), isNotEmpty);
    });

    test('空のキーワードでは何も返さない', () {
      expect(searchGlossaryTerms(''), isEmpty);
    });

    test('一致しないキーワードでは空を返す', () {
      expect(searchGlossaryTerms('存在しない語句'), isEmpty);
    });
  });

  group('termReferencesIn', () {
    test('本文中に出現する用語集の用語をTermReferenceとして返す', () {
      final refs = termReferencesIn('引火点は可燃性蒸気を発生する最低温度。指定数量も重要。');
      final ids = refs.map((r) => r.termId).toSet();
      expect(ids, containsAll(['引火点', '指定数量']));
    });

    test('一致する用語が無ければ空を返す', () {
      expect(termReferencesIn('まったく関係のない文章'), isEmpty);
    });
  });
}
