import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  static const _store = FlutterSecureStorage();
  Future<String?> get token => _store.read(key: 'access_token');
  Future<String?> get role => _store.read(key: 'user_role');

  Future<void> save({required String token, required String role}) async {
    await _store.write(key: 'access_token', value: token);
    await _store.write(key: 'user_role', value: role);
  }

  Future<void> clear() async {
    await _store.delete(key: 'access_token');
    await _store.delete(key: 'user_role');
  }
}
