import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../domain/ports/photo_source.dart';
import '../../domain/services/photo_compression.dart';

class CameraPhotoSource implements PhotoSource {
  CameraPhotoSource({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  static const cameraQuality = 90;

  final ImagePicker _picker;

  @override
  Future<Uint8List?> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxPhotoSide.toDouble(),
      maxHeight: maxPhotoSide.toDouble(),
      imageQuality: cameraQuality,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
