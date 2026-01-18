import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';

  // Save login data
  static Future<void> saveLogin({
    required String token,
    required String userId,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUserId, value: userId);
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    String? token = await _storage.read(key: _keyToken);
    return token != null;
  }

  // Logout
  static Future<void> logout() async {
    await _storage.deleteAll();
  }
}
