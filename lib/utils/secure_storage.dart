import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorage {
  final _storage = FlutterSecureStorage();

  Future<void> writeSecureData(String key, String value) async {
    var writeData = await _storage.write(key: key, value: value);
    return writeData;
  }

  Future<String?> readSecureData(String key) async {
    var readData = await _storage.read(key: key);
    return readData;
  }

  Future<void> deleteSecureData(String key) async {
    var deleteData = await _storage.delete(key: key);
    return deleteData;
  }

  Future<bool> containsKeyInSecureData(String key) async {
    var containsKey = await _storage.containsKey(key: key);
    return containsKey;
  }

  Future<void> deleteAllSecureData() async {
    var deleteAll = await _storage.deleteAll();
    return deleteAll;
  }

  Future<void> writeSecureJson(String key, Map<String, dynamic> value) async {
    var writeData = await _storage.write(key: key, value: json.encode(value));
    return writeData;
  }

  Future<Map<String, dynamic>?> readSecureJson(String key) async {
    var readData = await _storage.read(key: key);
    if (readData != null) {
      return json.decode(readData);
    }
    return null;
  }
}
