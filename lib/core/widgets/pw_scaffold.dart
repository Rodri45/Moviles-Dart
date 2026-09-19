import 'package:flutter/material.dart';

import '../design/spacing.dart';

/// Scaffold base de ParkWise: fondo, padding horizontal y AppBar opcional.
///
/// Todas las pantallas deberían usarlo para mantener el mismo look.
class PwScaffold extends StatelessWidget {
  const PwScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.bottom,
    this.showBack = true,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;

  /// Widget fijado al fondo (ej. botón "Reserve").
  final Widget? bottom;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              actions: actions,
              automaticallyImplyLeading: showBack,
            ),
      body: SafeArea(
        child: Padding(padding: Spacing.screen, child: body),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.sm,
                  Spacing.md,
                  Spacing.md,
                ),
                child: bottom,
              ),
            ),
    );
  }
}
