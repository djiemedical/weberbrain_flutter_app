import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorage {
  final _storage = FlutterSecureStorage();

  Future<void> writeSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readSecureData(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteSecureData(String key) async {
    await _storage.delete(key: key);
  }

  Future<bool> containsKeyInSecureData(String key) async {
    return await _storage.containsKey(key: key);
  }

  Future<void> deleteAllSecureData() async {
    await _storage.deleteAll();
  }

  Future<void> writeSecureJson(String key, Map<String, dynamic> value) async {
    await _storage.write(key: key, value: json.encode(value));
  }

  Future<Map<String, dynamic>?> readSecureJson(String key) async {
    var readData = await _storage.read(key: key);
    if (readData != null) {
      return json.decode(readData);
    }
    return null;
  }
}
