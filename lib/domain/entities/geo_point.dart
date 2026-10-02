class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
    (json['latitude'] as num).toDouble(),
    (json['longitude'] as num).toDouble(),
  );

  static const campus = GeoPoint(4.6018, -74.0660);

  final double latitude;
  final double longitude;

  String toZone() =>
      '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}
