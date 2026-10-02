import 'dart:async';

import '../../domain/entities/app_user.dart';
import '../../domain/errors.dart';
import '../../domain/ports/auth_repository.dart';

// version de mentira. password correcto: "secret123".
// meError sirve para simular que el token vencio o que no hay red
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.saved});

  static const user = AppUser(
    id: 'user-1',
    email: 'laura@uniandes.edu.co',
    name: 'Laura Gomez',
  );

  AppUser? saved;
  Object? meError;
  final _expired = StreamController<void>.broadcast();

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    if (password != 'secret123') {
      throw const ApiException(401, 'Invalid credentials');
    }
    return saved = user;
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (email == user.email) {
      throw const ApiException(409, 'Email already registered');
    }
    return saved = AppUser(id: 'user-2', email: email, name: name);
  }

  @override
  Future<AppUser> me() async {
    final error = meError;
    if (error != null) throw error;
    final current = saved;
    if (current == null) throw const ApiException(401, 'Unauthorized');
    return current;
  }

  @override
  Future<AppUser?> cachedUser() async => saved;

  @override
  Future<void> logout() async => saved = null;

  @override
  Stream<void> get sessionExpired => _expired.stream;

  void expireSession() {
    saved = null;
    _expired.add(null);
  }
}
