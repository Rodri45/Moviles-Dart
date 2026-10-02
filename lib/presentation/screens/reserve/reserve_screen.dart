import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/format.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/reservation_history_card.dart';
import '../../shared/location_rationale.dart';
import '../../shell/main_shell.dart';
import '../find_my_car/find_my_car_screen.dart';
import '../find_spot/find_spot_screen.dart';
import 'reserve_view_model.dart';

// pantalla 4, reserve. la card del puesto con el circulo del tiempo, el
// aviso amarillo de cuando reservar y abajo el historial
class ReserveScreen extends StatelessWidget {
  const ReserveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reserve = context.watch<ReserveViewModel>();

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(reserve: reserve),
            Expanded(
              child: RefreshIndicator(
                onRefresh: reserve.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.lg,
                    Spacing.md,
                    Spacing.lg,
                  ),
                  children: [
                    if (reserve.errorMessage != null) ...[
                      NoticeBanner(
                        message: reserve.errorMessage!,
                        tone: NoticeTone.danger,
                        icon: Icons.error_outline,
                      ),
                      const SizedBox(height: Spacing.md),
                    ],
                    _SpotCard(reserve: reserve),
                    const SizedBox(height: Spacing.md),
                    NoticeBanner(
                      title: 'Best time to reserve',
                      message:
                          reserve.advice?.message ??
                          'Reserve when you are about ${reserve.holdMinutes} '
                              'minutes away so you arrive before the hold '
                              'expires.',
                    ),
                    const SizedBox(height: Spacing.lg),
                    Text('Compliance history', style: AppTypography.heading1),
                    const SizedBox(height: Spacing.sm),
                    ReservationHistoryCard(reservations: reserve.history),
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

// titulo de arriba

class _Header extends StatelessWidget {
  const _Header({required this.reserve});

  final ReserveViewModel reserve;

  String get _subtitle {
    final reservation = reserve.reservation;
    if (reservation != null) {
      return 'Level ${reservation.levelCode} · Spot ${reservation.spotCode}';
    }
    final spot = reserve.pendingSpot;
    if (spot != null) return 'Level ${spot.levelCode} · Zone ${spot.zone}';
    return 'Pick a spot on the map';
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reserve spot', style: AppTypography.display),
          const SizedBox(height: Spacing.xs),
          Text(
            _subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(color: Palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

// la card grande con el puesto, el circulo y los botones. cambia segun si
// no hay nada, hay un puesto elegido, una reserva activa o ya parqueo

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.reserve});

  final ReserveViewModel reserve;

  // antes del dialogo del sistema se explica para que sirve el gps
  Future<void> _checkIn(BuildContext context) async {
    if (await reserve.shouldExplainLocation() && context.mounted) {
      final allow = await showLocationRationale(context);
      if (allow) await reserve.requestLocation();
    }
    await reserve.checkIn();
  }

  @override
  Widget build(BuildContext context) {
    final reservation = reserve.reservation;
    final spot = reserve.pendingSpot;

    if (reservation == null && spot == null) return const _EmptyCard();

    final String code;
    final String detail;
    final Widget ring;
    final List<Widget> actions;

    if (reservation != null && reserve.isParked) {
      code = reservation.spotCode;
      detail = 'Parked since ${formatTime(reservation.checkedInAt!)}';
      ring = const _HoldTimeRing(
        label: 'P',
        caption: 'parked',
        color: Palette.success,
      );
      actions = [
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context).pushNamed(FindMyCarScreen.routeName),
          child: const Text('Find my car'),
        ),
        _ActionButton(
          label: 'I left',
          busy: reserve.isBusy,
          onPressed: reserve.release,
        ),
      ];
    } else if (reservation != null) {
      final remaining = reserve.remaining;
      code = reservation.spotCode;
      detail =
          'Level ${reservation.levelCode} · expires '
          '${formatTime(reservation.expiresAt)}';
      ring = _HoldTimeRing(
        label: formatCountdown(remaining),
        caption: 'hold time left',
        color: remaining <= ReserveViewModel.warnBefore
            ? Palette.warning
            : Palette.primary,
      );
      actions = [
        _ActionButton(
          label: 'I parked',
          busy: reserve.isBusy,
          onPressed: () => _checkIn(context),
        ),
        OutlinedButton(
          onPressed: reserve.isBusy ? null : reserve.release,
          child: const Text('Cancel reservation'),
        ),
      ];
    } else {
      code = spot!.code;
      detail =
          'Level ${spot.levelCode} · Zone ${spot.zone} · '
          '${spot.walkMinutes} min walk';
      ring = _HoldTimeRing(
        label: formatCountdown(Duration(minutes: reserve.holdMinutes)),
        caption: 'hold time',
        color: Palette.primary,
      );
      actions = [
        _ActionButton(
          label: 'Confirm reservation',
          busy: reserve.isBusy,
          onPressed: reserve.confirm,
        ),
      ];
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Spacing.sm),
                      Text('SPOT', style: AppTypography.overline),
                      const SizedBox(height: Spacing.xs),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(code, style: AppTypography.monoDisplay),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.md),
                ring,
              ],
            ),
            const SizedBox(height: Spacing.lg),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: Spacing.sm),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }
}

// cuando todavia no han elegido puesto
class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('No spot selected', style: AppTypography.heading1),
            const SizedBox(height: Spacing.xs),
            Text(
              'Choose a free spot on the map or search one to reserve it.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: Spacing.md),
            FilledButton(
              onPressed: () => MainShell.openTab(context, AppTab.map),
              child: const Text('Open map'),
            ),
            const SizedBox(height: Spacing.sm),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(FindSpotScreen.routeName),
              child: const Text('Find a spot'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy ? const ButtonSpinner() : Text(label),
    );
  }
}

// el circulo con el tiempo que queda adentro
class _HoldTimeRing extends StatelessWidget {
  const _HoldTimeRing({
    required this.label,
    required this.caption,
    required this.color,
  });

  final String label;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 5),
          ),
          child: Text(label, style: AppTypography.monoCountdown),
        ),
        const SizedBox(height: Spacing.sm),
        Text(caption, style: AppTypography.caption),
      ],
    );
  }
}
