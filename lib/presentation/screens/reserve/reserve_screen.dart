import 'package:flutter/material.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_tab_bar.dart';

// pantalla 4, reserve. solo es la vista, el boton de confirmar no hace nada
// tiene la card del puesto con el circulo del tiempo, el aviso amarillo
// y abajo el historial
class ReserveScreen extends StatelessWidget {
  const ReserveScreen({super.key});

  static const String routeName = '/reserve';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                ),
                children: [
                  const _SpotCard(),
                  const SizedBox(height: Spacing.md),
                  const _BestTimeBanner(),
                  const SizedBox(height: Spacing.lg),
                  Text('Compliance history', style: AppTypography.heading1),
                  const SizedBox(height: Spacing.sm),
                  const _ComplianceCard(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppTabBar(current: AppTab.reserve),
    );
  }
}

// datos de mentira para el historial

typedef _HistoryRow = ({String spot, String date, bool ok});

const List<_HistoryRow> _history = [
  (spot: 'Spot B201', date: 'Sep 3, 2026', ok: true),
  (spot: 'Spot A103', date: 'Sep 2, 2026', ok: true),
  (spot: 'Spot C012', date: 'Aug 30', ok: false),
  (spot: 'Spot A205', date: 'Aug 28', ok: true),
  (spot: 'Spot B108', date: 'Aug 27', ok: true),
];

// titulo de arriba

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reserve spot', style: AppTypography.display),
          const SizedBox(height: Spacing.xs),
          Text(
            'P1 · North · Zone B',
            style: AppTypography.body.copyWith(color: Palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

// la card grande con el puesto, el circulo y el boton de confirmar

class _SpotCard extends StatelessWidget {
  const _SpotCard();

  @override
  Widget build(BuildContext context) {
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
                        child: Text('B201', style: AppTypography.monoDisplay),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Level P1 · North · Row 2',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.md),
                const _HoldTimeRing(time: '15:00'),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: () {},
              child: const Text('Confirm reservation'),
            ),
          ],
        ),
      ),
    );
  }
}

// el circulo azul con el 15:00 adentro
class _HoldTimeRing extends StatelessWidget {
  const _HoldTimeRing({required this.time});

  final String time;

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
            border: Border.all(color: Palette.primary, width: 5),
          ),
          child: Text(time, style: AppTypography.monoCountdown),
        ),
        const SizedBox(height: Spacing.sm),
        Text('hold time', style: AppTypography.caption),
      ],
    );
  }
}

// el aviso amarillo de "best time to reserve"

class _BestTimeBanner extends StatelessWidget {
  const _BestTimeBanner();

  @override
  Widget build(BuildContext context) {
    final body = AppTypography.body.copyWith(color: Palette.textSecondary);
    final bold = body.copyWith(
      color: Palette.textPrimary,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Palette.warningSoft,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: Palette.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 16, color: Palette.warningText),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best time to reserve',
                  style: AppTypography.heading2.copyWith(color: Palette.warningText),
                ),
                const SizedBox(height: Spacing.xs),
                Text.rich(
                  TextSpan(
                    style: body,
                    children: [
                      const TextSpan(
                        text: 'Based on your commute, reserve at ',
                      ),
                      TextSpan(text: '7:45 AM', style: bold),
                      const TextSpan(
                        text:
                            ' to arrive during the low-traffic window. Today\'s lot fills by 8:30 AM.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// la lista del historial de abajo

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < _history.length; i++) ...[
            _ComplianceRow(row: _history[i]),
            if (i < _history.length - 1) const Divider(),
          ],
        ],
      ),
    );
  }
}

class _ComplianceRow extends StatelessWidget {
  const _ComplianceRow({required this.row});

  final _HistoryRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: 14,
      ),
      child: Row(
        children: [
          _ComplianceBadge(ok: row.ok),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              row.spot,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Text(row.date, style: AppTypography.monoData),
        ],
      ),
    );
  }
}

// el cuadrito verde con chulo o rojo con x
class _ComplianceBadge extends StatelessWidget {
  const _ComplianceBadge({required this.ok});

  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? Palette.success : Palette.danger;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: ok ? Palette.successSoft : Palette.dangerSoft,
        borderRadius: BorderRadius.circular(Radii.badge),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Icon(ok ? Icons.check : Icons.close, size: 14, color: color),
    );
  }
}
