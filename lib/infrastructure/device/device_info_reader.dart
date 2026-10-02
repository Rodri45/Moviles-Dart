import 'package:device_info_plus/device_info_plus.dart';

import '../../domain/entities/device_description.dart';

// lee una sola vez el modelo y la version de android al arrancar
Future<DeviceDescription> readDeviceDescription() async {
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    return DeviceDescription(
      model: '${info.manufacturer} ${info.model}',
      osVersion: info.version.release,
    );
  } on Exception {
    return const DeviceDescription(model: 'unknown', osVersion: 'unknown');
  }
}
