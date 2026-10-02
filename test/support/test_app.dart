import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkwise/app/app_router.dart';
import 'package:parkwise/app/dependencies.dart';
import 'package:parkwise/core/design/app_theme.dart';

// monta una pantalla con los view models armados sobre los mocks
Widget testApp(Widget home, {AppDependencies? dependencies}) {
  final deps = dependencies ?? AppDependencies.mock();
  return MultiProvider(
    providers: deps.providers,
    child: MaterialApp(
      theme: AppTheme.light,
      home: home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
}
