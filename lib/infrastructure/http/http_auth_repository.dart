import 'dart:async';

import '../../domain/entities/app_user.dart';
import '../../domain/ports/auth_repository.dart';
import '../storage/local_cache.dart';
import '../storage/session_store.dart';
import 'api_client.dart';

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._client, this._session, this._cache) {
    _client.onUnauthorized = _expire;
  }

  final ApiClient _client;
  final SessionStore _session;

  final LocalCache _cache;
  final _expired = StreamController<void>.broadcast();

  @override
  Future<AppUser> login({required String email, required String password}) =>
      _authenticate('/auth/login', {'email': email, 'password': password});

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) => _authenticate('/auth/register', {
    'name': name,
    'email': email,
    'password': password,
  });

  @override
  Future<AppUser> me() async {
    final json = await _client.get('/auth/me') as Map<String, dynamic>;
    final user = AppUser.fromJson(json);
    await _session.saveUser(user);
    return user;
  }

  @override
  Future<AppUser?> cachedUser() async =>
      _session.token == null ? null : _session.user;

  @override
  Future<void> logout() async {
    await _session.clear();
    await _cache.clear();
  }

  @override
  Stream<void> get sessionExpired => _expired.stream;

  Future<AppUser> _authenticate(String path, Map<String, String> body) async {
    final json = await _client.post(path, body: body) as Map<String, dynamic>;
    final user = AppUser.fromJson(json['user'] as Map<String, dynamic>);
    await _session.save(json['token'] as String, user);
    return user;
  }

  Future<void> _expire() async {
    await logout();
    _expired.add(null);
  }
}
