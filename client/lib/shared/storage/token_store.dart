import 'package:shared_preferences/shared_preferences.dart';


abstract class TokenStore {
  Future<String?> getAccessToken();

  Future<void> setAccessToken(String token);

  Future<void> clear();
}


class SharedPrefsTokenStore implements TokenStore {
  static const _key = 'access_token';

  @override
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> setAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
