import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/reservation_history_card.dart';
import '../../../domain/entities/app_user.dart';
import '../login/auth_view_model.dart';
import 'profile_view_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final profile = context.watch<ProfileViewModel>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: profile.load,
                child: ListView(
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
                    Text('RESERVATION HISTORY', style: AppTypography.overline),
                    const SizedBox(height: Spacing.sm),
                    if (profile.errorMessage != null) ...[
                      NoticeBanner(message: profile.errorMessage!),
                      const SizedBox(height: Spacing.sm),
                    ],
                    if (profile.isLoading && profile.history.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else
                      ReservationHistoryCard(reservations: profile.history),
                    const SizedBox(height: Spacing.lg),
                    OutlinedButton.icon(
                      onPressed: auth.logout,
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
            ),
          ],
        ),
      ),
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
