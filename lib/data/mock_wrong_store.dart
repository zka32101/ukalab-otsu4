import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 直近の模擬試験で間違えた問題のqid一覧（端末内保存）。模試を終えるたびに
/// 直近1回分で上書きする。模試終了直後に見る読み取り専用の振り返り
/// （`MockReviewView`）とは別に、模試を離れたあとでも一問一答として
/// 選んで答えながら復習できるようにする（`MockWrongReviewView`）。
class MockWrongStore {
  static const _key = 'ukalab_otsu4_mock_wrong_qids';

  Future<List<String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> write(List<String> qids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(qids));
  }
}

/// 直近の模試の間違いの読み込み・更新。`main()` で `load()` してから
/// `mockWrongServiceProvider.overrideWithValue(...)` で渡す。
class MockWrongService {
  MockWrongService({MockWrongStore? store}) : _store = store ?? MockWrongStore();

  final MockWrongStore _store;
  List<String> _qids = [];

  List<String> get qids => _qids;

  Future<void> load() async {
    _qids = await _store.read();
  }

  /// 模擬試験を終えたときに呼ぶ。直近1回分で上書きする。
  Future<List<String>> setWrong(List<String> qids) async {
    _qids = qids;
    await _store.write(_qids);
    return _qids;
  }

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<List<String>> reset() async {
    _qids = [];
    await _store.write(_qids);
    return _qids;
  }
}

final mockWrongServiceProvider = Provider<MockWrongService>(
  (ref) => throw UnimplementedError('mockWrongServiceProvider を override してください'),
);

class MockWrongNotifier extends Notifier<List<String>> {
  MockWrongService get _s => ref.read(mockWrongServiceProvider);

  @override
  List<String> build() => _s.qids;

  Future<void> setWrong(List<String> qids) async {
    state = await _s.setWrong(qids);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }
}

final mockWrongProvider = NotifierProvider<MockWrongNotifier, List<String>>(MockWrongNotifier.new);
