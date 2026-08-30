import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? secure})
      : _secure = secure ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;
  static const _token = 'auth_token';
  static const _refresh = 'refresh_token';

  Future<String?> getToken() async {
    try {
      return await _secure.read(key: _token);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_token);
    }
  }

  Future<String?> getRefresh() async {
    try {
      return await _secure.read(key: _refresh);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refresh);
    }
  }

  Future<void> saveTokens(String token, String? refresh) async {
    try {
      await _secure.write(key: _token, value: token);
      if (refresh != null) await _secure.write(key: _refresh, value: refresh);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_token, token);
      if (refresh != null) await prefs.setString(_refresh, refresh);
    }
  }

  Future<void> clear() async {
    try {
      await _secure.delete(key: _token);
      await _secure.delete(key: _refresh);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_token);
      await prefs.remove(_refresh);
    }
  }
}
