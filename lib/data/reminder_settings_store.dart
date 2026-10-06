import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリ内リマインダー（学習・模試）を個別に表示するかどうかの設定。
class ReminderSettings {
  const ReminderSettings({this.studyReminderEnabled = true, this.mockReminderEnabled = true});

  /// デイリーミッション未達成時の学習リマインダー（ホーム）を表示するか。
  final bool studyReminderEnabled;

  /// 模擬試験の受験間隔リマインダー（ホーム）を表示するか。
  final bool mockReminderEnabled;

  ReminderSettings copyWith({bool? studyReminderEnabled, bool? mockReminderEnabled}) =>
      ReminderSettings(
        studyReminderEnabled: studyReminderEnabled ?? this.studyReminderEnabled,
        mockReminderEnabled: mockReminderEnabled ?? this.mockReminderEnabled,
      );

  Map<String, dynamic> toJson() => {
        'studyReminderEnabled': studyReminderEnabled,
        'mockReminderEnabled': mockReminderEnabled,
      };

  static ReminderSettings fromJson(Map<String, dynamic> json) => ReminderSettings(
        studyReminderEnabled: json['studyReminderEnabled'] as bool? ?? true,
        mockReminderEnabled: json['mockReminderEnabled'] as bool? ?? true,
      );
}

/// リマインダー設定の端末内保存。
class ReminderSettingsStore {
  static const _key = 'ukalab_otsu4_reminder_settings';

  Future<ReminderSettings> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const ReminderSettings();
    try {
      return ReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ReminderSettings();
    }
  }

  Future<void> write(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}

/// リマインダー設定の読み込み・更新。`main()` で `load()` してから
/// `reminderSettingsServiceProvider.overrideWithValue(...)` で渡す。
class ReminderSettingsService {
  ReminderSettingsService({ReminderSettingsStore? store}) : _store = store ?? ReminderSettingsStore();

  final ReminderSettingsStore _store;
  ReminderSettings _settings = const ReminderSettings();

  ReminderSettings get settings => _settings;

  Future<void> load() async {
    _settings = await _store.read();
  }

  Future<ReminderSettings> setStudyReminderEnabled(bool enabled) async {
    _settings = _settings.copyWith(studyReminderEnabled: enabled);
    await _store.write(_settings);
    return _settings;
  }

  Future<ReminderSettings> setMockReminderEnabled(bool enabled) async {
    _settings = _settings.copyWith(mockReminderEnabled: enabled);
    await _store.write(_settings);
    return _settings;
  }
}

final reminderSettingsServiceProvider = Provider<ReminderSettingsService>(
  (ref) => throw UnimplementedError('reminderSettingsServiceProvider を override してください'),
);

class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  ReminderSettingsService get _s => ref.read(reminderSettingsServiceProvider);

  @override
  ReminderSettings build() => _s.settings;

  Future<void> setStudyReminderEnabled(bool enabled) async {
    state = await _s.setStudyReminderEnabled(enabled);
  }

  Future<void> setMockReminderEnabled(bool enabled) async {
    state = await _s.setMockReminderEnabled(enabled);
  }
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(ReminderSettingsNotifier.new);
