import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../entities/report_photo.dart';

typedef PhotoCompressor = Future<ReportPhoto> Function(Uint8List original);

const maxPhotoBytes = 300 * 1024;

const maxPhotoSide = 1280;

const photoQualities = [80, 70, 60, 50];

Future<ReportPhoto> compressPhotoInBackground(Uint8List original) =>
    Isolate.run(() => compressPhoto(original), debugName: 'report-photo');

Future<ReportPhoto> compressPhotoInline(Uint8List original) async =>
    compressPhoto(original);

ReportPhoto compressPhoto(Uint8List original) {
  final decoded = img.decodeImage(original);
  if (decoded == null) {
    throw const FormatException('The photo could not be read');
  }
  final image = img.bakeOrientation(decoded);
  for (var side = maxPhotoSide; ; side = side * 3 ~/ 4) {
    final resized = _fit(image, side);
    for (final quality in photoQualities) {
      final bytes = img.encodeJpg(resized, quality: quality);
      if (bytes.length <= maxPhotoBytes || side < 160) {
        return ReportPhoto(bytes: bytes, originalBytes: original.length);
      }
    }
  }
}

img.Image _fit(img.Image image, int side) {
  if (image.width <= side && image.height <= side) return image;
  return image.width >= image.height
      ? img.copyResize(image, width: side)
      : img.copyResize(image, height: side);
}
