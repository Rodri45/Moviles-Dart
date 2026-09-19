import 'package:flutter/material.dart';

import '../design/spacing.dart';

// scaffold base con el fondo gris y los margenes, para que todas las
// pantallas se vean igual
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

  // algo que va pegado abajo, como un boton
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
