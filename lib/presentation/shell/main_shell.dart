import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/widgets/app_tab_bar.dart';
import '../screens/home/home_screen.dart';
import '../screens/level_map/level_map_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/profile_view_model.dart';
import '../screens/reserve/reserve_screen.dart';
import '../screens/reserve/reserve_view_model.dart';
import 'shell_view_model.dart';

// las 4 pantallas de la barra de abajo. se quedan vivas en un IndexedStack
// para no perder el scroll ni volver a cargar al cambiar de tab
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  // para las pantallas que se abren encima (find a spot, find my car...):
  // cierra todo lo de encima y abre la tab
  static void openTab(BuildContext context, AppTab tab) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.read<ShellViewModel>().open(tab);
    if (tab == AppTab.profile) context.read<ProfileViewModel>().load();
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final ReserveViewModel _reserve;

  @override
  void initState() {
    super.initState();
    _reserve = context.read<ReserveViewModel>()..addListener(_showExpiryAlert);
    // al entrar a la app se recupera la reserva activa del backend
    WidgetsBinding.instance.addPostFrameCallback((_) => _reserve.load());
  }

  // el aviso sale en cualquier tab, no solo en la de reserva
  Future<void> _showExpiryAlert() async {
    final reservation = _reserve.reservation;
    if (!_reserve.expiryAlert || reservation == null || !mounted) return;
    _reserve.dismissExpiryAlert();
    final cancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your reservation is about to expire'),
        content: Text(
          'Spot ${reservation.spotCode} is held until '
          '${formatTime(reservation.expiresAt)} and you are more than '
          '1 km from campus. Cancel it so someone else can use it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel reservation'),
          ),
        ],
      ),
    );
    if (cancel ?? false) await _reserve.release();
  }

  @override
  void dispose() {
    _reserve.removeListener(_showExpiryAlert);
    super.dispose();
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
        onSelected: (tab) => MainShell.openTab(context, tab),
      ),
    );
  }
}
