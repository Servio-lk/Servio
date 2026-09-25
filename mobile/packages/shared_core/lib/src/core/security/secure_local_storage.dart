import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage;

  const SecureLocalStorage([this._storage = const FlutterSecureStorage()]);

  AndroidOptions get _androidOptions => const AndroidOptions();

  IOSOptions get _iosOptions => const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      );

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    return await _storage.read(
      key: supabasePersistSessionKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  @override
  Future<bool> hasAccessToken() async {
    return await _storage.containsKey(
      key: supabasePersistSessionKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(
      key: supabasePersistSessionKey,
      value: persistSessionString,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(
      key: supabasePersistSessionKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }
}
