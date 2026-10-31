class DeviceDescription {
  const DeviceDescription({
    required this.model,
    required this.osVersion,
  });

  final String model;
  final String osVersion;

  Map<String, Object> toProperties() => {
    'deviceModel': model,
    'osVersion': osVersion,
  };
}
