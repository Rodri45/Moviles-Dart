import 'package:flutter_cache_manager/flutter_cache_manager.dart';

abstract final class BuildingPhotoCache {
  static const key = 'building_photos';

  static final CacheManager manager = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 10,
    ),
  );
}
