/// Secure storage service for tokens and sensitive data.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Token Management ─────────────────────────────────────────────
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: 'access_token', value: token);

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: 'refresh_token', value: token);

  Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');

  // ── User Data ────────────────────────────────────────────────────
  Future<void> saveUserId(String id) =>
      _storage.write(key: 'user_id', value: id);

  Future<String?> getUserId() => _storage.read(key: 'user_id');

  Future<void> saveUserRole(String role) =>
      _storage.write(key: 'user_role', value: role);

  Future<String?> getUserRole() => _storage.read(key: 'user_role');

  Future<void> saveOfflineUser(String userJson) =>
      _storage.write(key: 'cached_user', value: userJson);

  Future<String?> getOfflineUser() => _storage.read(key: 'cached_user');

  // ── Notifications ────────────────────────────────────────────────
  Future<void> saveNotificationsReadAt(String timestamp) =>
      _storage.write(key: 'notifications_read_at', value: timestamp);

  Future<String?> getNotificationsReadAt() =>
      _storage.read(key: 'notifications_read_at');

  // ── Offline Login ──────────────────────────────────────────────────
  // Removed insecure offline credentials storage methods. Offline support should use tokens.

  // ── Clear ────────────────────────────────────────────────────────
  Future<void> clearAll() => _storage.deleteAll();

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
