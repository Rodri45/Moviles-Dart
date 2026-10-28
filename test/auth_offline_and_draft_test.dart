import 'package:flutter_test/flutter_test.dart';
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
}
