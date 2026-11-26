import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:parkwise/domain/services/photo_compression.dart';

Uint8List noisyPhoto(int width, int height) {
  final random = Random(7);
  final image = img.Image(width: width, height: height);
  for (final pixel in image) {
    pixel
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256);
  }
  return img.encodeJpg(image, quality: 95);
}

void main() {
  test('a camera photo ends under 300 KB and 1280 px', () {
    final original = noisyPhoto(2400, 1600);

    final photo = compressPhoto(original);
    final result = img.decodeJpg(photo.bytes)!;

    expect(original.length, greaterThan(maxPhotoBytes));
    expect(photo.originalBytes, original.length);
    expect(photo.sizeBytes, lessThanOrEqualTo(maxPhotoBytes));
    expect(result.width, lessThanOrEqualTo(maxPhotoSide));
    expect(result.width / result.height, closeTo(1.5, 0.01));
  });

  test('a portrait photo is resized by its height', () {
    final photo = compressPhoto(noisyPhoto(900, 1500));
    final result = img.decodeJpg(photo.bytes)!;

    expect(result.height, lessThanOrEqualTo(maxPhotoSide));
    expect(result.height, greaterThan(result.width));
  });

  test('a small photo keeps its size', () {
    final png = img.encodePng(img.Image(width: 320, height: 240));
    final photo = compressPhoto(png);
    final result = img.decodeJpg(photo.bytes)!;

    expect(result.width, 320);
    expect(result.height, 240);
  });

  test('bytes that are not a photo are reported', () {
    expect(
      () => compressPhoto(Uint8List.fromList([1, 2, 3, 4])),
      throwsFormatException,
    );
  });

  test('the background isolate gives the same photo', () async {
    final original = noisyPhoto(1600, 1200);

    final inBackground = await compressPhotoInBackground(original);
    final inline = await compressPhotoInline(original);

    expect(inBackground.sizeBytes, inline.sizeBytes);
  });
}
