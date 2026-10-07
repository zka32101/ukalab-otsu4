/// 推しの挨拶セリフの時間帯バリエーション（ホームの「推し」カード用）。
///
/// `app_common_kit` の `MascotLines`（セリフ集）は共通パッケージ側で管理
/// されており、このリポジトリから直接追加できない。学習済み・連続記録・
/// 試験日連動等の場面別セリフは `MascotLines.gentle` を使い続け、特別な
/// 状況が無い「greeting」場面（`lib/widgets/oshi_card.dart` の
/// `_situationFor`）だけ、otsu4側で時間帯に応じた追加バリエーションを
/// 用意する。口調・禁止表現のルールは `app_common_kit` と同じ
/// （責めない・落ち込ませない・恋愛依存を煽らない）。
enum TimeOfDayGreeting { morning, afternoon, evening, night }

/// [now] の時刻から、朝・昼・夕方・夜のどの時間帯かを返す。
TimeOfDayGreeting timeOfDayGreetingFor(DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour < 11) return TimeOfDayGreeting.morning;
  if (hour >= 11 && hour < 17) return TimeOfDayGreeting.afternoon;
  if (hour >= 17 && hour < 21) return TimeOfDayGreeting.evening;
  return TimeOfDayGreeting.night;
}

const _timeOfDayGreetingLines = <TimeOfDayGreeting, List<String>>{
  TimeOfDayGreeting.morning: [
    'おはようございます。今日も少しずつ進めましょう',
    '朝の時間に1問、始めてみませんか',
  ],
  TimeOfDayGreeting.afternoon: [
    'こんにちは。今日も少しずつ進めましょう',
    '午後のひと休みに、復習はいかがですか',
  ],
  TimeOfDayGreeting.evening: [
    'こんばんは。今日の分を少し進めてみましょう',
    '夕方のひとときに、1問だけでも',
  ],
  TimeOfDayGreeting.night: [
    '夜遅くまでおつかれさまです。無理のない範囲で',
    '今日の学習、もう少しだけ進めてみませんか',
  ],
};

/// [now] の時間帯に応じた挨拶セリフを1つ返す（[seed] で決まる。同じseedなら
/// 同じ文言になり、タップで`_seed`を進めると次のバリエーションに替わる）。
String pickTimeOfDayGreeting(DateTime now, {int seed = 0}) {
  final lines = _timeOfDayGreetingLines[timeOfDayGreetingFor(now)]!;
  return lines[seed.abs() % lines.length];
}
