import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../domain/ports/photo_source.dart';

class MockPhotoSource implements PhotoSource {
  MockPhotoSource({Uint8List? photo})
    : photo = photo ?? img.encodeJpg(img.Image(width: 640, height: 480));

  Uint8List? photo;
  int taken = 0;

  @override
  Future<Uint8List?> takePhoto() async {
    taken++;
    return photo;
  }
}
