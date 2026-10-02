import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/notice_banner.dart';
import '../login/auth_view_model.dart';
import '../login/login_screen.dart';

// registro: nombre, email, contraseña y confirmacion. el boton queda
// apagado hasta que todo es valido
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  static const String routeName = '/register';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final showMismatch =
        auth.confirmPassword.isNotEmpty && !auth.passwordsMatch;
    final showShort = auth.password.isNotEmpty && !auth.isPasswordLongEnough;

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(backgroundColor: Palette.background),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            0,
            Spacing.md,
            Spacing.lg,
          ),
          children: [
            const AuthBrand(),
            const SizedBox(height: Spacing.lg),
            Text('Create account', style: AppTypography.display),
            const SizedBox(height: Spacing.xs),
            Text(
              'Your reservations sync with the iOS app too.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: Spacing.lg),
            if (auth.errorMessage != null) ...[
              NoticeBanner(
                message: auth.errorMessage!,
                tone: NoticeTone.danger,
                icon: Icons.error_outline,
              ),
              const SizedBox(height: Spacing.md),
            ],
            TextField(
              onChanged: auth.setName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Name',
                counterText: '',
              ),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              onChanged: auth.setEmail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              onChanged: auth.setPassword,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'At least 6 characters',
                errorText: showShort ? 'At least 6 characters' : null,
              ),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              onChanged: auth.setConfirmPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                errorText: showMismatch ? 'Passwords don\'t match' : null,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: auth.canRegister ? auth.register : null,
              child: auth.isLoading
                  ? const ButtonSpinner()
                  : const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
