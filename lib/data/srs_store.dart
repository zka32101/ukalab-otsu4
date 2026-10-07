import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourwish_kentei/yourwish_kentei.dart';

/// 苦手問題の復習（間隔反復・`yourwish_kentei` の `Srs`）の端末内保存。
class SrsStore {
  static const _key = 'ukalab_otsu4_srs';

  Future<Map<String, SrsItem>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List;
      final items = [for (final j in list) SrsItem.fromJson(j as Map<String, dynamic>)];
      return {for (final i in items) i.qid: i};
    } catch (_) {
      return {};
    }
  }

  Future<void> write(Map<String, SrsItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final i in items.values) i.toJson()]));
  }
}

/// 苦手問題の読み込み・更新。`main()` で `load()` してから
/// `srsServiceProvider.overrideWithValue(...)` で渡す。
class SrsService {
  SrsService({SrsStore? store, DateTime Function()? clock})
      : _store = store ?? SrsStore(),
        _clock = clock ?? DateTime.now;

  final SrsStore _store;
  final DateTime Function() _clock;
  Map<String, SrsItem> _items = {};

  Map<String, SrsItem> get items => _items;

  Future<void> load() async {
    _items = await _store.read();
  }

  /// 一問一答で1問答えたときに呼ぶ。正解で箱が上がり復習間隔が延び、
  /// 不正解で箱0（すぐ復習対象）に戻る。
  Future<Map<String, SrsItem>> review({required String qid, required bool correct}) async {
    final updated = Srs.review(_items[qid], qid: qid, correct: correct, now: _clock());
    _items = {..._items, qid: updated};
    await _store.write(_items);
    return _items;
  }

  /// 復習時期が来ている問題のqid（期限の古い順）。
  List<String> dueQids({int? limit}) =>
      Srs.due(_items.values, _clock(), limit: limit).map((i) => i.qid).toList();

  /// 学習記録のリセット時に呼ぶ。初期状態に戻す。
  Future<Map<String, SrsItem>> reset() async {
    _items = {};
    await _store.write(_items);
    return _items;
  }

  /// バックアップの読み込み時に呼ぶ。[items] で上書きする。
  Future<Map<String, SrsItem>> restore(Map<String, SrsItem> items) async {
    _items = items;
    await _store.write(_items);
    return _items;
  }
}

final srsServiceProvider = Provider<SrsService>(
  (ref) => throw UnimplementedError('srsServiceProvider を override してください'),
);

class SrsNotifier extends Notifier<Map<String, SrsItem>> {
  SrsService get _s => ref.read(srsServiceProvider);

  @override
  Map<String, SrsItem> build() => _s.items;

  Future<void> review({required String qid, required bool correct}) async {
    state = await _s.review(qid: qid, correct: correct);
  }

  Future<void> reset() async {
    state = await _s.reset();
  }

  Future<void> restore(Map<String, SrsItem> items) async {
    state = await _s.restore(items);
  }
}

final srsProvider = NotifierProvider<SrsNotifier, Map<String, SrsItem>>(SrsNotifier.new);

/// 復習時期が来ている問題のqid（期限の古い順）。
final dueWeakQidsProvider = Provider<List<String>>((ref) {
  final items = ref.watch(srsProvider);
  return Srs.due(items.values, DateTime.now()).map((i) => i.qid).toList();
});

/// 箱（0〜`Srs.maxBox`）ごとの問題数。苦手問題の復習の定着度分布表示に使う。
/// 箱が大きいほど復習間隔が長く、定着が進んでいることを示す。
Map<int, int> srsBoxDistribution(Iterable<SrsItem> items) {
  final dist = {for (var box = 0; box <= Srs.maxBox; box++) box: 0};
  for (final item in items) {
    dist[item.box] = (dist[item.box] ?? 0) + 1;
  }
  return dist;
}
