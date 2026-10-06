import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 直近に出題した問題のqidの記憶上限。
const maxRememberedQuestions = 30;

/// 新しい出題 [shown] を既存の履歴 [current]（新しい順）の先頭に積む。
/// 重複は新しい記録の方を残し、件数上限 [maxRememberedQuestions] で切り詰める。
List<String> mergeRecentQuestions(List<String> current, Iterable<String> shown) {
  final merged = [...shown, ...current.where((q) => !shown.contains(q))];
  return merged.take(maxRememberedQuestions).toList();
}

/// 直近に出題した問題のqid（新しい順）。一問一答の出題で同じ問題が
/// 連続・頻発しにくいよう、次のセッション構築時に優先的に避ける。
/// 永続化はせず、アプリ起動中のみ記憶する（再起動すれば自然にリセットされる）。
class RecentQuestionsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  /// 出題した問題のqidを記録する。
  void recordShown(Iterable<String> qids) {
    state = mergeRecentQuestions(state, qids);
  }
}

final recentQuestionsProvider =
    NotifierProvider<RecentQuestionsNotifier, List<String>>(RecentQuestionsNotifier.new);

/// [pool] から、直近出題した [recentIds] を避けたリストを返す。
/// 除外すると [minPoolSize] 未満になる場合は、除外せず元の [pool] をそのまま
/// 返す（問題データが少ない分野で出題できなくなるのを防ぐ）。
List<T> excludeRecent<T>(
  List<T> pool,
  Set<String> recentIds,
  String Function(T) idOf, {
  required int minPoolSize,
}) {
  final filtered = [for (final item in pool) if (!recentIds.contains(idOf(item))) item];
  return filtered.length >= minPoolSize ? filtered : pool;
}
