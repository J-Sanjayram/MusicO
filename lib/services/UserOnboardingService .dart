// lib/services/user_onboarding_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserOnboardingService {
  static const String _kHasOnboarded = 'has_onboarded';
  static const String _kUserName = 'user_name';
  static const String _kUserKey = 'user_key';

  Future<bool> hasUserOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasOnboarded) ?? false;
  }

  Future<void> completeOnboarding(String name, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserName, name);
    await prefs.setString(_kUserKey, key);
    await prefs.setBool(_kHasOnboarded, true);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserName);
  }

  Future<String?> getUserKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserKey);
  }

  // For testing/resetting purposes
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHasOnboarded);
    await prefs.remove(_kUserName);
    await prefs.remove(_kUserKey);
  }
}