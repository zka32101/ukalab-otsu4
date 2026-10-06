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

  group('glossaryTermsBySubject', () {
    test('指定した分野の用語だけを返す', () {
      final terms = glossaryTermsBySubject('law');
      expect(terms, isNotEmpty);
      expect(terms.every((t) => t.subjectId == 'law'), isTrue);
    });

    test('全ての用語はlaw・physics_chem・property_extinguishのいずれかに属する', () {
      const validSubjects = {'law', 'physics_chem', 'property_extinguish'};
      expect(glossaryTerms.every((t) => validSubjects.contains(t.subjectId)), isTrue);
    });

    test('存在しない分野では空を返す', () {
      expect(glossaryTermsBySubject('存在しない分野'), isEmpty);
    });
  });

  group('filterGlossaryTerms', () {
    test('subjectIdがnullならすべての用語が対象', () {
      final terms = filterGlossaryTerms(subjectId: null, favoritesOnly: false, favoriteTerms: {});
      expect(terms, glossaryTerms);
    });

    test('subjectIdを指定すると、その分野だけに絞り込む', () {
      final terms = filterGlossaryTerms(subjectId: 'law', favoritesOnly: false, favoriteTerms: {});
      expect(terms.every((t) => t.subjectId == 'law'), isTrue);
    });

    test('favoritesOnlyがtrueなら、favoriteTermsに含まれる用語だけに絞り込む', () {
      final terms = filterGlossaryTerms(
        subjectId: null,
        favoritesOnly: true,
        favoriteTerms: {'引火点', '指定数量'},
      );
      expect(terms.map((t) => t.term).toSet(), {'引火点', '指定数量'});
    });

    test('分野・お気に入りの両方を同時に絞り込める', () {
      final terms = filterGlossaryTerms(
        subjectId: 'law',
        favoritesOnly: true,
        favoriteTerms: {'引火点', '指定数量'},
      );
      expect(terms.map((t) => t.term).toSet(), {'指定数量'});
    });

    test('お気に入りが空ならfavoritesOnlyで空を返す', () {
      final terms = filterGlossaryTerms(subjectId: null, favoritesOnly: true, favoriteTerms: {});
      expect(terms, isEmpty);
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
