import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppStats {
  static const String _keyOpenCountPrefix = 'open_count_';
  static const String _keyTopicsHistory = 'topics_history';
  static const String _keyTotalSessions = 'total_sessions';

  static String _todayKey() {
    final now = DateTime.now();
    return '$_keyOpenCountPrefix${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> recordSessionOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    final todayCount = prefs.getInt(todayKey) ?? 0;
    await prefs.setInt(todayKey, todayCount + 1);
    final total = prefs.getInt(_keyTotalSessions) ?? 0;
    await prefs.setInt(_keyTotalSessions, total + 1);
  }

  static Future<int> getTodayOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_todayKey()) ?? 0;
  }

  static Future<int> getTotalSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalSessions) ?? 0;
  }

  static Future<void> recordTopicSearch(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTopicsHistory);
    final List<String> list =
        raw != null ? List<String>.from(jsonDecode(raw)) : [];
    list.add(topic);
    if (list.length > 50) list.removeAt(0);
    await prefs.setString(_keyTopicsHistory, jsonEncode(list));
  }

  static Future<String?> getMostSearchedTopic() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTopicsHistory);
    if (raw == null) return null;
    final List<String> list = List<String>.from(jsonDecode(raw));
    if (list.isEmpty) return null;
    final counts = <String, int>{};
    for (final t in list) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static Future<List<String>> getTopicsHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTopicsHistory);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  static Future<void> clearStats() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    await prefs.remove(todayKey);
    await prefs.remove(_keyTotalSessions);
    await prefs.remove(_keyTopicsHistory);
  }
}
