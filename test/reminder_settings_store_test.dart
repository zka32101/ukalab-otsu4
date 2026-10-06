import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/reminder_settings_store.dart';

void main() {
  group('ReminderSettingsService', () {
    test('初期状態は両方オン', () async {
      final service = ReminderSettingsService(store: _FakeStore());
      expect(service.settings.studyReminderEnabled, isTrue);
      expect(service.settings.mockReminderEnabled, isTrue);
    });

    test('学習リマインダーだけをオフにできる', () async {
      final service = ReminderSettingsService(store: _FakeStore());
      await service.setStudyReminderEnabled(false);
      expect(service.settings.studyReminderEnabled, isFalse);
      expect(service.settings.mockReminderEnabled, isTrue);
    });

    test('模試リマインダーだけをオフにできる', () async {
      final service = ReminderSettingsService(store: _FakeStore());
      await service.setMockReminderEnabled(false);
      expect(service.settings.studyReminderEnabled, isTrue);
      expect(service.settings.mockReminderEnabled, isFalse);
    });

    test('保存・再読み込みで状態が復元される', () async {
      final store = _FakeStore();
      final service = ReminderSettingsService(store: store);
      await service.setStudyReminderEnabled(false);
      await service.setMockReminderEnabled(false);

      final reloaded = ReminderSettingsService(store: store);
      await reloaded.load();
      expect(reloaded.settings.studyReminderEnabled, isFalse);
      expect(reloaded.settings.mockReminderEnabled, isFalse);
    });
  });
}

/// テスト用。SharedPreferencesを使わずメモリ上に保存する。
class _FakeStore implements ReminderSettingsStore {
  ReminderSettings _saved = const ReminderSettings();

  @override
  Future<ReminderSettings> read() async => _saved;

  @override
  Future<void> write(ReminderSettings settings) async => _saved = settings;
}
