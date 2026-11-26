import 'dart:typed_data';

class ReportPhoto {
  const ReportPhoto({required this.bytes, required this.originalBytes});

  final Uint8List bytes;
  final int originalBytes;

  int get sizeBytes => bytes.length;
}
