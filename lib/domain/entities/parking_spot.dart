enum SpotStatus { free, reserved, occupied, disabled }

class ParkingSpot {
  const ParkingSpot({
    required this.id,
    required this.code,
    required this.zone,
    required this.levelCode,
    required this.status,
    required this.walkMinutes,
    this.isAccessible = false,
    this.isEv = false,
    this.isVip = false,
    this.mine = false,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) => ParkingSpot(
    id: json['id'] as String,
    code: json['code'] as String,
    zone: json['zone'] as String,
    levelCode: json['levelCode'] as String,
    status:
        SpotStatus.values.asNameMap()[json['status']] ?? SpotStatus.disabled,
    walkMinutes: (json['walkMinutes'] as num).toInt(),
    isAccessible: json['isAccessible'] as bool? ?? false,
    isEv: json['isEv'] as bool? ?? false,
    isVip: json['isVip'] as bool? ?? false,
    mine: json['mine'] as bool? ?? false,
  );

  final String id;
  final String code;
  final String zone;
  final String levelCode;
  final SpotStatus status;
  final int walkMinutes;
  final bool isAccessible;
  final bool isEv;
  final bool isVip;

  final bool mine;

  bool get isFree => status == SpotStatus.free;
}
