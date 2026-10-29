import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../domain/services/register_rules.dart';
import '../login/auth_view_model.dart';
import '../login/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthViewModel>()..restoreRegisterDraft();
      _name.text = auth.name;
      _email.text = auth.email;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final showMismatch =
        auth.confirmPassword.isNotEmpty && !auth.passwordsMatch;
    final nameError = auth.name.isEmpty ? null : auth.nameProblem;
    final emailError = auth.isEmailValid ? auth.emailProblem : null;
    final passwordError = auth.password.isEmpty ? null : auth.passwordProblem;

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(backgroundColor: Palette.background),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            authFormSidePadding(context),
            0,
            authFormSidePadding(context),
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
            if (!auth.online) ...[
              const NoticeBanner(
                title: 'You\'re offline',
                message:
                    'Creating an account needs a connection. Your name and '
                    'email are saved on this phone, so you can finish when '
                    'the connection is back.',
                icon: Icons.cloud_off_outlined,
              ),
              const SizedBox(height: Spacing.md),
            ] else if (auth.hasRegisterDraft) ...[
              const NoticeBanner(
                message:
                    'We filled in the name and email you started before. '
                    'Choose a password to finish.',
                icon: Icons.restore,
              ),
              const SizedBox(height: Spacing.md),
            ],
            if (auth.errorMessage != null) ...[
              NoticeBanner(
                message: auth.errorMessage!,
                tone: NoticeTone.danger,
                icon: Icons.error_outline,
              ),
              const SizedBox(height: Spacing.md),
            ],
            TextField(
              controller: _name,
              onChanged: auth.setName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: RegisterRules.nameMaxLength,
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: nameError,
                errorMaxLines: 2,
                counterText: '',
              ),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _email,
              onChanged: auth.setEmail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              maxLength: AuthViewModel.emailMaxLength,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              decoration: InputDecoration(
                labelText: 'Email',
                helperText:
                    'Gmail, Outlook, Hotmail, Live, Yahoo, iCloud, Proton or '
                    'Uniandes',
                helperMaxLines: 2,
                errorText: emailError,
                errorMaxLines: 2,
                counterText: '',
              ),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              onChanged: auth.setPassword,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              maxLength: AuthViewModel.passwordMaxLength,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText:
                    '8 to 64 characters with an uppercase letter, a '
                    'lowercase letter, a number and a symbol',
                helperMaxLines: 3,
                errorText: passwordError,
                counterText: '',
              ),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              onChanged: auth.setConfirmPassword,
              obscureText: true,
              maxLength: AuthViewModel.passwordMaxLength,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                errorText: showMismatch ? 'Passwords don\'t match' : null,
                counterText: '',
              ),
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: auth.canRegister ? auth.register : null,
              child: auth.isLoading
                  ? const ButtonSpinner()
                  : Text(
                      auth.online ? 'Create account' : 'Waiting for connection',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
