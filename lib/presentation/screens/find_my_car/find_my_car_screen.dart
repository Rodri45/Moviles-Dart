import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/format.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../domain/ports/location_provider.dart';
import '../../shell/main_shell.dart';
import 'find_my_car_view_model.dart';

class FindMyCarScreen extends StatefulWidget {
  const FindMyCarScreen({super.key});

  static const String routeName = '/find-my-car';

  @override
  State<FindMyCarScreen> createState() => _FindMyCarScreenState();
}

class _FindMyCarScreenState extends State<FindMyCarScreen>
    with WidgetsBindingObserver {
  late final FindMyCarViewModel _car;

  @override
  void initState() {
    super.initState();
    _car = context.read<FindMyCarViewModel>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _car.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _car.refreshAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _car.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = context.watch<FindMyCarViewModel>();

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(car: car),
            Expanded(
              child: RefreshIndicator(
                onRefresh: car.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.md,
                    Spacing.md,
                    Spacing.lg,
                  ),
                  children: [
                    if (car.isLoading && !car.hasCar)
                      const Center(child: CircularProgressIndicator())
                    else if (!car.hasCar)
                      const _NoCarCard()
                    else
                      ..._carDetails(car),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppTabBar(
        current: AppTab.map,
        onSelected: (tab) => MainShell.openTab(context, tab),
      ),
    );
  }

  List<Widget> _carDetails(FindMyCarViewModel car) {
    final meters = car.distanceMeters;
    final minutes = car.walkingMinutes;
    final String walkCaption;
    if (car.saved?.position == null) {
      walkCaption = 'No GPS when you parked';
    } else if (meters == null) {
      walkCaption = 'Waiting for your location';
    } else if (car.usingLastKnown) {
      walkCaption = 'Last known position';
    } else {
      walkCaption = '${meters.round()} m away';
    }

    return [
      if (car.offline) ...[
        const NoticeBanner(
          message: 'No connection. Showing where you saved your car.',
          icon: Icons.wifi_off,
        ),
        const SizedBox(height: Spacing.md),
      ],
      if (car.access != null && car.access != LocationAccess.granted) ...[
        _PermissionCard(car: car),
        const SizedBox(height: Spacing.md),
      ],
      Row(
        children: [
          Expanded(
            child: _InfoCard(
              label: 'SPOT',
              value: car.spotCode!,
              mono: true,
              caption: car.zone == null
                  ? 'Level ${car.levelCode}'
                  : 'Level ${car.levelCode} · Zone ${car.zone}',
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: _InfoCard(
              label: 'WALK',
              value: minutes == null ? '—' : '~$minutes min',
              mono: false,
              caption: walkCaption,
            ),
          ),
        ],
      ),
      const SizedBox(height: Spacing.md),
      _FloorViewCard(
        levelCode: car.levelCode!,
        spotCode: car.spotCode!,
        distance: meters == null ? null : '~${meters.round()}m',
      ),
      const SizedBox(height: Spacing.md),
      const _RouteToggle(),
      const SizedBox(height: Spacing.md),
      for (final step in _stepsFor(car)) ...[
        _StepCard(step: step),
        const SizedBox(height: Spacing.sm),
      ],
    ];
  }

  List<_Step> _stepsFor(FindMyCarViewModel car) => [
    (icon: Icons.stairs_outlined, text: 'Go to Level ${car.levelCode}'),
    if (car.zone != null)
      (icon: Icons.arrow_upward, text: 'Walk to Zone ${car.zone}'),
    (icon: Icons.flag_outlined, text: 'Your car is at spot ${car.spotCode}'),
  ];
}

typedef _Step = ({IconData icon, String text});

class _Header extends StatelessWidget {
  const _Header({required this.car});

  final FindMyCarViewModel car;

  @override
  Widget build(BuildContext context) {
    final parkedAt = car.parkedAt;

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
          Text('Find my car', style: AppTypography.display),
          const SizedBox(height: Spacing.xs),
          Text(
            parkedAt == null
                ? 'No car parked'
                : 'Parked ${formatDate(parkedAt)} at ${formatTime(parkedAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(color: Palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NoCarCard extends StatelessWidget {
  const _NoCarCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('No car parked', style: AppTypography.heading1),
            const SizedBox(height: Spacing.xs),
            Text(
              'Tap "I parked" on your reservation and we will remember '
              'the spot.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: Spacing.md),
            OutlinedButton(
              onPressed: () => MainShell.openTab(context, AppTab.reserve),
              child: const Text('Go to my reservation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.car});

  final FindMyCarViewModel car;

  @override
  Widget build(BuildContext context) {
    final (message, button, action) = switch (car.access) {
      LocationAccess.deniedForever => (
        'Location is blocked for ParkWise. Turn it on in settings to see '
            'how far your car is.',
        'Open settings',
        car.openSettings,
      ),
      LocationAccess.serviceDisabled => (
        'Your phone location is off. Turn it on to see how far your car is.',
        'Open settings',
        car.openSettings,
      ),
      _ => (
        'We use your location only to show how far you are from your car. '
            'It never leaves your phone.',
        'Allow location',
        car.requestAccess,
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Palette.secondary,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    'Use your location',
                    style: AppTypography.heading2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(message, style: AppTypography.caption),
            const SizedBox(height: Spacing.md),
            OutlinedButton(onPressed: action, child: Text(button)),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.mono,
    required this.caption,
  });

  final String label;
  final String value;
  final bool mono;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.overline),
            const SizedBox(height: Spacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: mono
                    ? AppTypography.monoDisplay.copyWith(fontSize: 24)
                    : AppTypography.display.copyWith(fontSize: 24),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorViewCard extends StatelessWidget {
  const _FloorViewCard({
    required this.levelCode,
    required this.spotCode,
    required this.distance,
  });

  final String levelCode;
  final String spotCode;
  final String? distance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LEVEL $levelCode — FLOOR VIEW',
              style: AppTypography.overline,
            ),
            const SizedBox(height: Spacing.md),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: Palette.background,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: _FloorMap(spotCode: spotCode, distance: distance),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorMap extends StatelessWidget {
  const _FloorMap({required this.spotCode, required this.distance});

  final String spotCode;

  final String? distance;

  static const int _cols = 6;
  static const int _rows = 8;
  static const double _gap = Spacing.sm;
  static const double _cellHeight = 22;

  static const _carRow = 2;
  static const _carCol = 0;
  static const _solidCell = (row: 3, col: 1);
  static const _pathCells = [
    (row: 4, col: 1),
    (row: 5, col: 1),
    (row: 6, col: 1),
    (row: 6, col: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - _gap * (_cols - 1)) / _cols;
        final gridHeight = _rows * _cellHeight + (_rows - 1) * _gap;
        const entranceSpace = 28.0;

        double left(int col) => col * (cellWidth + _gap);
        double top(int row) => row * (_cellHeight + _gap);
        final lineX = left(_carCol) + cellWidth / 2;

        return SizedBox(
          height: gridHeight + entranceSpace,
          child: Stack(
            children: [
              for (var r = 0; r < _rows; r++)
                for (var c = 0; c < _cols; c++)
                  Positioned(
                    left: left(c),
                    top: top(r),
                    width: cellWidth,
                    height: _cellHeight,
                    child: _MapCell(
                      solid: r == _solidCell.row && c == _solidCell.col,
                      path: _pathCells.any((p) => p.row == r && p.col == c),
                      hidden: r == _carRow && c == _carCol,
                    ),
                  ),
              Positioned(
                left: lineX - 1,
                top: top(_carRow) + _cellHeight,
                width: 2,
                height: gridHeight - top(_carRow) - _cellHeight + Spacing.sm,
                child: const _DashedLine(),
              ),
              if (distance != null)
                Positioned(
                  left: lineX + Spacing.sm,
                  top: top(5) - 2,
                  child: Text(
                    distance!,
                    style: AppTypography.monoData.copyWith(fontSize: 9),
                  ),
                ),
              Positioned(
                left: 0,
                top: top(_carRow) - 2,
                child: _MapChip(
                  label: spotCode,
                  color: Palette.primary,
                  background: Palette.primarySoft,
                  icon: Icons.directions_car,
                ),
              ),
              Positioned(
                left: 0,
                top: gridHeight + Spacing.xs,
                child: const _MapChip(
                  label: 'ENTRANCE',
                  color: Palette.secondary,
                  background: Palette.secondarySoft,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapCell extends StatelessWidget {
  const _MapCell({
    required this.solid,
    required this.path,
    required this.hidden,
  });

  final bool solid;
  final bool path;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    if (hidden) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: solid ? Palette.primary : Palette.border,
        borderRadius: BorderRadius.circular(Radii.badge),
        border: path ? Border.all(color: Palette.primary, width: 1.5) : null,
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(Radii.badge),
            border: Border.all(color: color),
          ),
          child: Text(
            label,
            style: AppTypography.monoId.copyWith(fontSize: 10, color: color),
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: Spacing.xs),
          Icon(icon, size: 12, color: color),
        ],
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DashedLinePainter());
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.primary
      ..strokeWidth = size.width;
    const dash = 4.0;
    const space = 3.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash + space;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => false;
}

class _RouteToggle extends StatelessWidget {
  const _RouteToggle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _RouteOption(label: 'Direct route', selected: true),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _RouteOption(
            label: 'Lit route',
            selected: false,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lit route is coming soon.')),
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteOption extends StatelessWidget {
  const _RouteOption({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Palette.primarySoft : Palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        side: BorderSide(
          color: selected ? Palette.primary : Palette.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: AppTypography.button.copyWith(
                color: selected ? Palette.primary : Palette.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border.all(color: Palette.border),
              ),
              child: Icon(step.icon, size: 14, color: Palette.textSecondary),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                step.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
