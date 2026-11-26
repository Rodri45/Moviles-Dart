import 'dart:typed_data';

abstract interface class PhotoSource {
  Future<Uint8List?> takePhoto();
}
