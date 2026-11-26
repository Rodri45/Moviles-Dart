import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../domain/ports/photo_source.dart';

class CameraPhotoSource implements PhotoSource {
  CameraPhotoSource({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> takePhoto() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return null;
    return file.readAsBytes();
  }
}
