import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design/app_theme.dart';
import 'app_router.dart';
import 'dependencies.dart';

class ParkWiseApp extends StatelessWidget {
  const ParkWiseApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: dependencies.providers,
      child: MaterialApp(
        title: 'ParkWise',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRouter.root,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
