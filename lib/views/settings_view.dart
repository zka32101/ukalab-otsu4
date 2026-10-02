import 'package:flutter/material.dart';

/// 免責表示（うかラボ共通方針）。ストア説明文の冒頭の注意書きと趣旨を揃える。
const String appDisclaimer =
    '本アプリは、消防試験研究センター等の危険物取扱者試験の実施団体・主催者とは一切関係のない、'
    'Your Wish が制作した非公式の学習アプリです。\n'
    '試験名は、学習の対象を示すためにのみ使用しています。問題・解説は独自に作成したもので、'
    '実際の試験の出題内容や合格を保証するものではありません。\n'
    '最新の試験情報は、実施団体の公式サイトでご確認ください。';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('このアプリについて', style: theme.textTheme.titleSmall),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 24),
          child: Text(appDisclaimer, style: TextStyle(fontSize: 12, height: 1.6)),
        ),
      ],
    );
  }
}
