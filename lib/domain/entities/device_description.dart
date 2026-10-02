class DeviceDescription {
  const DeviceDescription({
    required this.model,
    required this.osVersion,
    this.platform = 'android',
  });

  final String model;
  final String osVersion;
  final String platform;

  Map<String, Object> toProperties() => {
    'deviceModel': model,
    'osVersion': osVersion,
    'platform': platform,
  };
}
