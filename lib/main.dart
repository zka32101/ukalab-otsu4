import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/bookmark_store.dart';
import 'data/mock_history_store.dart';
import 'data/progress_store.dart';
import 'data/srs_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 学習コイン・衣装（app_common_kit）。財布はアプリごと。端末内に保存する。
  // コインは学習の成長でのみ獲得する（課金・広告視聴での付与はしない）。
  final coinService = CoinService(
    store: SharedPreferencesCoinStore('otsu4'),
    shop: OutfitCatalog.shopItems([UkalabCert.hazmat4]),
  );
  await coinService.load();
  final outfitService = OutfitService(store: SharedPreferencesOutfitStore('otsu4'));
  await outfitService.load();

  // 推しの成長の暫定の進捗指標（問題データが入るまでの代替。README参照）。
  final progressService = ProgressService();
  await progressService.load();

  // 苦手問題の復習（間隔反復）。端末内に保存する。
  final srsService = SrsService();
  await srsService.load();

  // 模擬試験の結果履歴。端末内に保存する。
  final mockHistoryService = MockHistoryService();
  await mockHistoryService.load();

  // 気になる問題のブックマーク。端末内に保存する。
  final bookmarkService = BookmarkService();
  await bookmarkService.load();

  runApp(
    ProviderScope(
      overrides: [
        coinServiceProvider.overrideWithValue(coinService),
        outfitServiceProvider.overrideWithValue(outfitService),
        progressServiceProvider.overrideWithValue(progressService),
        srsServiceProvider.overrideWithValue(srsService),
        mockHistoryServiceProvider.overrideWithValue(mockHistoryService),
        bookmarkServiceProvider.overrideWithValue(bookmarkService),
      ],
      child: const Otsu4App(),
    ),
  );
}
