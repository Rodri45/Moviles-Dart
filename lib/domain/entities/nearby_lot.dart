class NearbyLot {
  const NearbyLot({
    required this.id,
    required this.name,
    required this.address,
    required this.ratePerHour,
    required this.currency,
    required this.walkMinutes,
  });

  factory NearbyLot.fromJson(Map<String, dynamic> json) => NearbyLot(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    ratePerHour: (json['ratePerHour'] as num).toInt(),
    currency: json['currency'] as String,
    walkMinutes: (json['walkMinutes'] as num).toInt(),
  );

  final String id;
  final String name;
  final String address;
  final int ratePerHour;
  final String currency;
  final int walkMinutes;
}
