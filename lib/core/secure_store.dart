import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ledger.dart';

class SecureKv implements KvStore {
  SecureKv([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
}
