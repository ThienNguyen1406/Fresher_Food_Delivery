import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/providers/theme_provider.dart';
import 'package:fresher_food/providers/language_provider.dart';
import 'package:fresher_food/utils/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.darkMode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text(localizations.light),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(localizations.dark),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(localizations.system),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(localizations.vietnamese),
                value: 'vi',
                groupValue: languageProvider.languageCode,
                onChanged: (String? value) {
                  if (value != null) {
                    languageProvider.setLanguage(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<String>(
                title: Text(localizations.english),
                value: 'en',
                groupValue: languageProvider.languageCode,
                onChanged: (String? value) {
                  if (value != null) {
                    languageProvider.setLanguage(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getThemeModeText(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        return localizations.light;
      case ThemeMode.dark:
        return localizations.dark;
      case ThemeMode.system:
        return localizations.system;
    }
  }

  String _getLanguageText(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    
    return languageProvider.isVietnamese 
        ? localizations.vietnamese 
        : localizations.english;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.settings,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingsSection(
              title: localizations.notifications,
              children: [
                SwitchListTile(
                  title: Text(localizations.enableNotifications),
                  subtitle: Text(localizations.enableNotificationsDesc),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _saveSetting('notifications_enabled', value);
                  },
                  activeColor: const Color(0xFF667EEA),
                ),
                Opacity(
                  opacity: _notificationsEnabled ? 1.0 : 0.5,
                  child: SwitchListTile(
                    title: Text(localizations.emailNotifications),
                    subtitle: Text(localizations.emailNotificationsDesc),
                    value: _emailNotifications,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            setState(() => _emailNotifications = value);
                            _saveSetting('email_notifications', value);
                          }
                        : null,
                    activeColor: const Color(0xFF667EEA),
                  ),
                ),
                Opacity(
                  opacity: _notificationsEnabled ? 1.0 : 0.5,
                  child: SwitchListTile(
                    title: Text(localizations.pushNotifications),
                    subtitle: Text(localizations.pushNotificationsDesc),
                    value: _pushNotifications,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            setState(() => _pushNotifications = value);
                            _saveSetting('push_notifications', value);
                          }
                        : null,
                    activeColor: const Color(0xFF667EEA),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              title: localizations.appearance,
              children: [
                ListTile(
                  leading: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : themeProvider.themeMode == ThemeMode.light
                            ? Icons.light_mode
                            : Icons.brightness_auto,
                    color: const Color(0xFF667EEA),
                  ),
                  title: Text(localizations.darkMode),
                  subtitle: Text(_getThemeModeText(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showThemeDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language, color: Color(0xFF667EEA)),
                  title: Text(localizations.language),
                  subtitle: Text(_getLanguageText(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showLanguageDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              title: localizations.other,
              children: [
                ListTile(
                  leading: const Icon(Icons.storage_outlined,
                      color: Color(0xFF667EEA)),
                  title: Text(localizations.storage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showComingSoon(localizations.storage);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Tính năng đang phát triển'),
        backgroundColor: const Color(0xFF00C896),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
