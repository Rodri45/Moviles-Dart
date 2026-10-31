import 'package:flutter/material.dart';

import '../../core/widgets/notice_banner.dart';

class PendingActionsBanner extends StatelessWidget {
  const PendingActionsBanner({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return NoticeBanner(
      title: 'Saved on this phone',
      message: count == 1
          ? '1 action will be sent when you\'re back online.'
          : '$count actions will be sent when you\'re back online.',
      icon: Icons.cloud_upload_outlined,
    );
  }
}
