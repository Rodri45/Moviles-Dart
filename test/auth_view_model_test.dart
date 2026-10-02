import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/mock/mock_auth_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_telemetry.dart';
import 'package:parkwise/presentation/screens/login/auth_view_model.dart';

void main() {
  late MockAuthRepository repository;
  late MockTelemetry telemetry;
  late AuthViewModel auth;

  setUp(() {
    repository = MockAuthRepository();
    telemetry = MockTelemetry();
    auth = AuthViewModel(repository, telemetry);
  });

  tearDown(() => auth.dispose());

  group('login', () {
    test('valid credentials open the session', () async {
      auth
        ..setEmail('laura@uniandes.edu.co')
        ..setPassword('secret123');
      expect(auth.canLogin, isTrue);

      await auth.login();

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.user!.email, 'laura@uniandes.edu.co');
      expect(auth.errorMessage, isNull);
      expect(telemetry.named('app_opened').single, {'platform': 'android'});
    });

    test('wrong password shows an error and stays logged out', () async {
      auth
        ..setEmail('laura@uniandes.edu.co')
        ..setPassword('nope');

      await auth.login();

      expect(auth.status, isNot(AuthStatus.authenticated));
      expect(auth.errorMessage, 'Wrong email or password.');
      expect(auth.isLoading, isFalse);
    });

    test('an invalid email keeps the button disabled', () {
      auth
        ..setEmail('laura')
        ..setPassword('secret123');
      expect(auth.canLogin, isFalse);
    });
  });

  group('register', () {
    test('needs every field valid and matching passwords', () {
      auth
        ..setName('Laura')
        ..setEmail('new@uniandes.edu.co')
        ..setPassword('secret123')
        ..setConfirmPassword('secret12');
      expect(auth.canRegister, isFalse);

      auth.setConfirmPassword('secret123');
      expect(auth.canRegister, isTrue);

      auth.setPassword('123');
      expect(auth.canRegister, isFalse);
    });

    test('a registered email shows its own message', () async {
      auth
        ..setName('Laura')
        ..setEmail(MockAuthRepository.user.email)
        ..setPassword('secret123')
        ..setConfirmPassword('secret123');

      await auth.register();

      expect(auth.errorMessage, 'This email is already registered.');
    });
  });

  group('restore session', () {
    test('without a token goes to login', () async {
      await auth.restoreSession();
      expect(auth.status, AuthStatus.unauthenticated);
    });

    test('a valid token goes to home', () async {
      repository.saved = MockAuthRepository.user;

      await auth.restoreSession();

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.offlineSession, isFalse);
    });

    test('a 401 clears the session and goes to login', () async {
      repository
        ..saved = MockAuthRepository.user
        ..meError = const ApiException(401, 'Invalid token');

      await auth.restoreSession();

      expect(auth.status, AuthStatus.unauthenticated);
      expect(repository.saved, isNull);
    });

    test('without network uses the cached user', () async {
      repository
        ..saved = MockAuthRepository.user
        ..meError = const NetworkException('offline');

      await auth.restoreSession();

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.offlineSession, isTrue);
      expect(auth.user!.name, 'Laura Gomez');
    });

    test('a 401 on any later request sends the user back to login', () async {
      repository.saved = MockAuthRepository.user;
      await auth.restoreSession();

      repository.expireSession();
      await Future<void>.delayed(Duration.zero);

      expect(auth.status, AuthStatus.unauthenticated);
    });
  });
}
