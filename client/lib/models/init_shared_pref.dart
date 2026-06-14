import 'dart:async';
import 'dart:convert';

import 'package:expense_tracker/db/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitSheredPref {
  static final InitSheredPref _instance = InitSheredPref._init();
  static InitSheredPref get instance => _instance;
  SharedPreferences? _prefs;
  InitSheredPref._init();
  Future<void> get getSharedPref async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// set and get theme
  Future<void> setTheme(String theme) async {
    await _prefs?.remove("theme");
    await _prefs?.setString("theme", theme);
  }

  Future<String?> getTheme() async {
    String? value = _prefs?.getString("theme");
    return value;
  }

  /// set and get auth token

  Future<void> setToken(String token) async {
    await _prefs?.remove("token");
    await _prefs?.setString("token", token);
    await clearLastLogoutDate();
    // Extract user_id from JWT payload
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(base64Url.decode(parts[1]));
        final data = jsonDecode(payload);
        if (data['sub'] != null) {
          await setUserId(data['sub']);
        }
      }
    } catch (_) {}
  }

  Future<String?> getToken() async {
    return _prefs?.getString("token");
  }

  Future<void> logOut() async {
    await DBHelper.instance.clearAllData();
    await _prefs?.remove("token");
    await _prefs?.remove("user_id");
    await _prefs?.remove("last_synced_at");
    await setLastLogoutDate();
  }

  /// set and get user id

  Future<void> setUserId(String userId) async {
    await _prefs?.setString("user_id", userId);
  }

  Future<String?> getUserId() async {
    return _prefs?.getString("user_id");
  }

  /// set and get last synced at

  Future<void> setLastSyncedAt(String syncedAt) async {
    await _prefs?.setString("last_synced_at", syncedAt);
  }

  Future<String?> getLastSyncedAt() async {
    return _prefs?.getString("last_synced_at");
  }

  //set and get images
  Future<void> setImages(String images) async {
    await _prefs?.remove("images");
    await _prefs?.setString("images", images);
  }

  Future<String?> getImages() async {
    return _prefs?.getString("images");
  }

  /// set and get profile details
  Future<void> setProfileName(String name) async {
    await _prefs?.setString("profile_name", name);
  }

  Future<String?> getProfileName() async {
    return _prefs?.getString("profile_name");
  }

  Future<void> setProfileEmail(String email) async {
    await _prefs?.setString("profile_email", email);
  }

  Future<String?> getProfileEmail() async {
    return _prefs?.getString("profile_email");
  }

  /// set and get last logout date
  Future<void> setLastLogoutDate() async {
    await _prefs?.setString("last_logout_date", DateTime.now().toIso8601String());
  }

  Future<String?> getLastLogoutDate() async {
    return _prefs?.getString("last_logout_date");
  }

  Future<void> clearLastLogoutDate() async {
    await _prefs?.remove("last_logout_date");
  }
}
