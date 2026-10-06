import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 試験日（本番の日付）の端末内保存。未設定なら null。
class ExamDateStore {
  static const _key = 'ukalab_otsu4_exam_date';

  Future<DateTime?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(DateTime? date) async {
    final prefs = await SharedPreferences.getInstance();
    if (date == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, date.toIso8601String());
    }
  }
}

/// 試験日の読み込み・更新。`main()` で `load()` してから
/// `examDateServiceProvider.overrideWithValue(...)` で渡す。
class ExamDateService {
  ExamDateService({ExamDateStore? store}) : _store = store ?? ExamDateStore();

  final ExamDateStore _store;
  DateTime? _date;

  DateTime? get date => _date;

  Future<void> load() async {
    _date = await _store.read();
  }

  /// 試験日を設定する。null で設定を解除する。
  Future<DateTime?> setDate(DateTime? date) async {
    _date = date;
    await _store.write(date);
    return _date;
  }
}

final examDateServiceProvider = Provider<ExamDateService>(
  (ref) => throw UnimplementedError('examDateServiceProvider を override してください'),
);

class ExamDateNotifier extends Notifier<DateTime?> {
  ExamDateService get _s => ref.read(examDateServiceProvider);

  @override
  DateTime? build() => _s.date;

  Future<void> setDate(DateTime? date) async {
    state = await _s.setDate(date);
  }
}

final examDateProvider = NotifierProvider<ExamDateNotifier, DateTime?>(ExamDateNotifier.new);

/// [examDate] までの残り日数（日付のみで計算。当日なら0、過去なら負の値）。
int daysUntilExam(DateTime examDate, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(examDate.year, examDate.month, examDate.day);
  return target.difference(today).inDays;
}

/// 残り日数からホームに表示する文言を組み立てる。
String examCountdownText(int daysLeft) {
  if (daysLeft > 0) return '本番まであと$daysLeft日';
  if (daysLeft == 0) return '本番は今日です';
  return '本番から${-daysLeft}日経過しました';
}
