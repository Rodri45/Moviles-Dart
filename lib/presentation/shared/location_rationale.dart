import 'package:flutter/material.dart';

Future<bool> showLocationRationale(BuildContext context) async {
  final allow = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Use your location?'),
      content: const Text(
        'ParkWise saves where you parked so Find my car can guide you back, '
        'and warns you if your reservation is about to expire while you are '
        'far from campus. Your exact location never leaves your phone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Allow'),
        ),
      ],
    ),
  );
  return allow ?? false;
}
