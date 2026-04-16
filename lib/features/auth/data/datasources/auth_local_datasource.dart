import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();

  Future<void> saveRememberMe(String username, String password);
  Future<(String, String)?> getRememberMe();
  Future<void> clearRememberMe();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl(this.sharedPreferences);

  static const _tokenKey = 'auth_token';
  static const _rememberUsernameKey = 'remember_username';
  static const _rememberPasswordKey = 'remember_password';

  @override
  Future<void> saveToken(String token) async {
    await sharedPreferences.setString(_tokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    return sharedPreferences.getString(_tokenKey);
  }

  @override
  Future<void> clearToken() async {
    await sharedPreferences.remove(_tokenKey);
  }

  @override
  Future<void> saveRememberMe(String username, String password) async {
    await sharedPreferences.setString(_rememberUsernameKey, username);
    await sharedPreferences.setString(_rememberPasswordKey, password);
  }

  @override
  Future<(String, String)?> getRememberMe() async {
    final username = sharedPreferences.getString(_rememberUsernameKey);
    final password = sharedPreferences.getString(_rememberPasswordKey);
    if (username != null && password != null) {
      return (username, password);
    }
    return null;
  }

  @override
  Future<void> clearRememberMe() async {
    await sharedPreferences.remove(_rememberUsernameKey);
    await sharedPreferences.remove(_rememberPasswordKey);
  }
}
