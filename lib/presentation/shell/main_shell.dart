import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_tab_bar.dart';
import '../screens/home/home_screen.dart';
import '../screens/level_map/level_map_screen.dart';
import '../screens/profile/profile_view_model.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/reserve/reserve_screen.dart';
import 'shell_view_model.dart';

// las 4 pantallas de la barra de abajo. se quedan vivas en un IndexedStack
// para no perder el scroll ni volver a cargar al cambiar de tab
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  // para las pantallas que se abren encima (find a spot, find my car...):
  // cierra todo lo de encima y abre la tab
  static void openTab(BuildContext context, AppTab tab) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.read<ShellViewModel>().open(tab);
    if (tab == AppTab.profile) context.read<ProfileViewModel>().load();
  }

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ShellViewModel>().tab;

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [
          HomeScreen(),
          LevelMapScreen(),
          ReserveScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppTabBar(
        current: tab,
        onSelected: (tab) => openTab(context, tab),
      ),
    );
  }
}
