import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/notice_banner.dart';
import '../register/register_screen.dart';
import 'auth_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  Future<void> _openRegister() async {
    final auth = context.read<AuthViewModel>()..resetForm();
    await Navigator.of(context).pushNamed(RegisterScreen.routeName);
    if (!mounted) return;
    _email.clear();
    _password.clear();
    auth.resetForm();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.xl,
            Spacing.md,
            Spacing.lg,
          ),
          children: [
            const AuthBrand(),
            const SizedBox(height: Spacing.xl),
            Text('Log in', style: AppTypography.display),
            const SizedBox(height: Spacing.xs),
            Text(
              'Use your account to find and reserve a spot.',
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
              controller: _email,
              onChanged: auth.setEmail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _password,
              onChanged: auth.setPassword,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => auth.canLogin ? auth.login() : null,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: auth.canLogin ? auth.login : null,
              child: auth.isLoading
                  ? const ButtonSpinner()
                  : const Text('Log in'),
            ),
            const SizedBox(height: Spacing.sm),
            OutlinedButton(
              onPressed: auth.isLoading ? null : _openRegister,
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Palette.primary,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Text(
            'P',
            style: AppTypography.heading1.copyWith(
              color: Palette.textOnPrimary,
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            'ParkWise',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.heading1,
          ),
        ),
      ],
    );
  }
}
