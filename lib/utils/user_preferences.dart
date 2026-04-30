import 'package:shared_preferences/shared_preferences.dart';
import 'app_enums.dart';
import '../config/app_config.dart';

class UserPreferences {
  static const String _keySchoolLevel = 'school_level';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyIsGuest = 'is_guest';
  static const String _keyUserEmail = 'user_email';

  // ---------------------------------------------------------------------------
  // School level
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // School level
  // ---------------------------------------------------------------------------

  /// In modalità DEV restituisce sempre null (nessun livello salvato).
  static Future<SchoolLevel?> getSavedSchoolLevel() async {
    if (AppConfig.isDev) return null;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keySchoolLevel);
    if (stored == null) return null;
    return SchoolLevel.fromRouteArgument(stored);
  }

  /// In modalità DEV restituisce sempre true (sempre primo avvio).
  static Future<bool> isFirstLaunch() async {
    if (AppConfig.isDev) return true;
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_keySchoolLevel);
  }

  /// In modalità DEV è un no-op (non scrive su disco).
  static Future<void> saveSchoolLevel(SchoolLevel level) async {
    if (AppConfig.isDev) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySchoolLevel, level.routeArgument);
  }

  /// In modalità DEV è un no-op.
  static Future<void> clearProfile() async {
    if (AppConfig.isDev) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySchoolLevel);
  }

  // ---------------------------------------------------------------------------
  // Login / Guest state
  // ---------------------------------------------------------------------------

  /// In modalità DEV restituisce sempre false.
  static Future<bool> isLoggedIn() async {
    if (AppConfig.isDev) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// In modalità DEV restituisce sempre false.
  static Future<bool> isGuest() async {
    if (AppConfig.isDev) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsGuest) ?? false;
  }

  /// In modalità DEV restituisce sempre null.
  static Future<String?> getUserEmail() async {
    if (AppConfig.isDev) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  /// In modalità DEV è un no-op.
  static Future<void> saveLoginState({required String email}) async {
    if (AppConfig.isDev) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setBool(_keyIsGuest, false);
    await prefs.setString(_keyUserEmail, email);
  }

  /// In modalità DEV è un no-op.
  static Future<void> saveGuestState() async {
    if (AppConfig.isDev) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsGuest, true);
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserEmail);
  }

  /// Cancella tutto: login state + profilo scolastico.
  /// In modalità DEV è un no-op (nulla è stato salvato).
  static Future<void> clearLoginState() async {
    if (AppConfig.isDev) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyIsGuest);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keySchoolLevel);
  }
}
