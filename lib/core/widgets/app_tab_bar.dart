import 'package:flutter/material.dart';

import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

enum AppTab { home, map, reserve, profile }

// la barra de abajo con home, map, reserve y profile
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.current, this.onSelected});

  final AppTab current;
  final ValueChanged<AppTab>? onSelected;

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
              onTap: () => onSelected?.call(AppTab.home),
            ),
            _TabItem(
              icon: Icons.map_outlined,
              label: 'Map',
              active: current == AppTab.map,
              onTap: () => onSelected?.call(AppTab.map),
            ),
            _TabItem(
              icon: Icons.calendar_today_outlined,
              label: 'Reserve',
              active: current == AppTab.reserve,
              onTap: () => onSelected?.call(AppTab.reserve),
            ),
            _TabItem(
              icon: Icons.person_outline,
              label: 'Profile',
              active: current == AppTab.profile,
              onTap: () => onSelected?.call(AppTab.profile),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Palette.primary : Palette.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // la rayita azul arriba del icono cuando esta activo
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
      ),
    );
  }
}
