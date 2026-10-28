class NearbyLot {
  const NearbyLot({
    required this.id,
    required this.name,
    required this.address,
    required this.ratePerHour,
    required this.currency,
    required this.walkMinutes,
    this.imageUrl,
  });

  factory NearbyLot.fromJson(Map<String, dynamic> json, {String? imageBase}) {
    final image = json['imageUrl'] as String?;
    return NearbyLot(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      ratePerHour: (json['ratePerHour'] as num).toInt(),
      currency: json['currency'] as String,
      walkMinutes: (json['walkMinutes'] as num).toInt(),
      imageUrl: image == null || imageBase == null
          ? image
          : Uri.parse(imageBase).resolve(image).toString(),
    );
  }

  final String id;
  final String name;
  final String address;
  final int ratePerHour;
  final String currency;
  final int walkMinutes;
  final String? imageUrl;
}
