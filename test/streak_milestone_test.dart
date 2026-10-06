import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/views/record_view.dart';

void main() {
  group('latestStreakMilestone', () {
    test('節目に達していなければnull', () {
      expect(latestStreakMilestone(2), isNull);
    });

    test('節目にちょうど達したらその値', () {
      expect(latestStreakMilestone(7), 7);
    });

    test('節目の間にあれば直前の節目', () {
      expect(latestStreakMilestone(20), 14);
    });

    test('最大の節目を超えても最大の節目のまま', () {
      expect(latestStreakMilestone(1000), 365);
    });
  });
}
