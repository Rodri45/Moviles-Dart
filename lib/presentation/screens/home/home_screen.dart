import 'package:flutter/material.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/pill.dart';

/// Pantalla 1 — Home. SOLO VISUAL, sin lógica.
///
/// Estructura (de arriba a abajo):
///   1. Saludo + nombre + avatar.
///   2. DESTINATION: pills en fila horizontal.
///   3. Card "Occupancy forecast · today" con barras por hora y leyenda.
///   4. PARKING LEVELS: una card por nivel con badge, estado y barra.
///   5. Acciones rápidas: "Find a spot" y "Find my car".
///   6. Bottom nav con "Home" activo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.md,
            Spacing.md,
            Spacing.lg,
          ),
          children: [
            const _Greeting(),
            const SizedBox(height: Spacing.lg),
            Text('DESTINATION', style: AppTypography.overline),
            const SizedBox(height: Spacing.sm),
            const _DestinationPills(),
            const SizedBox(height: Spacing.md),
            const _ForecastCard(),
            const SizedBox(height: Spacing.lg),
            Text('PARKING LEVELS', style: AppTypography.overline),
            const SizedBox(height: Spacing.sm),
            for (final level in _levels) ...[
              _LevelCard(level: level),
              const SizedBox(height: Spacing.sm),
            ],
            const SizedBox(height: Spacing.sm),
            const _QuickActions(),
          ],
        ),
      ),
      bottomNavigationBar: const AppTabBar(current: AppTab.home),
    );
  }
}

// ---------------------------------------------------------------------------
// Datos de muestra (solo para la vista)
// ---------------------------------------------------------------------------

enum _Occupancy { low, med, high }

typedef _ForecastBar = ({String hour, double value, _Occupancy level, bool now});

const List<_ForecastBar> _forecast = [
  (hour: '7', value: 0.35, level: _Occupancy.low, now: false),
  (hour: '8', value: 0.65, level: _Occupancy.med, now: true),
  (hour: '9', value: 0.95, level: _Occupancy.high, now: false),
  (hour: '10', value: 0.85, level: _Occupancy.high, now: false),
  (hour: '11', value: 0.60, level: _Occupancy.med, now: false),
  (hour: '12', value: 0.45, level: _Occupancy.low, now: false),
  (hour: '1', value: 0.40, level: _Occupancy.low, now: false),
  (hour: '2', value: 0.58, level: _Occupancy.med, now: false),
];

enum _LevelStatus { available, limited, full }

typedef _Level = ({
String code,
String name,
_LevelStatus status,
String free,
int reserved,
int total,
double occupancy,
});

const List<_Level> _levels = [
  (
  code: 'P1',
  name: 'Level P1 · North',
  status: _LevelStatus.available,
  free: '14 free',
  reserved: 3,
  total: 80,
  occupancy: 0.82,
  ),
  (
  code: 'P2',
  name: 'Level P2 · Central',
  status: _LevelStatus.limited,
  free: '3 free',
  reserved: 8,
  total: 60,
  occupancy: 0.95,
  ),
  (
  code: 'P3',
  name: 'Level P3 · South',
  status: _LevelStatus.full,
  free: 'No spots',
  reserved: 12,
  total: 50,
  occupancy: 1.0,
  ),
];

// ---------------------------------------------------------------------------
// Saludo + avatar
// ---------------------------------------------------------------------------

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good evening', style: AppTypography.caption),
              const SizedBox(height: 2),
              Text(
                'Andrés Morales',
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
            'AM',
            style: AppTypography.heading2.copyWith(color: Palette.textOnPrimary),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pills de destino (scroll horizontal)
// ---------------------------------------------------------------------------

class _DestinationPills extends StatelessWidget {
  const _DestinationPills();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          Pill(label: 'Main Campus — Blk 20', selected: true),
          SizedBox(width: Spacing.sm),
          Pill(label: 'Library'),
          SizedBox(width: Spacing.sm),
          Pill(label: 'Admin Building'),
          SizedBox(width: Spacing.sm),
          Pill(label: 'Sports Center'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card de pronóstico
// ---------------------------------------------------------------------------

class _ForecastCard extends StatelessWidget {
  const _ForecastCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Occupancy forecast · today',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading1,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                const _LiveBadge(),
              ],
            ),
            const SizedBox(height: Spacing.md),
            SizedBox(
              height: 72,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < _forecast.length; i++) ...[
                    if (i > 0) const SizedBox(width: Spacing.xs),
                    Expanded(child: _Bar(bar: _forecast[i])),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            const Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.xs,
              children: [
                _LegendItem(color: Palette.success, label: 'Low < 55%'),
                _LegendItem(color: Palette.warning, label: 'Med 55-80%'),
                _LegendItem(color: Palette.danger, label: 'High > 80%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: Palette.successSoft,
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Text(
        'LIVE',
        style: AppTypography.overline.copyWith(color: Palette.success),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bar});

  final _ForecastBar bar;

  Color get _base => switch (bar.level) {
    _Occupancy.low => Palette.success,
    _Occupancy.med => Palette.warning,
    _Occupancy.high => Palette.danger,
  };

  @override
  Widget build(BuildContext context) {
    // La hora actual va en color sólido; el resto en tinte suave.
    final fill = bar.now ? _base : _base.withValues(alpha: 0.25);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: bar.value,
              child: Container(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(Radii.badge),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          bar.hour,
          style: AppTypography.monoData.copyWith(
            color: bar.now ? Palette.textPrimary : Palette.textSecondary,
            fontWeight: bar.now ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: Spacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card de nivel
// ---------------------------------------------------------------------------

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final _Level level;

  Color get _color => switch (level.status) {
    _LevelStatus.available => Palette.success,
    _LevelStatus.limited => Palette.warning,
    _LevelStatus.full => Palette.danger,
  };

  Color get _soft => switch (level.status) {
    _LevelStatus.available => Palette.successSoft,
    _LevelStatus.limited => Palette.warningSoft,
    _LevelStatus.full => Palette.dangerSoft,
  };

  String get _label => switch (level.status) {
    _LevelStatus.available => 'Available',
    _LevelStatus.limited => 'Limited',
    _LevelStatus.full => 'Full',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            _CodeBadge(code: level.code, color: _color, background: _soft),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          level.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading2,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      _StatusChip(label: _label, color: _color, background: _soft),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text.rich(
                    TextSpan(
                      style: AppTypography.caption,
                      children: [
                        TextSpan(
                          text: level.free,
                          style: TextStyle(
                            color: _color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text:
                          '  ${level.reserved} reserved · ${level.total} total',
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.pill),
                    child: LinearProgressIndicator(
                      value: level.occupancy,
                      minHeight: 4,
                      backgroundColor: Palette.border,
                      color: _color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            const Icon(Icons.chevron_right, size: 20, color: Palette.border),
          ],
        ),
      ),
    );
  }
}

/// Cuadro tintado con el código del nivel (P1, P2, P3).
class _CodeBadge extends StatelessWidget {
  const _CodeBadge({
    required this.code,
    required this.color,
    required this.background,
  });

  final String code;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(code, style: AppTypography.monoId.copyWith(color: color)),
    );
  }
}

/// Chip de estado de texto sobre fondo tintado (Available / Limited / Full).
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Acciones rápidas
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.search,
            label: 'Find a spot',
            color: Palette.primary,
            background: Palette.primarySoft,
          ),
        ),
        SizedBox(width: Spacing.sm),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.directions_car_outlined,
            label: 'Find my car',
            color: Palette.secondary,
            background: Palette.secondarySoft,
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
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {},
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
