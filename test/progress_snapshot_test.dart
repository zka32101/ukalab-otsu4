import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/progress_store.dart';

void main() {
  group('ProgressSnapshot', () {
    test('未解答なら網羅率・正答率は0', () {
      const p = ProgressSnapshot();
      expect(p.coverage, 0);
      expect(p.accuracy, 0);
    });

    test('網羅率は100問相当で頭打ち', () {
      const p = ProgressSnapshot(answered: 250, correct: 250);
      expect(p.coverage, 1.0);
    });

    test('網羅率・正答率の計算', () {
      const p = ProgressSnapshot(answered: 40, correct: 30);
      expect(p.coverage, closeTo(0.4, 1e-9));
      expect(p.accuracy, closeTo(0.75, 1e-9));
    });

    test('copyWithは指定した値だけ変更する', () {
      const p = ProgressSnapshot(answered: 1, correct: 1, streakDays: 2);
      final updated = p.copyWith(answered: 2);
      expect(updated.answered, 2);
      expect(updated.correct, 1);
      expect(updated.streakDays, 2);
    });

    test('toJson/fromJsonの往復', () {
      final date = DateTime(2026, 10, 4);
      final p = ProgressSnapshot(answered: 5, correct: 3, streakDays: 2, lastStudyDate: date);
      final restored = ProgressSnapshot.fromJson(p.toJson());
      expect(restored.answered, 5);
      expect(restored.correct, 3);
      expect(restored.streakDays, 2);
      expect(restored.lastStudyDate, date);
    });
  });

  group('ProgressService.recordAnswer', () {
    test('初回の解答でanswered・correctが増え、streakDaysは1になる', () async {
      final now = DateTime(2026, 10, 4, 9);
      final service = ProgressService(store: _FakeProgressStore(), clock: () => now);
      final snapshot = await service.recordAnswer(correct: true);
      expect(snapshot.answered, 1);
      expect(snapshot.correct, 1);
      expect(snapshot.streakDays, 1);
    });

    test('同じ日に複数回答えてもstreakDaysは増えない', () async {
      var now = DateTime(2026, 10, 4, 9);
      final service = ProgressService(store: _FakeProgressStore(), clock: () => now);
      await service.recordAnswer(correct: true);
      now = DateTime(2026, 10, 4, 20);
      final snapshot = await service.recordAnswer(correct: false);
      expect(snapshot.answered, 2);
      expect(snapshot.correct, 1);
      expect(snapshot.streakDays, 1);
    });

    test('翌日に答えるとstreakDaysが増える', () async {
      var now = DateTime(2026, 10, 4, 9);
      final service = ProgressService(store: _FakeProgressStore(), clock: () => now);
      await service.recordAnswer(correct: true);
      now = DateTime(2026, 10, 5, 9);
      final snapshot = await service.recordAnswer(correct: true);
      expect(snapshot.streakDays, 2);
    });

    test('1日以上空くとstreakDaysは1に戻る', () async {
      var now = DateTime(2026, 10, 4, 9);
      final service = ProgressService(store: _FakeProgressStore(), clock: () => now);
      await service.recordAnswer(correct: true);
      now = DateTime(2026, 10, 7, 9);
      final snapshot = await service.recordAnswer(correct: true);
      expect(snapshot.streakDays, 1);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeProgressStore implements ProgressStore {
  ProgressSnapshot? _saved;

  @override
  Future<ProgressSnapshot> read() async => _saved ?? const ProgressSnapshot();

  @override
  Future<void> write(ProgressSnapshot snapshot) async => _saved = snapshot;
}
