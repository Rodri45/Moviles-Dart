import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> login({required String email, required String password});

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUser> me();

  Future<AppUser?> cachedUser();

  Future<void> logout();

  Stream<void> get sessionExpired;
}
