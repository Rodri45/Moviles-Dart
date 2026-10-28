import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../cache/lot_photo_cache.dart';
import '../design/palette.dart';
import '../design/typography.dart';

class LotPhoto extends StatelessWidget {
  const LotPhoto({
    super.key,
    required this.name,
    required this.url,
    this.height = 96,
  });

  final String name;
  final String? url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: url == null
          ? _Initials(name)
          : LayoutBuilder(
              builder: (context, constraints) => CachedNetworkImage(
                imageUrl: url,
                cacheManager: LotPhotoCache.manager,
                memCacheWidth: (constraints.maxWidth * ratio).round(),
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, _) => _Initials(name),
                errorWidget: (_, _, _) => _Initials(name),
              ),
            ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(this.name);

  final String name;

  String get _letters => name
      .split(' ')
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Palette.primarySoft,
      child: Center(
        child: Text(
          _letters,
          style: AppTypography.display.copyWith(color: Palette.primary),
        ),
      ),
    );
  }
}
