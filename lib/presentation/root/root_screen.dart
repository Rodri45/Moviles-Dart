import 'package:flutter/material.dart';

import '../../core/design/palette.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../screens/find_my_car/find_my_car_screen.dart';
import '../screens/find_spot/find_spot_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/lot_detail/lot_detail_screen.dart';
import '../screens/no_spots/no_spots_screen.dart';
import '../screens/offline/offline_screen.dart';
import '../screens/reserve/reserve_screen.dart';

/// Contenedor de desarrollo. Equivalente a `RootView.swift`.
///
/// Barra compacta arriba (◀ nombre de la pantalla  3/7 ▶) y debajo la
/// pantalla seleccionada. Sirve para revisar cada pantalla contra Figma sin
/// navegar por la app. Se quita cuando exista navegación real.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _entries = <({String label, Widget screen})>[
    (label: 'Home', screen: HomeScreen()),
    (label: 'P1 · North', screen: LotDetailScreen()),
    (label: 'Find a spot', screen: FindSpotScreen()),
    (label: 'Reserve', screen: ReserveScreen()),
    (label: 'No campus spots', screen: NoSpotsScreen()),
    (label: 'Find my car', screen: FindMyCarScreen()),
    (label: 'Offline', screen: OfflineScreen()),
  ];

  void _go(int delta) {
    setState(() {
      _index = (_index + delta) % _entries.length;
      if (_index < 0) _index += _entries.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.devBar,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DevNavBar(
              label: _entries[_index].label,
              index: _index,
              total: _entries.length,
              onPrevious: () => _go(-1),
              onNext: () => _go(1),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Radii.card),
                ),
                child: IndexedStack(
                  index: _index,
                  children: [for (final e in _entries) e.screen],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ◀  Find a spot  3/7  ▶
class _DevNavBar extends StatelessWidget {
  const _DevNavBar({
    required this.label,
    required this.index,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final int index;
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Spacing.touchTarget,
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            color: Palette.textOnPrimary,
            tooltip: 'Previous screen',
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading2.copyWith(
                    color: Palette.textOnPrimary,
                  ),
                ),
                Text(
                  '${index + 1} / $total',
                  style: AppTypography.monoData.copyWith(
                    color: Palette.textOnPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            color: Palette.textOnPrimary,
            tooltip: 'Next screen',
          ),
        ],
      ),
    );
  }
}
