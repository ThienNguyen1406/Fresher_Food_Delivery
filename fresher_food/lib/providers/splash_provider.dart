import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashProvider with ChangeNotifier {
  static const String _hasShownSplashKey = 'has_shown_splash';
  bool _hasShownSplash = false;
  bool _isInitialized = false;

  bool get hasShownSplash => _hasShownSplash;
  bool get isInitialized => _isInitialized;

  SplashProvider() {
    _loadSplashStatus();
  }

  /// Load splash status from SharedPreferences
  Future<void> _loadSplashStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasShownSplash = prefs.getBool(_hasShownSplashKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading splash status: $e');
      _hasShownSplash = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Mark splash screen as shown
  Future<void> markSplashAsShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasShownSplashKey, true);
      _hasShownSplash = true;
      notifyListeners();
    } catch (e) {
      print('Error marking splash as shown: $e');
    }
  }

  /// Reset splash status (for testing or app reload)
  Future<void> resetSplashStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasShownSplashKey, false);
      _hasShownSplash = false;
      notifyListeners();
    } catch (e) {
      print('Error resetting splash status: $e');
    }
  }
}

