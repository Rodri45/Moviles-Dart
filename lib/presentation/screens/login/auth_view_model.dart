import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/app_user.dart';
import '../../../domain/errors.dart';
import '../../../domain/ports/auth_repository.dart';
import '../../../domain/ports/telemetry.dart';
import '../../shared/error_messages.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

// estado de la sesion y de los formularios de login y registro
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository, this._telemetry) {
    _expiredSub = _repository.sessionExpired.listen((_) => _signOut());
  }

  final AuthRepository _repository;
  final Telemetry _telemetry;
  bool _openReported = false;
  late final StreamSubscription<void> _expiredSub;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  bool isLoading = false;
  String? errorMessage;

  // true si se abrio con el usuario guardado porque no habia red
  bool offlineSession = false;

  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool get isEmailValid => _emailPattern.hasMatch(email.trim());
  bool get isPasswordLongEnough => password.length >= 6;
  bool get passwordsMatch => password == confirmPassword;

  bool get canLogin => !isLoading && isEmailValid && password.isNotEmpty;

  bool get canRegister =>
      !isLoading &&
      name.trim().isNotEmpty &&
      name.trim().length <= 80 &&
      isEmailValid &&
      isPasswordLongEnough &&
      password.length <= 128 &&
      passwordsMatch;

  void setName(String value) => _edit(() => name = value);
  void setEmail(String value) => _edit(() => email = value);
  void setPassword(String value) => _edit(() => password = value);
  void setConfirmPassword(String value) => _edit(() => confirmPassword = value);

  void resetForm() {
    name = email = password = confirmPassword = '';
    errorMessage = null;
    notifyListeners();
  }

  // al abrir la app: con token se valida, sin red se usa el usuario guardado
  Future<void> restoreSession() async {
    final cached = await _repository.cachedUser();
    if (cached == null) return _setStatus(AuthStatus.unauthenticated);

    try {
      user = await _repository.me();
      offlineSession = false;
      _setStatus(AuthStatus.authenticated);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _repository.logout();
        return _signOut();
      }
      _openOffline(cached);
    } on NetworkException {
      _openOffline(cached);
    }
  }

  Future<void> login() =>
      _submit(() => _repository.login(email: email.trim(), password: password));

  Future<void> register() => _submit(
    () => _repository.register(
      name: name.trim(),
      email: email.trim(),
      password: password,
    ),
  );

  Future<void> logout() async {
    await _repository.logout();
    _signOut();
  }

  Future<void> _submit(Future<AppUser> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      user = await action();
      offlineSession = false;
      name = email = password = confirmPassword = '';
      status = AuthStatus.authenticated;
      _reportOpen();
    } catch (e) {
      errorMessage = messageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static String messageFor(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          return 'Wrong email or password.';
        case 409:
          return 'This email is already registered.';
        case 429:
          return 'Too many attempts. Wait a minute and try again.';
        case 400:
          return 'Check your data and try again.';
      }
    }
    return errorMessageFor(error);
  }

  void _openOffline(AppUser cached) {
    user = cached;
    offlineSession = true;
    _setStatus(AuthStatus.authenticated);
  }

  void _signOut() {
    user = null;
    offlineSession = false;
    _setStatus(AuthStatus.unauthenticated);
  }

  void _setStatus(AuthStatus value) {
    status = value;
    if (value == AuthStatus.authenticated) _reportOpen();
    notifyListeners();
  }

  // BQ3 cuenta usuarios activos con app_opened, por eso se manda ya con token
  void _reportOpen() {
    if (_openReported) return;
    _openReported = true;
    _telemetry.track('app_opened', {'platform': 'android'});
  }

  void _edit(VoidCallback change) {
    change();
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _expiredSub.cancel();
    super.dispose();
  }
}
