import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/format.dart';
import '../../../core/widgets/header_scroll_view.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/reservation_history_card.dart';
import '../../../domain/entities/app_user.dart';
import '../../shared/arrival_question_card.dart';
import '../../shared/pending_actions_banner.dart';
import '../login/auth_view_model.dart';
import 'profile_view_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, int pending) async {
    final auth = context.read<AuthViewModel>();
    if (pending > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _LogoutDialog(pending: pending),
      );
      if (confirmed != true) return;
    }
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final profile = context.watch<ProfileViewModel>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: HeaderScrollView(
          header: const _Header(),
          onRefresh: profile.load,
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.lg,
            Spacing.md,
            Spacing.lg,
          ),
          children: [
            if (user != null)
              _UserCard(user: user, offline: auth.offlineSession),
            const SizedBox(height: Spacing.lg),
            const ArrivalQuestionCard(),
            Text('RESERVATION HISTORY', style: AppTypography.overline),
            const SizedBox(height: Spacing.sm),
            if (profile.historyFromCache) ...[
              NoticeBanner(
                title: 'Saved on this phone',
                message: _savedHistoryMessage(profile.historySavedAt),
                icon: Icons.history,
              ),
              const SizedBox(height: Spacing.sm),
            ],
            if (profile.errorMessage != null) ...[
              NoticeBanner(message: profile.errorMessage!),
              const SizedBox(height: Spacing.sm),
            ],
            if (profile.isLoading && profile.history.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              ReservationHistoryCard(reservations: profile.history),
            const SizedBox(height: Spacing.lg),
            if (profile.pendingActions > 0) ...[
              PendingActionsBanner(count: profile.pendingActions),
              const SizedBox(height: Spacing.md),
            ],
            OutlinedButton.icon(
              onPressed: () => _logout(context, profile.pendingActions),
              style: OutlinedButton.styleFrom(
                foregroundColor: Palette.danger,
                side: const BorderSide(color: Palette.danger),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}

String _savedHistoryMessage(DateTime? savedAt) {
  if (savedAt == null) return 'It updates when you\'re back online.';
  return 'Updated ${formatDate(savedAt)} at ${formatTime(savedAt)}. '
      'It updates when you\'re back online.';
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog({required this.pending});

  final int pending;

  @override
  Widget build(BuildContext context) {
    final actions = pending == 1 ? '1 action is' : '$pending actions are';
    return AlertDialog(
      title: const Text('Log out now?'),
      content: Text(
        '$actions still waiting for signal. Logging out deletes them from '
        'this phone, so they will never reach ParkWise.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Stay'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Palette.danger),
          child: const Text('Log out'),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Palette.surface,
        border: Border(bottom: BorderSide(color: Palette.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.lg,
        Spacing.md,
        Spacing.md,
      ),
      child: Text('Profile', style: AppTypography.display),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.offline});

  final AppUser user;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Palette.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                user.initials,
                style: AppTypography.heading1.copyWith(
                  color: Palette.textOnPrimary,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    offline ? '${user.email} · offline' : user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
