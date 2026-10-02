import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/app_user.dart';

class SessionStore {
  SessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final FlutterSecureStorage _storage;
  String? _token;
  AppUser? _user;

  String? get token => _token;
  AppUser? get user => _user;

  Future<void> load() async {
    _token = await _storage.read(key: _tokenKey);
    final raw = await _storage.read(key: _userKey);
    _user = raw == null
        ? null
        : AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(String token, AppUser user) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
    await saveUser(user);
  }

  Future<void> saveUser(AppUser user) async {
    _user = user;
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    _token = null;
    _user = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
