import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/format.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/forecast_card.dart';
import '../../../core/widgets/level_card.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/pill.dart';
import '../../../domain/entities/app_user.dart';
import '../../shell/main_shell.dart';
import '../find_my_car/find_my_car_screen.dart';
import '../find_spot/find_spot_screen.dart';
import '../level_map/level_map_view_model.dart';
import '../login/auth_view_model.dart';
import '../no_spots/no_spots_screen.dart';
import '../offline/offline_screen.dart';
import 'home_view_model.dart';

// pantalla 1, home: saludo, destino, pronostico, niveles y accesos rapidos
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _home;

  @override
  void initState() {
    super.initState();
    _home = context.read<HomeViewModel>()..addListener(_openNoSpotsIfFull);
    WidgetsBinding.instance.addPostFrameCallback((_) => _home.load());
  }

  // cuando el backend dice campusFull se abre la pantalla de no_spots una vez
  void _openNoSpotsIfFull() {
    if (!_home.campusFullPending || !mounted) return;
    _home.campusFullHandled();
    Navigator.of(context).pushNamed(NoSpotsScreen.routeName);
  }

  @override
  void dispose() {
    _home.removeListener(_openNoSpotsIfFull);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeViewModel>();
    final user = context.watch<AuthViewModel>().user;
    final levels = home.levels;

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: home.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.md,
              Spacing.md,
              Spacing.lg,
            ),
            children: [
              _Greeting(user: user, hour: home.currentHour),
              if (home.showOffline) ...[
                const SizedBox(height: Spacing.md),
                OfflineBanner(
                  savedAt: levels?.savedAt,
                  online: home.online,
                  onTap: () =>
                      Navigator.of(context).pushNamed(OfflineScreen.routeName),
                ),
              ],
              if (home.errorMessage != null && levels == null) ...[
                const SizedBox(height: Spacing.md),
                NoticeBanner(
                  message: home.errorMessage!,
                  tone: NoticeTone.danger,
                  icon: Icons.error_outline,
                ),
              ],
              const SizedBox(height: Spacing.lg),
              Text('DESTINATION', style: AppTypography.overline),
              const SizedBox(height: Spacing.sm),
              _DestinationPills(home: home),
              const SizedBox(height: Spacing.md),
              ForecastCard(
                hours: home.forecast,
                currentHour: home.currentHour,
                live: !home.showOffline,
              ),
              const SizedBox(height: Spacing.lg),
              Text('PARKING LEVELS', style: AppTypography.overline),
              const SizedBox(height: Spacing.sm),
              _ArrivalCard(home: home),
              const SizedBox(height: Spacing.sm),
              if (levels == null && home.isLoading)
                const Padding(
                  padding: EdgeInsets.all(Spacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              for (final level in levels?.data.levels ?? const []) ...[
                LevelCard(
                  level: level,
                  recommended: level.code == home.recommendation?.recommended,
                  onTap: () {
                    context.read<LevelMapViewModel>().selectLevel(level.code);
                    MainShell.openTab(context, AppTab.map);
                  },
                ),
                const SizedBox(height: Spacing.sm),
              ],
              const SizedBox(height: Spacing.sm),
              const _QuickActions(),
            ],
          ),
        ),
      ),
    );
  }
}

// saludo + avatar

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user, required this.hour});

  final AppUser? user;
  final int hour;

  String get _greeting {
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting, style: AppTypography.caption),
              const SizedBox(height: 2),
              Text(
                user?.displayName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display,
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacing.md),
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Palette.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            user?.initials ?? '',
            style: AppTypography.heading2.copyWith(
              color: Palette.textOnPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// pills de destino (scroll horizontal)

class _DestinationPills extends StatelessWidget {
  const _DestinationPills({required this.home});

  final HomeViewModel home;

  @override
  Widget build(BuildContext context) {
    if (home.buildings.isEmpty) {
      return Text('Destinations unavailable', style: AppTypography.caption);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final building in home.buildings) ...[
            Pill(
              label: building.name,
              selected: building.id == home.destination,
              onTap: () => home.selectDestination(building.id),
            ),
            const SizedBox(width: Spacing.sm),
          ],
        ],
      ),
    );
  }
}

// la hora de llegada y el nivel que recomienda el backend para esa hora

class _ArrivalCard extends StatelessWidget {
  const _ArrivalCard({required this.home});

  final HomeViewModel home;

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(home.arrivalAt),
    );
    if (picked != null) await home.setArrivalTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final best = home.recommendation?.recommended;
    final body = AppTypography.caption;
    final bold = body.copyWith(
      color: Palette.textPrimary,
      fontWeight: FontWeight.w600,
    );

    return Card(
      child: InkWell(
        onTap: () => _pickTime(context),
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Palette.primary),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: body,
                    children: [
                      const TextSpan(text: 'Arriving '),
                      TextSpan(text: formatTime(home.arrivalAt), style: bold),
                      TextSpan(
                        text: best == null ? ' · no history yet' : ' · best ',
                      ),
                      if (best != null) TextSpan(text: best, style: bold),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'Change',
                style: AppTypography.button.copyWith(color: Palette.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// acciones rapidas

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.search,
            label: 'Find a spot',
            color: Palette.primary,
            background: Palette.primarySoft,
            onTap: () =>
                Navigator.of(context).pushNamed(FindSpotScreen.routeName),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.directions_car_outlined,
            label: 'Find my car',
            color: Palette.secondary,
            background: Palette.secondarySoft,
            onTap: () =>
                Navigator.of(context).pushNamed(FindMyCarScreen.routeName),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
