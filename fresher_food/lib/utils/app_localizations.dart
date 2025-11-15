import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Vietnamese translations
  static const Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      // Settings
      'settings': 'Cài đặt',
      'notifications': 'Thông báo',
      'enable_notifications': 'Bật thông báo',
      'enable_notifications_desc': 'Nhận thông báo từ ứng dụng',
      'email_notifications': 'Thông báo qua email',
      'email_notifications_desc': 'Nhận thông báo qua email',
      'push_notifications': 'Thông báo đẩy',
      'push_notifications_desc': 'Nhận thông báo đẩy trên thiết bị',
      'appearance': 'Giao diện',
      'dark_mode': 'Chế độ tối',
      'dark_mode_desc': 'Bật chế độ tối cho ứng dụng',
      'language': 'Ngôn ngữ',
      'language_desc': 'Chọn ngôn ngữ hiển thị',
      'vietnamese': 'Tiếng Việt',
      'english': 'Tiếng Anh',
      'other': 'Khác',
      'storage': 'Dữ liệu và bộ nhớ',
      'save': 'Lưu',
      'cancel': 'Hủy',
      'select_language': 'Chọn ngôn ngữ',
      'light': 'Sáng',
      'dark': 'Tối',
      'system': 'Theo hệ thống',
    },
    'en': {
      // Settings
      'settings': 'Settings',
      'notifications': 'Notifications',
      'enable_notifications': 'Enable Notifications',
      'enable_notifications_desc': 'Receive notifications from the app',
      'email_notifications': 'Email Notifications',
      'email_notifications_desc': 'Receive notifications via email',
      'push_notifications': 'Push Notifications',
      'push_notifications_desc': 'Receive push notifications on device',
      'appearance': 'Appearance',
      'dark_mode': 'Dark Mode',
      'dark_mode_desc': 'Enable dark mode for the app',
      'language': 'Language',
      'language_desc': 'Select display language',
      'vietnamese': 'Vietnamese',
      'english': 'English',
      'other': 'Other',
      'storage': 'Data and Storage',
      'save': 'Save',
      'cancel': 'Cancel',
      'select_language': 'Select Language',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for common translations
  String get settings => translate('settings');
  String get notifications => translate('notifications');
  String get enableNotifications => translate('enable_notifications');
  String get enableNotificationsDesc => translate('enable_notifications_desc');
  String get emailNotifications => translate('email_notifications');
  String get emailNotificationsDesc => translate('email_notifications_desc');
  String get pushNotifications => translate('push_notifications');
  String get pushNotificationsDesc => translate('push_notifications_desc');
  String get appearance => translate('appearance');
  String get darkMode => translate('dark_mode');
  String get darkModeDesc => translate('dark_mode_desc');
  String get language => translate('language');
  String get languageDesc => translate('language_desc');
  String get vietnamese => translate('vietnamese');
  String get english => translate('english');
  String get other => translate('other');
  String get storage => translate('storage');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get selectLanguage => translate('select_language');
  String get light => translate('light');
  String get dark => translate('dark');
  String get system => translate('system');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['vi', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

