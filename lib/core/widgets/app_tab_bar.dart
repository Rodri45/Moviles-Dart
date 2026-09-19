import 'package:flutter/material.dart';

import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

/// Pestañas del bottom nav. Equivalente a `AppTabBar.swift`.
enum AppTab { home, map, reserve, profile }

/// Bottom navigation de ParkWise: Home · Map · Reserve · Profile.
///
/// Solo visual: recibe la pestaña activa y la pinta. Sin navegación.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.current});

  final AppTab current;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Palette.surface,
        border: Border(top: BorderSide(color: Palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _TabItem(
              icon: Icons.home_outlined,
              label: 'Home',
              active: current == AppTab.home,
            ),
            _TabItem(
              icon: Icons.map_outlined,
              label: 'Map',
              active: current == AppTab.map,
            ),
            _TabItem(
              icon: Icons.calendar_today_outlined,
              label: 'Reserve',
              active: current == AppTab.reserve,
            ),
            _TabItem(
              icon: Icons.person_outline,
              label: 'Profile',
              active: current == AppTab.profile,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Palette.primary : Palette.textSecondary;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de pestaña activa (línea azul arriba del ícono).
          Container(
            height: 2,
            width: 32,
            color: active ? Palette.primary : Colors.transparent,
          ),
          const SizedBox(height: Spacing.sm),
          Icon(icon, size: 22, color: color),
          const SizedBox(height: Spacing.xs),
          Text(label, style: AppTypography.tab.copyWith(color: color)),
          const SizedBox(height: Spacing.sm),
        ],
      ),
    );
  }
}
