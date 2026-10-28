import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/mock/mock_auth_repository.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/infrastructure/mock/mock_form_draft_store.dart';
import 'package:parkwise/infrastructure/mock/mock_telemetry.dart';
import 'package:parkwise/presentation/screens/login/auth_view_model.dart';

void main() {
  late MockConnectivity connectivity;
  late MockFormDraftStore drafts;
  late AuthViewModel auth;

  setUp(() {
    connectivity = MockConnectivity();
    drafts = MockFormDraftStore();
    auth = AuthViewModel(
      MockAuthRepository(),
      MockTelemetry(),
      connectivity: connectivity,
      drafts: drafts,
    );
  });

  tearDown(() => auth.dispose());

  test('offline the login button stays off and turns on when back', () async {
    auth
      ..setEmail('laura@uniandes.edu.co')
      ..setPassword('secret123');
    expect(auth.canLogin, isTrue);

    connectivity.setOnline(false);
    await Future<void>.delayed(Duration.zero);
    expect(auth.canLogin, isFalse);
    expect(auth.email, 'laura@uniandes.edu.co');

    connectivity.setOnline(true);
    await Future<void>.delayed(Duration.zero);
    expect(auth.canLogin, isTrue);
  });

  test('the register draft keeps name and email but never the password', () {
    auth
      ..restoreRegisterDraft()
      ..setName('Laura')
      ..setEmail('laura@uniandes.edu.co')
      ..setPassword('secret123')
      ..setConfirmPassword('secret123');

    expect(drafts.read(AuthViewModel.registerDraft), {
      'name': 'Laura',
      'email': 'laura@uniandes.edu.co',
    });
  });

  test('reopening the register screen fills the saved draft', () async {
    await drafts.save(AuthViewModel.registerDraft, {
      'name': 'Laura',
      'email': 'laura@uniandes.edu.co',
    });

    auth
      ..resetForm()
      ..restoreRegisterDraft();

    expect(auth.name, 'Laura');
    expect(auth.email, 'laura@uniandes.edu.co');
    expect(auth.hasRegisterDraft, isTrue);
  });

  test('typing in the login form does not touch the register draft', () {
    auth
      ..resetForm()
      ..setEmail('other@uniandes.edu.co');

    expect(drafts.read(AuthViewModel.registerDraft), isEmpty);
  });

  test('a successful register deletes the draft', () async {
    auth
      ..restoreRegisterDraft()
      ..setName('Laura')
      ..setEmail('new.user@uniandes.edu.co')
      ..setPassword('secret123')
      ..setConfirmPassword('secret123');

    await auth.register();

    expect(auth.status, AuthStatus.authenticated);
    expect(drafts.read(AuthViewModel.registerDraft), isEmpty);
  });

  test('an offline session is confirmed when the signal returns', () async {
    final repository = MockAuthRepository(saved: MockAuthRepository.user)
      ..meError = const NetworkException('offline');
    final session = AuthViewModel(
      repository,
      MockTelemetry(),
      connectivity: connectivity,
    );
    addTearDown(session.dispose);

    await session.restoreSession();
    expect(session.offlineSession, isTrue);

    repository.meError = null;
    connectivity.setOnline(false);
    await Future<void>.delayed(Duration.zero);
    connectivity.setOnline(true);
    await Future<void>.delayed(Duration.zero);

    expect(session.offlineSession, isFalse);
    expect(session.user, MockAuthRepository.user);
  });

  test('the session is checked again until the server answers', () async {
    final repository = MockAuthRepository(saved: MockAuthRepository.user)
      ..meError = const NetworkException('server_unreachable');
    final session = AuthViewModel(
      repository,
      MockTelemetry(),
      connectivity: connectivity,
      sessionRetryEvery: const Duration(milliseconds: 10),
    );
    addTearDown(session.dispose);

    await session.restoreSession();
    expect(session.offlineSession, isTrue);

    repository.meError = null;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(session.offlineSession, isFalse);
  });

  test('a session the server rejects is closed on the next check', () async {
    final repository = MockAuthRepository(saved: MockAuthRepository.user)
      ..meError = const NetworkException('offline');
    final session = AuthViewModel(
      repository,
      MockTelemetry(),
      connectivity: connectivity,
    );
    addTearDown(session.dispose);

    await session.restoreSession();
    repository.meError = const ApiException(401, 'Unauthorized');
    connectivity.setOnline(false);
    await Future<void>.delayed(Duration.zero);
    connectivity.setOnline(true);
    await Future<void>.delayed(Duration.zero);

    expect(session.status, AuthStatus.unauthenticated);
  });
}
