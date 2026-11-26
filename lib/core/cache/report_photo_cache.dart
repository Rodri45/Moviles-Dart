import 'package:flutter_cache_manager/flutter_cache_manager.dart';

abstract final class ReportPhotoCache {
  static const key = 'report_photos';

  static final CacheManager manager = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 50,
    ),
  );
}
