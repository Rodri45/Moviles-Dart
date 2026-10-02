import 'package:flutter/foundation.dart';

import '../../core/widgets/app_tab_bar.dart';

// cual tab de abajo esta abierto
class ShellViewModel extends ChangeNotifier {
  AppTab tab = AppTab.home;

  void open(AppTab value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
  }
}
