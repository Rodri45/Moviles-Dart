import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/app_user.dart';
import '../../../domain/errors.dart';
import '../../../domain/ports/auth_repository.dart';
import '../../../domain/ports/connectivity_port.dart';
import '../../../domain/ports/form_draft_store.dart';
import '../../../domain/ports/telemetry.dart';
import '../../shared/connectivity_aware.dart';
import '../../shared/error_messages.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier with ConnectivityAware {
  AuthViewModel(
    this._repository,
    this._telemetry, {
    ConnectivityPort? connectivity,
    this._drafts,
    this._onSignedOut,
    this.sessionRetryEvery = const Duration(seconds: 30),
  }) {
    _expiredSub = _repository.sessionExpired.listen((_) => _signOut());
    if (connectivity != null) watchConnectivity(connectivity, _confirmSession);
  }

  static const registerDraft = 'register';

  final AuthRepository _repository;
  final Telemetry _telemetry;
  final FormDraftStore? _drafts;
  final Future<void> Function()? _onSignedOut;
  bool _draftingRegister = false;
  bool _openReported = false;
  late final StreamSubscription<void> _expiredSub;
  Timer? _sessionRetry;

  final Duration sessionRetryEvery;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  bool isLoading = false;
  String? errorMessage;

  bool offlineSession = false;

  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';

  static const nameMaxLength = 50;
  static const emailMaxLength = 100;
  static const passwordMinLength = 6;
  static const passwordMaxLength = 64;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool get isEmailValid =>
      email.trim().length <= emailMaxLength &&
      _emailPattern.hasMatch(email.trim());
  bool get isPasswordLongEnough => password.length >= passwordMinLength;
  bool get isPasswordShortEnough => password.length <= passwordMaxLength;
  bool get passwordsMatch => password == confirmPassword;

  bool get canLogin =>
      !isLoading &&
      online &&
      isEmailValid &&
      password.isNotEmpty &&
      isPasswordShortEnough;

  bool hasRegisterDraft = false;

  bool get canRegister =>
      !isLoading &&
      online &&
      name.trim().isNotEmpty &&
      name.trim().length <= nameMaxLength &&
      isEmailValid &&
      isPasswordLongEnough &&
      isPasswordShortEnough &&
      passwordsMatch;

  void setName(String value) => _edit(() => name = value);
  void setEmail(String value) => _edit(() => email = value);
  void setPassword(String value) => _edit(() => password = value);
  void setConfirmPassword(String value) => _edit(() => confirmPassword = value);

  void resetForm() {
    name = email = password = confirmPassword = '';
    errorMessage = null;
    _draftingRegister = false;
    hasRegisterDraft = false;
    notifyListeners();
  }

  void restoreRegisterDraft() {
    _draftingRegister = true;
    final draft = _drafts?.read(registerDraft) ?? const {};
    name = draft['name'] ?? name;
    email = draft['email'] ?? email;
    hasRegisterDraft = draft.isNotEmpty;
    notifyListeners();
  }

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
    } catch (_) {
      _openOffline(cached);
    }
  }

  Future<void> login() =>
      _submit(() => _repository.login(email: email.trim(), password: password));

  Future<void> register() async {
    await _submit(
      () => _repository.register(
        name: name.trim(),
        email: email.trim(),
        password: password,
      ),
    );
    if (status == AuthStatus.authenticated) {
      _draftingRegister = false;
      hasRegisterDraft = false;
      await _drafts?.clear(registerDraft);
    }
  }

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
    _sessionRetry?.cancel();
    _sessionRetry = Timer.periodic(sessionRetryEvery, (_) {
      if (online) _confirmSession();
    });
    _setStatus(AuthStatus.authenticated);
  }

  Future<void> _confirmSession() async {
    if (!offlineSession) return;
    try {
      user = await _repository.me();
      offlineSession = false;
      _sessionRetry?.cancel();
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode != 401) return;
      await _repository.logout();
      _signOut();
    } catch (e) {
      debugPrint('session check failed: $e');
    }
  }

  void _signOut() {
    user = null;
    offlineSession = false;
    _sessionRetry?.cancel();
    _openReported = false;
    final cleanup = _onSignedOut;
    if (cleanup != null) unawaited(cleanup());
    _setStatus(AuthStatus.unauthenticated);
  }

  void _setStatus(AuthStatus value) {
    status = value;
    if (value == AuthStatus.authenticated) _reportOpen();
    notifyListeners();
  }

  void _reportOpen() {
    if (_openReported) return;
    _openReported = true;
    _telemetry.track('app_opened');
  }

  void _edit(VoidCallback change) {
    change();
    errorMessage = null;
    if (_draftingRegister) {
      unawaited(
        _drafts?.save(registerDraft, {'name': name, 'email': email}),
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _expiredSub.cancel();
    _sessionRetry?.cancel();
    super.dispose();
  }
}
