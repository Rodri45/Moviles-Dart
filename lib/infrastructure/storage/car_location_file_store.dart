import 'dart:convert';
import 'dart:io';

class CarLocationFileStore {
  CarLocationFileStore(this._file);

  final File _file;

  Future<Map<String, dynamic>?> read() async {
    if (!await _file.exists()) return null;
    final decoded = jsonDecode(await _file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Saved car location must be a JSON object');
    }
    return decoded;
  }

  Future<void> write(Map<String, dynamic> location) async {
    await _file.parent.create(recursive: true);
    final pending = File('${_file.path}.tmp');
    await pending.writeAsString(jsonEncode(location), flush: true);
    if (await _file.exists()) await _file.delete();
    await pending.rename(_file.path);
  }

  Future<void> clear() async {
    if (await _file.exists()) await _file.delete();
  }
}
