import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/mock_history_store.dart';

MockHistoryEntry _entry(int score, int max) =>
    MockHistoryEntry(at: DateTime(2026, 10, 6), score: score, max: max, passed: score * 100 / max >= 60);

MockHistoryEntry _entryWithSubject(
  int score,
  int max, {
  required Map<String, int> subjectScore,
  required Map<String, int> subjectMax,
}) =>
    MockHistoryEntry(
      at: DateTime(2026, 10, 6),
      score: score,
      max: max,
      passed: score * 100 / max >= 60,
      subjectScore: subjectScore,
      subjectMax: subjectMax,
    );

void main() {
  group('predictPassTrend', () {
    test('直近の平均が合格ライン以上ならonTrack', () {
      final history = [_entry(25, 35), _entry(28, 35)]; // 71%, 80%
      expect(predictPassTrend(history, passPct: 60), PassPrediction.onTrack);
    });

    test('合格ラインまで10ポイント未満ならcloseToTarget', () {
      final history = [_entry(18, 35)]; // 約51.4%、合格ライン60%との差は約8.6
      expect(predictPassTrend(history, passPct: 60), PassPrediction.closeToTarget);
    });

    test('合格ラインまで10ポイント以上ならneedsWork', () {
      final history = [_entry(10, 35)]; // 約28.6%
      expect(predictPassTrend(history, passPct: 60), PassPrediction.needsWork);
    });

    test('4回以上あれば直近3回だけを見る', () {
      final history = [
        _entry(5, 35), // 約14.3%（古いので無視される）
        _entry(28, 35), // 80%
        _entry(28, 35), // 80%
        _entry(28, 35), // 80%
      ];
      expect(predictPassTrend(history, passPct: 60), PassPrediction.onTrack);
    });
  });

  group('predictSubjectPassTrend', () {
    test('科目のデータが無ければnull', () {
      final history = [_entry(25, 35)];
      expect(predictSubjectPassTrend(history, 'law', passPct: 60), isNull);
    });

    test('科目データがあれば、その科目だけの平均でonTrack/closeToTarget/needsWorkを判定する', () {
      final history = [
        _entryWithSubject(25, 35, subjectScore: {'law': 12}, subjectMax: {'law': 15}), // 80%
      ];
      expect(predictSubjectPassTrend(history, 'law', passPct: 60), PassPrediction.onTrack);
    });

    test('科目データが無い回は平均の対象から除く', () {
      final history = [
        _entry(5, 35), // 科目データ無し（無視される）
        _entryWithSubject(25, 35, subjectScore: {'law': 3}, subjectMax: {'law': 15}), // 20%
      ];
      expect(predictSubjectPassTrend(history, 'law', passPct: 60), PassPrediction.needsWork);
    });
  });

  group('passPredictionShortLabel', () {
    test('各判定に対応する一言ラベルを返す', () {
      expect(passPredictionShortLabel(PassPrediction.onTrack), '合格ライン到達中');
      expect(passPredictionShortLabel(PassPrediction.closeToTarget), 'もう少しで合格ライン');
      expect(passPredictionShortLabel(PassPrediction.needsWork), '合格ラインまで要対策');
    });
  });
}
