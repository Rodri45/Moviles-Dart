import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/palette.dart';
import '../../core/widgets/app_tab_bar.dart';
import '../screens/login/auth_view_model.dart';
import '../screens/login/login_screen.dart';
import '../screens/reserve/reserve_view_model.dart';
import 'main_shell.dart';
import 'shell_view_model.dart';

// lo primero que sale: mientras revisa la sesion muestra un loader y
// despues manda a login o a la app
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthViewModel _auth;
  late AuthStatus _lastStatus;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _lastStatus = _auth.status;
    _auth.addListener(_onAuthChanged);
    _auth.restoreSession();
  }

  // al entrar o salir se cierran las pantallas que hubiera encima
  // (registro, reserva, etc) para que quede solo login o la app
  void _onAuthChanged() {
    if (_auth.status == _lastStatus || !mounted) return;
    _lastStatus = _auth.status;
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.read<ShellViewModel>().open(AppTab.home);
    // que la siguiente cuenta no vea la reserva de la anterior
    if (_auth.status == AuthStatus.unauthenticated) {
      context.read<ReserveViewModel>().reset();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (context.watch<AuthViewModel>().status) {
      AuthStatus.unknown => const Scaffold(
        backgroundColor: Palette.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.authenticated => const MainShell(),
    };
  }
}
