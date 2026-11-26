import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's backend URL across restarts.
class SettingsStore {
  // ignore: prefer_initializing_formals
  SettingsStore({SharedPreferences? preferences}) : _preferences = preferences;

  static const _baseUrlKey = 'api.base_url';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _instance async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<String?> readBaseUrl() async {
    final preferences = await _instance;
    return preferences.getString(_baseUrlKey);
  }

  Future<void> saveBaseUrl(String url) async {
    final preferences = await _instance;
    await preferences.setString(_baseUrlKey, url);
  }
}
