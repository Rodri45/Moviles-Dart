enum SpotState { free, occupied, reserved, disabled }

// un puesto de parqueo, tipo "A-12"
class ParkingSpot {
  const ParkingSpot({
    required this.id,
    required this.code,
    required this.state,
    this.isAccessible = false,
    this.isEv = false,
  });

  final String id;
  final String code;
  final SpotState state;

  // si es para discapacitados
  final bool isAccessible;

  // si tiene cargador de carro electrico
  final bool isEv;
}
