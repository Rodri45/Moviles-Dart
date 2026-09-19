import 'package:flutter/material.dart';

import '../core/design/app_theme.dart';
import 'app_router.dart';

/// Widget raíz de la app. Equivalente a `SmartParkingApp.swift`.
class ParkWiseApp extends StatelessWidget {
  const ParkWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRouter.root,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
