import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/mock_history_store.dart';

MockHistoryEntry _entry(int score, int max) =>
    MockHistoryEntry(at: DateTime(2026, 10, 6), score: score, max: max, passed: score * 100 / max >= 60);

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
}
