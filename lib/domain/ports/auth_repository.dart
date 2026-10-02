import '../entities/app_user.dart';

// interfaz para entrar, registrarse y cerrar sesion
abstract interface class AuthRepository {
  Future<AppUser> login({required String email, required String password});

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  // valida el token guardado contra el backend
  Future<AppUser> me();

  // el usuario guardado si hay token, sin tocar la red
  Future<AppUser?> cachedUser();

  Future<void> logout();

  // avisa cuando el backend rechaza el token en cualquier peticion
  Stream<void> get sessionExpired;
}
